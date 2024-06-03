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
    if (MatchDD2::isEasyDD2Map) return;
    while (g_api is null || !g_api.HasContext) yield();
    auto sj = Stats::GetStatsJson();
    g_api.QueueMsg(ReportStatsMsg(sj));
}

uint Count_PushPBHeightUpdateToServer = 0;
uint Count_PushPBHeightUpdateToServerQueued = 0;

void PushPBHeightUpdateToServer() {
    if (MatchDD2::isEasyDD2Map) return;
    Count_PushPBHeightUpdateToServer++;
    while (g_api is null || !g_api.HasContext) yield();
    auto pb = Stats::GetPBHeight();
    g_api.QueueMsg(ReportPBHeightMsg(pb));
    Count_PushPBHeightUpdateToServerQueued++;
}

void PushGetPlayerPBRequestToServer(const string &in wsid) {
    if (wsid.Length < 30) warn("wsid too short: " + wsid);
    PushMessage(GetPlayersPbMsg(wsid));
}

void PushMessage(OutgoingMsg@ msg) {
    if (g_api is null) return;
    // if (!g_api.HasContext) {
    //     warn("Dropping message of type because connection has no context: " + tostring(msg.getTy()));
    //     return;
    // }
    g_api.QueueMsg(msg);
}


Json::Value@ JSON_TRUE = Json::Parse("true");

bool IsJsonTrue(Json::Value@ jv) {
    if (jv.GetType() != Json::Type::Boolean) return false;
    return bool(jv);
}

#if DEV
[Setting hidden]
string ENDPOINT = "127.0.0.1";
[SettingsTab name="DEV"]
void R_ST_Dev() {
    UI::Text("Endpoint: " + ENDPOINT);
    if (UI::Button("Dev Endpoint")) { ENDPOINT = "127.0.0.1"; }
    if (UI::Button("Prod Endpoint")) { ENDPOINT = "dips-plus-plus-server.xk.io"; }
    if (UI::Button("Reconnect")) {
        g_api.Shutdown();
        @g_api = null;
        @g_api = DD2API();
    }
}

#else
const string ENDPOINT = "dips-plus-plus-server.xk.io";
#endif


bool IsDisconnected() {
    return g_api is null || g_api.IsShutdownClosedOrDC;
}


class DD2API {
    BetterSocket@ socket;
    protected string sessionToken;
    protected MsgHandler@[] msgHandlers;
    protected uint lastPingTime;
    uint[] recvCount;
    uint[] sendCount;
    bool IsReady = false;
    bool HasContext = false;
    string authError;


    uint runNonce;

    DD2API() {
        InitMsgHandlers();
        @socket = BetterSocket(ENDPOINT, 17677);
        // @socket = BetterSocket(ENDPOINT, 19796);
        // @socket = BetterSocket(ENDPOINT, 443);
        // socket.StartConnect();
        // startnew(CoroutineFunc(BeginLoop));
        startnew(CoroutineFunc(ReconnectSocket));
        startnew(CoroutineFunc(WatchForDeadSocket));
    }

    void NewRunNonce() {
        runNonce = Math::Rand(0, 1000000);
    }

    void WatchForDeadSocket() {
        uint lastDead = Time::Now;
        bool wasDead = false;
        uint connStart = Time::Now;
        while (!_isShutdown && socket.IsConnecting && Time::Now - connStart < 5000) yield();
        sleep_fix(21230);
        while (!_isShutdown) {
            if (socket.IsConnecting) {
                connStart = Time::Now;
                while (!_isShutdown && socket.IsConnecting && Time::Now - connStart < 5000) yield();
            }
            if (IsShutdownClosedOrDC) {
                if (_isShutdown) return;
                if (!wasDead) {
                    wasDead = true;
                    lastDead = Time::Now;
                } else if (Time::Now - lastDead > 21230) {
                    lastDead = Time::Now;
                    ReconnectSocket();
                    wasDead = false;
                    sleep_fix(21230);
                }
            } else {
                wasDead = false;
            }
            sleep_fix(10);
        }
    }

