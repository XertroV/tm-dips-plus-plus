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

uint Count_PushPBHeightUpdateToServer = 0;
uint Count_PushPBHeightUpdateToServerQueued = 0;

void PushPBHeightUpdateToServer() {
    Count_PushPBHeightUpdateToServer++;
    while (g_api is null || !g_api.HasContext) yield();
    auto pb = Stats::GetPBHeight();
    g_api.QueueMsg(ReportPBHeightMsg(pb));
    Count_PushPBHeightUpdateToServerQueued++;
}


void PushMessage(OutgoingMsg@ msg) {
    if (g_api is null) return;
    g_api.QueueMsg(msg);
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
        trace("ReconnectSocket");
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
        QueueMsg(GetMyStatsMsg());
        startnew(CoroutineFunc(WatchAndSendContextChanges));
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
        if (queuedMsgs.Length > 10) {
            trace('msg queue: ' + queuedMsgs.Length);
        }
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

    string lastStatsJson;
    protected void SendMsgNow(OutgoingMsg@ msg) {
        if (msg.getTy() == MessageRequestTypes::ReportStats) {
            lastStatsJson = Json::Write(msg.msgPayload);
            socket.WriteMsg(msg.type, lastStatsJson);
            startnew(CoroutineFunc(PersistCachedStats));
        } else {
            socket.WriteMsg(msg.type, Json::Write(msg.msgPayload));
        }
        LogSentType(msg);
    }

    void PersistCachedStats() {
        if (IO::FileExists(STATS_FILE)) {
            IO::Move(STATS_FILE, STATS_FILE + ".bak");
        }
        IO::File f(STATS_FILE, IO::FileMode::Write);
        f.Write(lastStatsJson);
    }

    protected void LogSentType(OutgoingMsg@ msg) {
        if (msg.type >= sendCount.Length) {
            sendCount.Resize(msg.type + 1);
        }
        sendCount[msg.type]++;
        if (msg.getTy() != MessageRequestTypes::Ping)
            trace("Sent message type: " + tostring(msg.getTy()));
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
                trace("disconnect detected.");
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
        uint started = Time::Now;
        vec3 lastPos;
        while (true) {
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
            // if (socket.IsClosed || socket.ServerDisconnected) break;
            if (Time::Now - lastReport > (currentMapRelevant ? 5000 : 30000)) {
                CSceneVehicleVisState@ state = GetVehicleStateOfControlledPlayer();
                if (state !is null && (state.Position - lastPos).LengthSquared() > 0.1) {
                    lastReport = Time::Now;
                    lastPos = state.Position;
                    QueueMsg(ReportVehicleStateMsg(state));
                    sleep(117);
                }
                // if (socket.IsClosed || socket.ServerDisconnected) break;
            }
            if (Time::Now - lastGC > 300000) {
                lastGC = Time::Now;
                QueueMsg(ReportGCNodMsg(GC::GetInfo()));
            }
            sleep(117);
            if (Time::Now - started > 15000 && (socket.IsClosed || socket.ServerDisconnected)) {
                trace("breaking context loop");
                break;
            }
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
        Json::Value@ j;
        try {
            msgHandlers[msg.msgType](msg.msgJson);
        } catch {
            print("msg: " + Json::Write(msg.msgJson));
            warn("Failed to handle message type: " + MessageResponseTypes(msg.msgType) + ". " + getExceptionInfo());
// #if DEV
//             msgHandlers[msg.msgType](msg.msgJson);
// #endif
        }
    }


    void SetMsgHandlersInArray(MsgHandler@[]@ msgHandlers) {
        while (msgHandlers.Length < 256) {
            msgHandlers.InsertLast(null);
        }
        @msgHandlers[MessageResponseTypes::AuthFail] = MsgHandler(AuthFailHandler);
        @msgHandlers[MessageResponseTypes::AuthSuccess] = MsgHandler(AuthSuccessHandler);
        @msgHandlers[MessageResponseTypes::ContextAck] = MsgHandler(ContextAckHandler);

        @msgHandlers[MessageResponseTypes::Ping] = MsgHandler(PingHandler);

        @msgHandlers[MessageResponseTypes::ServerInfo] = MsgHandler(ServerInfoHandler);
        @msgHandlers[MessageResponseTypes::Stats] = MsgHandler(StatsHandler);
        @msgHandlers[MessageResponseTypes::GlobalLB] = MsgHandler(GlobalLBHandler);
        @msgHandlers[MessageResponseTypes::FriendsLB] = MsgHandler(FriendsLBHandler);
        @msgHandlers[MessageResponseTypes::GlobalOverview] = MsgHandler(GlobalOverviewHandler);
        @msgHandlers[MessageResponseTypes::Top3] = MsgHandler(Top3Handler);
        @msgHandlers[MessageResponseTypes::MyRank] = MsgHandler(MyRankHandler);
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

    void ServerInfoHandler(Json::Value@ msg) {
        //warn("Server info received.");
        if (msg.HasKey("ServerInfo")) @msg = msg["ServerInfo"];
        Global::SetServerInfoFromJson(msg);
    }

    void StatsHandler(Json::Value@ msg) {
        //warn("Stats received.");
        trace('stats from server: ' + Json::Write(msg));
        Stats::LoadStatsFromServer(msg["stats"]);
    }

    void GlobalLBHandler(Json::Value@ msg) {
        //warn("Global LB received.");
        Global::UpdateLBFromJson(msg["entries"]);
    }

    void FriendsLBHandler(Json::Value@ msg) {
        //warn("Friends LB received.");
    }

    void GlobalOverviewHandler(Json::Value@ msg) {
        // warn("Global Overview received. " + Json::Write(msg));
        Global::SetFromJson(msg["j"]);
    }

    void Top3Handler(Json::Value@ msg) {
        // warn("Top3 received. " + Json::Write(msg) + " / type: " + tostring(msg.GetType()));
        Global::SetTop3FromJson(msg["top3"]);
    }

    void MyRankHandler(Json::Value@ msg) {
        // warn("MyRank received. " + Json::Write(msg));
        Global::SetMyRankFromJson(msg["r"]);
    }
}

namespace Global {
    uint players = 0;
    uint sessions = 0;
    uint resets = 0;
    uint jumps = 0;
    uint map_loads = 0;
    uint falls = 0;
    uint floors_fallen = 0;
    float height_fallen = 0;
    uint nb_players_live = 0;

    void SetServerInfoFromJson(Json::Value@ j) {
        try {
            nb_players_live = j["nb_players_live"];
        } catch {
            warn("Failed to parse Server info. " + getExceptionInfo());
        }
    }

    void SetFromJson(Json::Value@ j) {
        try {
            players = j["players"];
            sessions = j["sessions"];
            resets = j["resets"];
            jumps = j["jumps"];
            map_loads = j["map_loads"];
            falls = j["falls"];
            floors_fallen = j["floors_fallen"];
            height_fallen = j["height_fallen"];
        } catch {
            warn("Failed to parse Global stats. " + getExceptionInfo());
        }
    }

    LBEntry@[] top3 = {LBEntry(), LBEntry(), LBEntry()};
    void SetTop3FromJson(Json::Value@ j) {
        for (uint i = 0; i < j.Length; i++) {
            while (i >= top3.Length) {
                top3.InsertLast(LBEntry());
            }
            top3[i].SetFromJson(j[i]);
        }
        EmitUpdatedTop3();
    }

    LBEntry@[] globalLB = {};
    void UpdateLBFromJson(Json::Value@ j) {
        while (globalLB.Length < j.Length) {
            globalLB.InsertLast(LBEntry());
        }
        for (uint i = 0; i < j.Length; i++) {
            globalLB[i].SetFromJson(j[i]);
        }
        EmitUpdatedGlobalLB();
    }

    LBEntry myRank = LBEntry();
    void SetMyRankFromJson(Json::Value@ j) {
        myRank.SetFromJson(j);
        EmitUpdatedMyRank();
    }
}


void EmitUpdatedTop3() {
    // warn("emit updated top3");
}

void EmitUpdatedGlobalLB() {

}

void EmitUpdatedMyRank() {

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
