/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
enum MessageRequestTypes {
    Authenticate = 1,
    ResumeSession = 2,
    ReportContext = 3,
    ReportGCNodMsg = 4,

    Ping = 8,

    ReportVehicleState = 32,
    ReportRespawn = 33,
    ReportFinish = 34,
    ReportFallStart = 35,
    ReportFallEnd = 36,
    ReportStats = 37,
    // ReportMapLoad = 38,
    ReportPBHeight = 39,

    GetMyStats = 128,
    GetGlobalLB = 129,
    GetFriendsLB = 130,
    GetGlobalOverview = 131,
    GetServerStats = 132,
    GetMyRank = 133,

    StressMe = 255,
}

enum MessageResponseTypes {
    AuthFail = 1,
    AuthSuccess = 2,
    ContextAck = 3,

    Ping = 8,
    ServerInfo = 9,

    NewRecord = 32,

    Stats = 128,
    GlobalLB = 129,
    FriendsLB = 130,
    GlobalOverview = 131,
    Top3 = 132,
    MyRank = 133,
}

OutgoingMsg@ WrapMsgJson(Json::Value@ inner, MessageRequestTypes type) {
    auto @j = Json::Object();
    j[tostring(type)] = inner;
    return OutgoingMsg(uint8(type), j);
}

OutgoingMsg@ AuthenticateMsg(const string &in token) {
    auto @j = Json::Object();
    j["token"] = token;
    j["plugin_info"] = GetPluginInfo();
    j["game_info"] = GetGameInfo();
    j["gamer_info"] = GetGameRunningInfo();
    return WrapMsgJson(j, MessageRequestTypes::Authenticate);
}

OutgoingMsg@ ResumeSessionMsg(const string &in session_token) {
    auto @j = Json::Object();
    j["session_token"] = session_token;
    j["plugin_info"] = GetPluginInfo();
    j["game_info"] = GetGameInfo();
    j["gamer_info"] = GetGameRunningInfo();
    return WrapMsgJson(j, MessageRequestTypes::ResumeSession);
}

bool creatingCtxMsg = false;
OutgoingMsg@ ReportContextMsg(uint64 sf, uint64 mi, nat2 bi, bool relevant) {
    while (creatingCtxMsg) yield();
    creatingCtxMsg = true;
    auto @j = Json::Object();
    j["sf"] = Text::FormatPointer(sf);
    j["mi"] = Text::FormatPointer(mi);
    j["map"] = Map::GetMapInfo(relevant);
    yield();
    j["i"] = Map::I();
    j["bi"] = Nat2ToJson(bi);
    creatingCtxMsg = false;
    return WrapMsgJson(j, MessageRequestTypes::ReportContext);
}

OutgoingMsg@ ReportGCNodMsg(const string &in gcBase64) {
    auto @j = Json::Object();
    j["data"] = gcBase64;
    return WrapMsgJson(j, MessageRequestTypes::ReportGCNodMsg);
}

OutgoingMsg@ PingMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::Ping);
}

OutgoingMsg@ ReportVehicleStateMsg(CSceneVehicleVisState@ p) {
    return ReportVehicleStateMsg(p.Position, quat(DirUpLeftToMat(p.Dir, p.Up, p.Left)), p.WorldVel);
}

OutgoingMsg@ ReportVehicleStateMsg(PlayerState@ p) {
    return ReportVehicleStateMsg(p.pos, p.rot, p.vel);
}

OutgoingMsg@ ReportVehicleStateMsg(const vec3 &in pos, const quat &in rotq, const vec3 &in vel) {
    auto @j = Json::Object();
    j["pos"] = Vec3ToJson(pos);
    j["rotq"] = QuatToJson(rotq);
    j["vel"] = Vec3ToJson(vel);
    return WrapMsgJson(j, MessageRequestTypes::ReportVehicleState);
}

OutgoingMsg@ ReportRespawnMsg(uint raceTime) {
    auto @j = Json::Object();
    j["race_time"] = raceTime;
    return WrapMsgJson(j, MessageRequestTypes::ReportRespawn);
}

OutgoingMsg@ ReportFinishMsg(uint raceTime) {
    auto @j = Json::Object();
    j["race_time"] = raceTime;
    return WrapMsgJson(j, MessageRequestTypes::ReportFinish);
}

OutgoingMsg@ ReportFallStartMsg(uint8 floor, vec3 pos, vec3 vel, uint startTime) {
    auto @j = Json::Object();
    j["floor"] = floor;
    j["pos"] = Vec3ToJson(pos);
    j["speed"] = vel.Length() * 3.6;
    j["start_time"] = startTime;
    return WrapMsgJson(j, MessageRequestTypes::ReportFallStart);
}

OutgoingMsg@ ReportFallEndMsg(uint8 floor, vec3 pos, uint endTime) {
    auto @j = Json::Object();
    j["floor"] = floor;
    j["pos"] = Vec3ToJson(pos);
    j["end_time"] = endTime;
    return WrapMsgJson(j, MessageRequestTypes::ReportFallEnd);
}

OutgoingMsg@ ReportStatsMsg(Json::Value@ statsJson) {
    auto @j = Json::Object();
    j["stats"] = statsJson;
    return WrapMsgJson(j, MessageRequestTypes::ReportStats);
}

// OutgoingMsg@ ReportMapLoad(const string &in uid) {
//     auto @j = Json::Object();
//     j["uid"] = uid;
//     return WrapMsgJson(j, MessageRequestTypes::ReportMapLoad);
// }

OutgoingMsg@ ReportPBHeightMsg(float height) {
    auto @j = Json::Object();
    j["h"] = height;
    return WrapMsgJson(j, MessageRequestTypes::ReportPBHeight);
}

OutgoingMsg@ GetMyStatsMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::GetMyStats);
    // return OutgoingMsg(uint8(MessageRequestTypes::GetMyStats), Json::Object());
}

OutgoingMsg@ GetGlobalLBMsg(uint start, uint end) {
    auto j = Json::Object();
    j["start"] = start;
    j["end"] = end;
    return WrapMsgJson(j, MessageRequestTypes::GetGlobalLB);
    // return OutgoingMsg(uint8(MessageRequestTypes::GetGlobalLB), Json::Object());
}

// takes WSIDs
OutgoingMsg@ GetFriendsLBMsg(string[]@ friends) {
    auto @j = Json::Array();
    for (uint i = 0; i < friends.Length; i++) {
        j.Add(friends[i]);
    }
    return WrapMsgJson(j, MessageRequestTypes::GetFriendsLB);
}

OutgoingMsg@ GetMyRankMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::GetMyRank);
}

OutgoingMsg@ StressMeMsg() {
    return OutgoingMsg(uint8(MessageRequestTypes::StressMe), Json::Object());
}