    void OnDisabled() {
        Shutdown();
    }

    bool _isShutdown = false;
    void Shutdown() {
        _isShutdown = true;
        if (socket !is null) socket.Shutdown();
        @socket = null;
        IsReady = false;
        HasContext = false;
    }

    bool get_IsShutdownClosedOrDC() {
        return _isShutdown || socket.IsClosed || socket.ServerDisconnected;
    }

    protected void InitMsgHandlers() {
        SetMsgHandlersInArray(msgHandlers);
    }

    protected void ReconnectSocket() {
        NewRunNonce();
        auto nonce = runNonce;
        IsReady = false;
        authError = "";
        HasContext = false;
        lastPingTime = Time::Now;
        trace("ReconnectSocket");
        if (_isShutdown) return;
        socket.ReconnectToServer();
        startnew(CoroutineFuncUserdataUint64(BeginLoop), nonce);
    }

    bool IsBadNonce(uint32 nonce) {
        if (nonce != runNonce) {
            return true;
        }
        return false;
    }

    protected void BeginLoop(uint64 nonce) {
        lastPingTime = Time::Now;
        while (!_isShutdown && socket.IsConnecting && !IsBadNonce(nonce)) yield();
        if (_isShutdown) return;
        AuthenticateWithServer(nonce);
        if (IsBadNonce(nonce)) return;
        if (IsShutdownClosedOrDC || sessionToken == "") {
            if (_isShutdown) return;
            // sessionToken = "";
            warn("Failed to connect to DD2API server.");
            warn("Waiting 15s and trying again.");
            sleep_fix(15000);
            if (IsBadNonce(nonce)) return;
            ReconnectSocket();
            return;
        }
        lastPingTime = Time::Now;
        print("Connected to DD2API server...");
        startnew(CoroutineFuncUserdataUint64(WatchAndSendContextChanges), nonce);
        uint ctxStartTime = Time::Now;
        while (!HasContext && !IsBadNonce(nonce) && Time::Now - ctxStartTime < 30000) yield_why("awaiting context");
        if (IsBadNonce(nonce)) return;
        if (!HasContext) {
            warn("Failed to get context.");
            Shutdown();
            sleep_fix(1000);
            if (IsBadNonce(nonce)) return;
            ReconnectSocket();
            return;
        }
        print("... DD2API ready");
        IsReady = true;
        QueueMsg(GetMyStatsMsg());
        QueueMsg(ReportMyColorMsg());
        QueueMsg(GetTwitchMsg());
        startnew(CoroutineFuncUserdataUint64(ReadLoop), nonce);
        startnew(CoroutineFuncUserdataUint64(SendLoop), nonce);
        startnew(CoroutineFuncUserdataUint64(SendPingLoop), nonce);
        startnew(CoroutineFuncUserdataUint64(ReconnectWhenDisconnected), nonce);
    }

    protected void AuthenticateWithServer(uint32 nonce) {
        if (sessionToken.Length == 0) {
            auto token = GetAuthToken();
            if (token.Length == 0) {
                throw("Failed to get auth token. Should not happen vie GetAuthToken.");
            }
            if (IsBadNonce(nonce)) return;
            SendMsgNow(AuthenticateMsg(token));
        } else {
            SendMsgNow(ResumeSessionMsg(sessionToken));
        }
        if (IsBadNonce(nonce) || socket is null) return;
        auto msg = socket.ReadMsg();
        if (msg is null) {
            trace("Recieved null msg from server after auth.");
            return;
        }
        LogRecvType(msg);
        if (msg.msgType == MessageResponseTypes::AuthFail) {
            authError = "Auth failed: " + string(msg.msgJson.Get("err", "Missing error message.")) + ".";
            NotifyWarningDebounce(authError, 300000);
            sessionToken = "";
            Shutdown();
            sleep_fix(5000);
            return;
        } else if (msg.msgType != MessageResponseTypes::AuthSuccess) {
            authError = "Unexpected message type: " + msg.msgType + ".";
            warn(authError);
            sessionToken = "";
            Shutdown();
            sleep_fix(5000);
            return;
        }
        sessionToken = msg.msgJson.Get("session_token", "");
        if (sessionToken.Length == 0) {
            authError = "Auth success but missing session token.";
            warn(authError);
            Shutdown();
            return;
        }
        authError = "";
    }

