void PushStatsUpdateToServer() {
    auto sj = Stats::GetStatsJson();
    g_api.QueueMsg(ReportStatsMsg(sj));
}


class DD2API {
    BetterSocket@ socket;
    protected string sessionToken;
    protected MsgHandler@[] msgHandlers;
    protected uint lastPingTime;
    uint[] recvCount;
    uint[] sendCount;

    DD2API() {
        InitMsgHandlers();
        @socket = BetterSocket("127.0.0.1", 17677);
        socket.StartConnect();
        startnew(CoroutineFunc(BeginLoop));
        startnew(UpdateAuthTokenIfNeeded);
    }

    void OnDisabled() {
        socket.Shutdown();
    }

    protected void InitMsgHandlers() {
        SetMsgHandlersInArray(msgHandlers);
    }

    protected void ReconnectSocket() {
        dev_trace("ReconnectSocket");
        socket.ReconnectToServer();
        startnew(CoroutineFunc(BeginLoop));
    }

    protected void BeginLoop() {
        while (socket.IsConnecting) yield();
        AuthenticateWithServer();
        if (socket.IsClosed || socket.ServerDisconnected) {
            // sessionToken = "";
            warn("Failed to connect to DD2API server.");
            warn("Waiting 10s and trying again.");
            sleep(10000);
            ReconnectSocket();
            return;
        }
        print("Connected to DD2API server.");
        startnew(CoroutineFunc(ReadLoop));
        startnew(CoroutineFunc(SendLoop));
        startnew(CoroutineFunc(SendPingLoop));
        startnew(CoroutineFunc(ReconnectWhenDisconnected));
    }

    protected void AuthenticateWithServer() {
        if (sessionToken.Length == 0) {
            auto token = GetAuthToken();
            if (token.Length == 0) {
                throw("Failed to get auth token. Should not happen vie GetAuthToken.");
            }
            SendMsgNow(AuthenticateMsg(token));
        } else {
            SendMsgNow(ResumeSessionMsg(sessionToken));
        }
        auto msg = socket.ReadMsg();
        if (msg is null) return;
        LogRecvType(msg);
        if (msg.msgType == MessageResponseTypes::AuthFail) {
            warn("Auth failed: " + string(msg.msgJson.Get("err", "Missing error message.")) + ".");
            sessionToken = "";
            socket.Shutdown();
            return;
        } else if (msg.msgType != MessageResponseTypes::AuthSuccess) {
            warn("Unexpected message type: " + msg.msgType + ".");
            sessionToken = "";
            socket.Shutdown();
            return;
        }
        sessionToken = msg.msgJson.Get("session_token", "");
        if (sessionToken.Length == 0) {
            warn("Auth success but missing session token.");
            socket.Shutdown();
            return;
        }
    }

    protected void ReadLoop() {
        RawMessage@ msg;
        while ((@msg = socket.ReadMsg()) !is null) {
            HandleRawMsg(msg);
        }
        // we disconnected
    }

    protected OutgoingMsg@[] queuedMsgs;

    void QueueMsg(OutgoingMsg@ msg) {
        queuedMsgs.InsertLast(msg);
    }
    protected void QueueMsg(uint8 type, Json::Value@ payload) {
        queuedMsgs.InsertLast(OutgoingMsg(type, payload));
    }

    protected void SendLoop() {
        OutgoingMsg@ next;
        while (true) {
            auto nbOutgoing = Math::Min(queuedMsgs.Length, 10);
            for (uint i = 0; i < nbOutgoing; i++) {
                @next = queuedMsgs[i];
                SendMsgNow(next);
            }
            queuedMsgs.RemoveRange(0, nbOutgoing);
            // if (nbOutgoing > 0) dev_trace("sent " + nbOutgoing + " messages");
            yield();
        }
    }

    protected void SendMsgNow(OutgoingMsg@ msg) {
        socket.WriteMsg(msg.type, Json::Write(msg.msgPayload));
        LogSentType(msg);
    }

