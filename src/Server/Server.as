void PushStatsUpdateToServer() {
    auto sj = Stats::GetStatsJson();
}


class DD2API {
    BetterSocket@ socket;
    string sessionToken;
    MsgHandler@[] msgHandlers;

    DD2API() {
        while (msgHandlers.Length < 256) {
            msgHandlers.InsertLast(null);
        }
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
        if (socket.IsClosed || socket.ServerDisconnected) {
            warn("Failed to connect to DD2API server.");
            warn("Waiting 10s and trying again.");
            sleep(10000);
            ReconnectSocket();
            return;
        }
        AuthenticateWithServer();
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
                throw("Failed to get auth token. Should not happen.");
            }

        }
    }

    protected void ReadLoop() {
        uint count;
        RawMessage@ msg;
        while ((@msg = socket.ReadMsg()) !is null) {
            HandleRawMsg(msg);
        }
        // we disconnected
    }

    protected OutgoingMsg@[] queuedMsgs;

    protected void SendLoop() {
        OutgoingMsg@ next;
        while (true) {
            auto nbOutgoing = Math::Min(queuedMsgs.Length, 10);
            for (uint i = 0; i < nbOutgoing; i++) {
                @next = queuedMsgs[i];
                socket.WriteMsg(next.type, Json::Write(next.msgPayload));
            }
            queuedMsgs.RemoveRange(0, nbOutgoing);
            if (nbOutgoing > 0) dev_trace("sent " + nbOutgoing + " messages");
            yield();
        }
    }

    protected bool hasStartedPingLoop = false;
    protected void SendPingLoop() {
        if (hasStartedPingLoop) return;
        hasStartedPingLoop = true;
        while (true) {
            sleep(10000);
            auto msg = PingMsg();
            socket.WriteMsg(msg.type, Json::Write(msg.msgPayload));
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
        if (!msg.msgJson.HasKey(tostring(MessageResponseTypes(msg.msgType)))) {
            Dev_Notify("Message type " + msg.msgType + " does not have a key for its type. Message: " + msg.msgData);
            warn("Message type " + msg.msgType + " does not have a key for its type. Message: " + msg.msgData);
            return;
        }
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
        //warn("Ping received.");
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
        msgPayload["type"] = type;
    }
}
