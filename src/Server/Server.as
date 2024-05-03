/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
void PushStatsUpdateToServer() {
    while (g_api is null || !g_api.HasContext) yield();
    auto sj = Stats::GetStatsJson();
    g_api.QueueMsg(ReportStatsMsg(sj));
}

void PushPBHeightUpdateToServer() {
    while (g_api is null || !g_api.HasContext) yield();
    auto pb = Stats::GetPBHeight();
    g_api.QueueMsg(ReportPBHeightMsg(pb));

}

Json::Value@ JSON_TRUE = Json::Parse("true");

bool IsJsonTrue(Json::Value@ jv) {
    if (jv.GetType() != Json::Type::Boolean) return false;
    return bool(jv);
}

#if DEVx
const string ENDPOINT = "127.0.0.1";
#else
// 161.35.155.191
const string ENDPOINT = "dips-plus-plus-server.xk.io";
// const string ENDPOINT = "161.35.155.191";
// const string ENDPOINT = "203.221.134.67";
// const string ENDPOINT = "dpps.xk.io";
// const string ENDPOINT = "167.71.143.101";
// const string ENDPOINT = "openplanet.dev";
// const string ENDPOINT = "map-together-au.xk.io";
#endif

class DD2API {
    BetterSocket@ socket;
    protected string sessionToken;
    protected MsgHandler@[] msgHandlers;
    protected uint lastPingTime;
    uint[] recvCount;
    uint[] sendCount;
    bool IsReady = false;
    bool HasContext = false;

    DD2API() {
        InitMsgHandlers();
        @socket = BetterSocket(ENDPOINT, 17677);
        // @socket = BetterSocket(ENDPOINT, 19796);
        // @socket = BetterSocket(ENDPOINT, 443);
        // socket.StartConnect();
        // startnew(CoroutineFunc(BeginLoop));
        startnew(CoroutineFunc(ReconnectSocket));
    }

    void OnDisabled() {
        Shutdown();
    }

    void Shutdown() {
        socket.Shutdown();
        IsReady = false;
        HasContext = false;
    }

    protected void InitMsgHandlers() {
        SetMsgHandlersInArray(msgHandlers);
    }

    protected void ReconnectSocket() {
        IsReady = false;
        HasContext = false;
        dev_trace("ReconnectSocket");
        socket.ReconnectToServer();
        startnew(CoroutineFunc(BeginLoop));
    }

    protected void BeginLoop() {
        lastPingTime = Time::Now;
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
        IsReady = true;
        print("Connected to DD2API server.");
        startnew(CoroutineFunc(ReadLoop));
        startnew(CoroutineFunc(SendLoop));
        startnew(CoroutineFunc(SendPingLoop));
        startnew(CoroutineFunc(ReconnectWhenDisconnected));
        startnew(CoroutineFunc(WatchAndSendContextChanges));
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
            Shutdown();
            return;
        } else if (msg.msgType != MessageResponseTypes::AuthSuccess) {
            warn("Unexpected message type: " + msg.msgType + ".");
            sessionToken = "";
            Shutdown();
            return;
        }
        sessionToken = msg.msgJson.Get("session_token", "");
        if (sessionToken.Length == 0) {
            warn("Auth success but missing session token.");
            Shutdown();
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
            if (socket.IsClosed || socket.ServerDisconnected) break;
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
            sleep(6789);
            if (socket.IsClosed || socket.ServerDisconnected) {
                continue;
            }
            QueueMsg(PingMsg());
            if (Time::Now - lastPingTime > 25000) {
                warn("Ping timeout.");
                lastPingTime = Time::Now;
                socket.Shutdown();
                hasStartedPingLoop = false;
                return;
            }
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

    bool currentMapRelevant = false;
    void WatchAndSendContextChanges() {
        uint lastCheck = 0;
        uint lastGC = 0;
        uint64 nextMI = 0;
        uint64 nextu64 = 0;
        uint64 lastMI = 0;
        uint64 lastu64 = 0;
        uint lastMapMwId = 0;
        uint lastReport = 0;
        nat2 bi = nat2();
        bool mapChange, u64Change;
        auto app = cast<CTrackMania>(GetApp());
        vec3 lastPos;
        while (true) {
            if (socket.IsClosed || socket.ServerDisconnected) break;
            mapChange = (app.RootMap is null && lastMapMwId > 0)
                || (lastMapMwId == 0 && app.RootMap !is null)
                || (app.RootMap !is null && lastMapMwId != app.RootMap.Id.Value);
            nextu64 = SF::GetInfo();
            nextMI = MI::GetInfo();
            u64Change = lastu64 != nextu64 || lastMI != nextMI;
            if (mapChange || u64Change) {
                lastCheck = Time::Now;
                lastMapMwId = app.RootMap !is null ? app.RootMap.Id.Value : 0;
                bi = app.RootMap is null ? nat2() : nat2(app.RootMap.Blocks.Length, app.RootMap.AnchoredObjects.Length);
                lastu64 = nextu64;
                lastMI = nextMI;
                currentMapRelevant = MapMatchesDD2Uid(app.RootMap)
                    || (Math::Abs(20522 - int(bi.x)) < 500 && Math::Abs(38369 - int(bi.y)) < 500);
                auto ctx = ReportContextMsg(nextu64, nextMI, bi, currentMapRelevant);
                QueueMsg(ctx);
                HasContext = true;
                currentMapRelevant = currentMapRelevant || (bool(ctx.msgPayload["ReportContext"]["i"]));
                yield();
                sleep(1000);
                yield();
            }
            sleep(117);
            if (socket.IsClosed || socket.ServerDisconnected) break;
            if (Time::Now - lastReport > (currentMapRelevant ? 5000 : 30000)) {
                CSceneVehicleVisState@ state = GetVehicleStateOfControlledPlayer();
                if (state !is null && (state.Position - lastPos).LengthSquared() > 0.1) {
                    lastReport = Time::Now;
                    lastPos = state.Position;
                    QueueMsg(ReportVehicleStateMsg(state));
                    sleep(117);
                }
                if (socket.IsClosed || socket.ServerDisconnected) break;
            }
            if (Time::Now - lastGC > 300000) {
                lastGC = Time::Now;
                QueueMsg(ReportGCNodMsg(GC::GetInfo()));
            }
            sleep(117);
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