    protected void ReadLoop(uint64 nonce) {
        RawMessage@ msg;
        while (!IsBadNonce(nonce) && (@msg = socket.ReadMsg()) !is null) {
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

    protected void SendLoop(uint64 nonce) {
        OutgoingMsg@ next;
        uint loopStarted = Time::Now;
        while (!IsReady && Time::Now - loopStarted < 10000) yield();
        while (!IsBadNonce(nonce)) {
            if (IsShutdownClosedOrDC) break;
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
        if (socket is null) return;
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
            dev_trace("Sent message type: " + tostring(msg.getTy()));
    }

    protected void LogRecvType(RawMessage@ msg) {
        if (msg.msgType >= recvCount.Length) {
            recvCount.Resize(msg.msgType + 1);
        }
        recvCount[msg.msgType]++;
    }

    uint pingTimeoutCount = 0;
    protected void SendPingLoop(uint64 nonce) {
        pingTimeoutCount = 0;
        while (!IsBadNonce(nonce)) {
            sleep_fix(6789);
            if (IsShutdownClosedOrDC) {
                return;
            }
            if (IsBadNonce(nonce)) return;
            QueueMsg(PingMsg());
            if (Time::Now - lastPingTime > 45000 && IsReady) {
                if (IsBadNonce(nonce)) return;
                pingTimeoutCount++;
                if (pingTimeoutCount > 3) {
                    warn("Ping timeout.");
                    lastPingTime = Time::Now;
                    socket.Shutdown();
                    return;
                }
            } else {
                pingTimeoutCount = 0;
            }
        }
    }

    void ReconnectWhenDisconnected(uint64 nonce) {
        while (!IsBadNonce(nonce)) {
            if (IsShutdownClosedOrDC) {
                trace("disconnect detected.");
                ReconnectSocket();
                return;
            }
            sleep_fix(1000);
        }
    }

    bool currentMapRelevant = false;
    void WatchAndSendContextChanges(uint64 nonce) {
        uint lastCheck = 0;
        uint lastGC = 0;
        uint64 nextMI = 0;
        uint64 nextu64 = 0;
        uint64 lastMI = 0;
        uint64 lastu64 = 0;
        uint lastMapMwId = 0;
        uint lastVSReport = 0;
        nat2 bi = nat2();
        bool mapChange, u64Change;
        auto app = cast<CTrackMania>(GetApp());
        uint started = Time::Now;
        vec3 lastPos = vec3();
        bool firstRun = true;
        trace('context loop start');
        while (!IsBadNonce(nonce)) {
            mapChange = (app.RootMap is null && lastMapMwId > 0)
                || (lastMapMwId == 0 && app.RootMap !is null)
                || (app.RootMap !is null && lastMapMwId != app.RootMap.Id.Value);
            nextu64 = SF::GetInfo();
            nextMI = MI::GetInfo();
            u64Change = lastu64 != nextu64 || lastMI != nextMI;
            if (mapChange || u64Change || firstRun) {
                // dev_trace('context change');
                firstRun = false;
                lastCheck = Time::Now;
                lastMapMwId = app.RootMap !is null ? app.RootMap.Id.Value : 0;
                bi = app.RootMap is null ? nat2() : nat2(app.RootMap.Blocks.Length, app.RootMap.AnchoredObjects.Length);
                lastu64 = nextu64;
                lastMI = nextMI;
                currentMapRelevant = app.RootMap !is null && app.RootMap.Id.GetName() == DD2_MAP_UID
                    || (Math::Abs(20522 - int(bi.x)) < 500 && Math::Abs(38369 - int(bi.y)) < 500);
                currentMapRelevant = currentMapRelevant && !MatchDD2::isEasyDD2Map;
                if (IsBadNonce(nonce)) break;
                OutgoingMsg@ ctx;
                try {
                    @ctx = ReportContextMsg(nextu64, nextMI, bi, currentMapRelevant);
                } catch {
                    warn("exception creating context: " + getExceptionInfo());
                    continue;
                }
                if (IsBadNonce(nonce)) break;
                QueueMsg(ctx);
                // dev_trace("sent context");
                HasContext = true;
                try {
                    currentMapRelevant = currentMapRelevant || (bool(ctx.msgPayload["ReportContext"]["i"]));
                    currentMapRelevant = currentMapRelevant && !MatchDD2::isEasyDD2Map;
                } catch {
                    warn('exception updating r: ' + getExceptionInfo());
                }
                yield();
                sleep_fix(1000);
                yield();
            }
            sleep_fix(117);
            // if (IsShutdownClosedOrDC) break;
            if (Time::Now - lastVSReport > (currentMapRelevant ? 5000 : 25000)) {
                if (IsBadNonce(nonce)) break;
                CSceneVehicleVisState@ state = GetVehicleStateOfControlledPlayer();
                if (state !is null &&
                    !Spectate::IsSpectator &&
                    ((state.Position - lastPos).LengthSquared() > 0.1
                     || Time::Now - lastVSReport > 25000)
                ) {
                    try {
                        lastVSReport = Time::Now;
                        lastPos = state.Position;
                        QueueMsg(ReportVehicleStateMsg(state));
                        sleep_fix(117);
                    } catch {
                        warn("exception reporting VS: " + getExceptionInfo());
                        }
                }
                // if (IsShutdownClosedOrDC) break;
            }
            if (IsBadNonce(nonce)) break;
            if (Time::Now - lastGC > 300000) {
                lastGC = Time::Now;
                QueueMsg(ReportGCNodMsg(GC::GetInfo()));
            }
            sleep_fix(117);
            if (IsBadNonce(nonce)) break;
            if (Time::Now - started > 15000 && (IsShutdownClosedOrDC)) {
                trace("breaking context loop");
                break;
            }
        }
        trace('context loop end');
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
        try {
            msgHandlers[msg.msgType](msg.msgJson);
        } catch {
            warn("failed to handle msg: " + Json::Write(msg.msgJson));
            warn("Failed to handle message type: " + MessageResponseTypes(msg.msgType) + ". " + getExceptionInfo());
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
        @msgHandlers[MessageResponseTypes::NonFatalErrorMsg] = MsgHandler(NonFatalErrorMsgHandler);

        @msgHandlers[MessageResponseTypes::Stats] = MsgHandler(StatsHandler);
        @msgHandlers[MessageResponseTypes::GlobalLB] = MsgHandler(GlobalLBHandler);
        @msgHandlers[MessageResponseTypes::FriendsLB] = MsgHandler(FriendsLBHandler);
        @msgHandlers[MessageResponseTypes::GlobalOverview] = MsgHandler(GlobalOverviewHandler);
        @msgHandlers[MessageResponseTypes::Top3] = MsgHandler(Top3Handler);
        @msgHandlers[MessageResponseTypes::MyRank] = MsgHandler(MyRankHandler);
        @msgHandlers[MessageResponseTypes::PlayersPB] = MsgHandler(PlayersPBHandler);
        @msgHandlers[MessageResponseTypes::Donations] = MsgHandler(DonationsHandler);
        @msgHandlers[MessageResponseTypes::GfmDonations] = MsgHandler(GfmDonationsHandler);
        @msgHandlers[MessageResponseTypes::TwitchName] = MsgHandler(TwitchNameHandler);

        @msgHandlers[MessageResponseTypes::UsersProfile] = MsgHandler(UsersProfileHandler);
        @msgHandlers[MessageResponseTypes::YourPreferences] = MsgHandler(MyPreferencesHandler);

        @msgHandlers[MessageResponseTypes::MapOverview] = MsgHandler(MapOverviewHandler);
        @msgHandlers[MessageResponseTypes::MapLB] = MsgHandler(MapLBHandler);
        @msgHandlers[MessageResponseTypes::MapLivePlayers] = MsgHandler(MapLivePlayersHandler);
        @msgHandlers[MessageResponseTypes::MapRank] = MsgHandler(MapRankHandler);

        @msgHandlers[MessageResponseTypes::SecretAssets] = MsgHandler(SecretAssetsHandler);
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

    void NonFatalErrorMsgHandler(Json::Value@ msg) {
        // 0 = error, 1 = warn, 2 = info, 3 = success, 4 = debug
        uint level = msg.Get("level", 2);
        string message = msg.Get("msg", "No Message");
        switch (level) {
            case 0: NotifyError(message); return;
            case 1: NotifyWarning(message); return;
            case 3: NotifySuccess(message); return;
            case 4: Dev_Notify(message); return;
        }
        Notify(message);
    }

    void StatsHandler(Json::Value@ msg) {
        //warn("Stats received.");
        // trace('stats from server: ' + Json::Write(msg));
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

    void PlayersPBHandler(Json::Value@ msg) {
        // warn("Players PB received. " + Json::Write(msg));
        Global::SetPlayersPBHeightFromJson(msg);
    }

    void DonationsHandler(Json::Value@ msg) {
        Global::SetDonationsFromJson(msg);
    }

    void GfmDonationsHandler(Json::Value@ msg) {
        Global::SetGfmDonationsFromJson(msg);
    }

    void TwitchNameHandler(Json::Value@ msg) {
        TwitchNames::HandleMsg(msg);
    }

    void UsersProfileHandler(Json::Value@ msg) {
        UserProfiles::HandleMsg(msg);
    }

    void MyPreferencesHandler(Json::Value@ msg) {
        MyPreferences::HandleMsg(msg);
    }

    // MapOverview
    // MapLB
    // MapLivePlayers
    // MapRank

    void MapOverviewHandler(Json::Value@ msg) {
        if (g_CustomMap !is null) {
            g_CustomMap.SetOverviewFromJson(msg);
        }
    }

    void MapLBHandler(Json::Value@ msg) {
        if (g_CustomMap !is null) {
            g_CustomMap.SetLBFromJson(msg);
        }
    }

    void MapLivePlayersHandler(Json::Value@ msg) {
        if (g_CustomMap !is null) {
            g_CustomMap.SetLivePlayersFromJson(msg);
        }
    }

    void MapRankHandler(Json::Value@ msg) {
        if (g_CustomMap !is null) {
            g_CustomMap.SetRankFromJson(msg);
        }
    }

    void SecretAssetsHandler(Json::Value@ msg) {
        SecretAssets::Load(msg);
    }
}

namespace Global {
    uint players = 0;
    uint sessions = 0;
    uint resets = 0;
    uint jumps = 0;
    // uint map_loads = 0;
    uint falls = 0;
    uint floors_fallen = 0;
    float height_fallen = 0;
    int nb_players_live = 0;
    int nb_players_climbing = 0;
    int nb_climbing_shallow_dip = 0;
    dictionary pbCache;

    dictionary wsidToPlayerName;
    dictionary colorCache;

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
            // map_loads = j["map_loads"];
            falls = j["falls"];
            floors_fallen = j["floors_fallen"];
            height_fallen = j["height_fallen"];
            nb_players_climbing = JGetInt(j, "nb_players_climbing", 0);
            nb_players_live = JGetInt(j, "nb_players_live", 0);
            nb_climbing_shallow_dip = JGetInt(j, "nb_climbing_shallow_dip", 0);
        } catch {
            warn("Failed to parse Global stats. " + getExceptionInfo());
        }
    }

    LBEntry@[]@ GetTop3() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            return g_CustomMap.mapLB;
        }
        return top3;
    }

    LBEntry@[] top3 = {LBEntry(), LBEntry(), LBEntry()};
    void SetTop3FromJson(Json::Value@ j) {
        auto @leader = top3[0];
        for (uint i = 0; i < j.Length; i++) {
            while (i >= top3.Length) {
                top3.InsertLast(LBEntry());
            }
            if (i == 0 && leader.height > 100. && leader.height < float(j[0]["height"])) {
                leader.SetFromJson(j[i]);
                EmitNewWR(leader);
            } else {
                top3[i].SetFromJson(j[i]);
            }
            @pbCache[top3[i].name] = top3[i];
            wsidToPlayerName[top3[i].wsid] = top3[i].name;
        }
        EmitUpdatedTop3();
    }

    LBEntry@[] globalLB = {};
    void UpdateLBFromJson(Json::Value@ j) {
        if (j.Length == 0) return;
        int firstRank = j[0]["rank"];
        int lastRank = j[j.Length-1]["rank"];
        lastRank = Math::Max(j.Length, lastRank);
        while (globalLB.Length < lastRank) {
            globalLB.InsertLast(LBEntry());
        }
        int rank;
        // repurpose lastRank
        lastRank = 0;
        LBEntry@ entry;
        for (uint i = 0; i < j.Length; i++) {
            rank = int(j[i]["rank"]);
            // equal places?
            if (rank <= lastRank) {
                rank = lastRank + 1;
            }
            @entry = globalLB[rank - 1];
            entry.SetFromJson(j[i]);
            @pbCache[entry.name] = entry;
            wsidToPlayerName[entry.wsid] = entry.name;
            lastRank = rank;
            if (i % 50 == 0) yield();
        }
        EmitUpdatedGlobalLB();
    }

    LBEntry myRank = LBEntry();
    void SetMyRankFromJson(Json::Value@ j) {
        myRank.SetFromJson(j);
        @pbCache[myRank.name] = myRank;
        wsidToPlayerName[myRank.wsid] = myRank.name;
        EmitUpdatedMyRank();
    }

    void SetPlayersPBHeightFromJson(Json::Value@ j) {
        auto name = string(j["name"]);
        if (pbCache.Exists(name)) {
            cast<LBEntry@>(pbCache[name]).SetFromJson(j);
        } else {
            auto @entry = LBEntry();
            entry.SetFromJson(j);
            @pbCache[name] = entry;
        }
    }

    dictionary lastUpdateTimes;
    void CheckUpdatePlayersHeight(const string &in login) {
        if (lastUpdateTimes.Exists(login)) {
            if (Time::Now - int(lastUpdateTimes[login]) < 30000) return;
        }
        lastUpdateTimes[login] = Time::Now;
        PushGetPlayerPBRequestToServer(LoginToWSID(login));
    }

    LBEntry@ GetPlayersPBEntryLogin(const string &in login) {
        CheckUpdatePlayersHeight(login);
        auto wsid = LoginToWSID(login);
        if (!wsidToPlayerName.Exists(wsid)) return null;
        string name = string(wsidToPlayerName[wsid]);
        if (pbCache.Exists(name)) {
            return cast<LBEntry@>(pbCache[name]);
        }
        return null;
    }

    LBEntry@ GetPlayersPBEntryWL(const string &in wsid, const string &in login) {
        CheckUpdatePlayersHeight(login);
        if (!wsidToPlayerName.Exists(wsid)) return null;
        string name = string(wsidToPlayerName[wsid]);
        if (pbCache.Exists(name)) {
            return cast<LBEntry@>(pbCache[name]);
        }
        return null;
    }

    LBEntry@ GetPlayersPBEntry(PlayerState@ p) {
        if (p is null) return null;
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            return g_CustomMap.GetPlayersPBEntry(p);
        }
        CheckUpdatePlayersHeight(p.playerLogin);
        if (pbCache.Exists(p.playerName)) {
            return cast<LBEntry@>(pbCache[p.playerName]);
        }
        return null;
    }

    float GetPlayersPBHeight(PlayerState@ player) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            return g_CustomMap.GetPlayersPBHeight(player);
        }
        if (player is null) return -2.;
        auto @pb = GetPlayersPBEntry(player);
        if (pb is null) {
            return -1.;
        }
        return pb.height;
    }

    // donations

    uint lastDonationsUpdate = 0;
    // update at most once per minute
    void CheckUpdateDonations() {
        if (lastDonationsUpdate + 60000 < Time::Now) {
            lastDonationsUpdate = Time::Now;
            PushMessage(GetDonationsMsg());
        }
    }

    Donation@[] donations = {};
    Donor@[] donors = {};
    float totalDonations = 0;

    void SetDonationsFromJson(Json::Value@ j) {
        startnew(CoroutineFuncUserdata(SetDonationsFromJsonAsync), j);
    }

    float gfmDonoAmount = 0.;

    void SetGfmDonationsFromJson(Json::Value@ j) {
        gfmDonoAmount = j['total'];
    }

    void SetDonationsFromJsonAsync(ref@ r) {
        Donations::ResetDonoCheers();
        totalDonations = 0;
        Json::Value@ j = cast<Json::Value>(r);
        auto d = j["donations"];
        auto n = j["donors"];
        while (donations.Length < d.Length) {
            donations.InsertLast(Donation());
        }
        for (uint i = 0; i < d.Length; i++) {
            donations[i].UpdateFromJson(d[i]);
            totalDonations += donations[i].amount;
            Donations::AddDonation(donations[i]);
            if (i % 50 == 0) yield();
        }
        while (donors.Length < n.Length) {
            donors.InsertLast(Donor());
        }
        for (uint i = 0; i < n.Length; i++) {
            donors[i].UpdateFromJson(n[i]);
            if (i % 50 == 0) yield();
        }
        Donations::SortCheers();
    }

    class Donation {
        string name;
        float amount;
        string comment;
        int64 ts;

        void UpdateFromJson(Json::Value@ j) {
            name = j["name"];
            amount = float(j["amount"]);
            comment = j["comment"];
            ts = int64(j["ts"]);
        }
    }

    class Donor {
        string name;
        float amount;

        void UpdateFromJson(Json::Value@ j) {
            name = j["name"];
            amount = float(j["amount"]);
        }
    }
}