    protected void LogSentType(OutgoingMsg@ msg) {
        if (msg.type >= sendCount.Length) {
            sendCount.Resize(msg.type + 1);
        }
        sendCount[msg.type]++;
        if (msg.getTy() != MessageRequestTypes::Ping)
            dev_trace("Sent message type: " + tostring(msg.getTy()));
    }

    protected void LogRecvType(RawMessage@ msg) {
        if (msg.msgType >= recvCount.Length) {
            recvCount.Resize(msg.msgType + 1);
        }
        recvCount[msg.msgType]++;
    }

    protected bool hasStartedPingLoop = false;
    protected void SendPingLoop() {
        if (hasStartedPingLoop) return;
        hasStartedPingLoop = true;
        while (true) {
#if DEV
            sleep(2000);
#else
            sleep(10000);
#endif
            QueueMsg(PingMsg());
        }
    }

    void ReconnectWhenDisconnected() {
        while (true) {
            if (socket.IsClosed || socket.ServerDisconnected) {
                dev_trace("disconnect detected.");
                ReconnectSocket();
                return;
            }
            sleep(1000);
        }
    }

    void HandleRawMsg(RawMessage@ msg) {
        if (msg.msgType >= msgHandlers.Length || msgHandlers[msg.msgType] is null) {
            warn("Unhandled message type: " + msg.msgType);
            return;
        }
        LogRecvType(msg);
        // if (!msg.msgJson.HasKey(tostring(MessageResponseTypes(msg.msgType)))) {
        //     Dev_Notify("Message type " + msg.msgType + " does not have a key for its type. Message: " + msg.msgData);
        //     warn("Message type " + msg.msgType + " does not have a key for its type. Message: " + msg.msgData);
        //     return;
        // }
        msgHandlers[msg.msgType](msg.msgJson);
    }


    void SetMsgHandlersInArray(MsgHandler@[]@ msgHandlers) {
        while (msgHandlers.Length < 256) {
            msgHandlers.InsertLast(null);
        }
        @msgHandlers[MessageResponseTypes::AuthFail] = MsgHandler(AuthFailHandler);
        @msgHandlers[MessageResponseTypes::AuthSuccess] = MsgHandler(AuthSuccessHandler);
        @msgHandlers[MessageResponseTypes::ContextAck] = MsgHandler(ContextAckHandler);

        @msgHandlers[MessageResponseTypes::Ping] = MsgHandler(PingHandler);

        @msgHandlers[MessageResponseTypes::Stats] = MsgHandler(StatsHandler);
        @msgHandlers[MessageResponseTypes::GlobalLB] = MsgHandler(GlobalLBHandler);
        @msgHandlers[MessageResponseTypes::FriendsLB] = MsgHandler(FriendsLBHandler);
    }



    void AuthFailHandler(Json::Value@ msg) {
        warn("Auth failed.");
    }

    void AuthSuccessHandler(Json::Value@ msg) {
        warn("Auth success.");
    }

    void ContextAckHandler(Json::Value@ msg) {
        warn("Context ack.");
    }

    void PingHandler(Json::Value@ msg) {
        // dev_trace("Ping received.");
        lastPingTime = Time::Now;
    }

    void StatsHandler(Json::Value@ msg) {
        //warn("Stats received.");
    }

    void GlobalLBHandler(Json::Value@ msg) {
        //warn("Global LB received.");
    }

    void FriendsLBHandler(Json::Value@ msg) {
        //warn("Friends LB received.");
    }
}


funcdef void MsgHandler(Json::Value@);


class OutgoingMsg {
    uint8 type;
    Json::Value@ msgPayload;
    OutgoingMsg(uint8 type, Json::Value@ payload) {
        this.type = type;
        @msgPayload = payload;
    }

    MessageRequestTypes getTy() {
        return MessageRequestTypes(type);
    }
}