[Setting hidden]
bool S_NotifyOnNewWR = true;


uint lastWRTime = 0;
void EmitNewWR(LBEntry@ leader) {
    if (leader.wsid == LocalPlayersWSID()) return;
    if (S_NotifyOnNewWR && Time::Now - lastWRTime > 30000) {
        lastWRTime = Time::Now;
        NotifySuccess("New DD2 WR Height: " + leader.name + " @ " + Text::Format("%.1f m", leader.height));
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


namespace TwitchNames {
    dictionary nameCache;
    void HandleMsg(Json::Value@ j) {
        try {
            string twitch_name = j["twitch_name"];
            string wsid = j["user_id"];
            if (wsid.Length == 0) {
                warn("[TwitchName Msg] No wsid returned? " + Json::Write(j));
            } else if (twitch_name.Length == 0) {
                // ignore unknown
            } else {
                nameCache[wsid] = twitch_name;
                if (wsid == LocalPlayersWSID()) {
                    MainUI::m_TwitchID = twitch_name;
                }
            }
        } catch {
            warn("Exception handling twitch name response: " + Json::Write(j) + ". Exception: " + getExceptionInfo());
        }
    }

    void UpdateMyTwitchName(const string &in twitch_name) {
        PushMessage(ReportTwitchMsg(twitch_name));
    }

    dictionary lastUpdateTimes;
    void CheckUpdateTwitchName(const string &in wsid) {
        if (lastUpdateTimes.Exists(wsid)) {
            if (Time::Now - int(lastUpdateTimes[wsid]) < 120000) return;
        }
        lastUpdateTimes[wsid] = Time::Now;
        PushMessage(GetTwitchMsg(wsid));
    }

    string GetTwitchName(const string &in wsid) {
        CheckUpdateTwitchName(wsid);
        if (nameCache.Exists(wsid)) {
            return string(nameCache[wsid]);
        }
        return "";
    }

    Json::Value@ _NewMsg(const string &in wsid, const string &in name) {
        auto @j = Json::Object();
        j['twitch_name'] = name;
        j['user_id'] = wsid;
        return j;
    }

    void AddDefaults() {
        HandleMsg(_NewMsg("5d6b14db-4d41-47a4-93e2-36a3bf229f9b", "Bren_TM2")); yield();
        HandleMsg(_NewMsg("d46fb45d-d422-47c9-9785-67270a311e25", "eLconn21")); yield();
        HandleMsg(_NewMsg("e3ff2309-bc24-414a-b9f1-81954236c34b", "Lars_tm")); yield();
        HandleMsg(_NewMsg("e5a9863b-1844-4436-a8a8-cea583888f8b", "Hazardu")); yield();
        HandleMsg(_NewMsg("bd45204c-80f1-4809-b983-38b3f0ffc1ef", "Wirtual")); yield();
        HandleMsg(_NewMsg("803695f6-8319-4b8e-8c28-44856834fe3b", "simo_900")); yield();
        HandleMsg(_NewMsg("c1e8bbec-8bb3-40b3-9b0e-52e3cb36015e", "SkandeaR")); yield();
        HandleMsg(_NewMsg("05477e79-25fd-48c2-84c7-e1621aa46517", "GranaDyy")); yield();
        HandleMsg(_NewMsg("da4642f9-6acf-43fe-88b6-b120ff1308ba", "Scrapie")); yield();
        HandleMsg(_NewMsg("a4699c4c-e6c1-4005-86f6-55888f854e6f", "Talliebird")); yield();
        HandleMsg(_NewMsg("b05db0f8-d845-47d2-b0e5-795717038ac6", "MASSA")); yield();
        HandleMsg(_NewMsg("e387f7d8-afb0-4bf6-bb29-868d1a62de3b", "Tarpor")); yield();
        HandleMsg(_NewMsg("d320a237-1b0a-4069-af83-f2c09fbf042e", "Mudda_tm")); yield();
        HandleMsg(_NewMsg("3bb0d130-637d-46a6-9c19-87fe4bda3c52", "Spammiej")); yield();
        HandleMsg(_NewMsg("af30b7a1-fc37-485f-94bf-f00e39805d8c", "Ixxonn")); yield();
        HandleMsg(_NewMsg("fc54a67c-7bd3-4b33-aa7d-a77f13a7b621", "mtat_TM")); yield();
        HandleMsg(_NewMsg("0c857beb-fd95-4449-a669-21fb310cacae", "CarlJrtm")); yield();
        HandleMsg(_NewMsg("e07e9ea9-daa5-4496-9908-9680e35da02b", "BirdieTM")); yield();
        HandleMsg(_NewMsg("24b09acf-f745-408e-80fc-b1141054504c", "SimplyNick")); yield();
        HandleMsg(_NewMsg("ed14ac85-1252-4cc7-8efd-49cd72938f9d", "Jxliano")); yield();
        HandleMsg(_NewMsg("06496fad-70f7-49bc-80c6-d62caa7a9de4", "Hefest")); yield();
        HandleMsg(_NewMsg("21161743-d01c-429f-a50d-8214149df07d", "Ryx_1")); yield();
    }
}
