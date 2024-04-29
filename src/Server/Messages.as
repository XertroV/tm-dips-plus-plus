enum MessageRequestTypes {
    Authenticate = 1,
    ResumeSession = 2,
    ReportContext = 3,
    ReportGameCamNod = 4,

    Ping = 8,

    ReportVehicleState = 32,
    ReportRespawn = 33,
    ReportFinish = 34,
    ReportFallStart = 35,
    ReportFallEnd = 36,
    ReportStats = 37,

    GetMyStats = 128,
    GetGlobalLB = 129,
    GetFriendsLB = 130,

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
    return WrapMsgJson(j, MessageRequestTypes::Authenticate);
}

OutgoingMsg@ ResumeSessionMsg(const string &in session_token) {
    auto @j = Json::Object();
    j["session_token"] = session_token;
    j["plugin_info"] = GetPluginInfo();
    j["game_info"] = GetGameInfo();
    return WrapMsgJson(j, MessageRequestTypes::ResumeSession);
}

OutgoingMsg@ ReportContextMsg() {
    throw("todo: ReportContextMsg");
    auto @j = Json::Object();
    // j["context"] = context;
    // todo
    return WrapMsgJson(j, MessageRequestTypes::ReportContext);
}

OutgoingMsg@ ReportGameCamNodMsg() {
    throw("todo: ReportGameCamNodMsg");
    auto @j = Json::Object();
    // todo
    return WrapMsgJson(j, MessageRequestTypes::ReportGameCamNod);
}

OutgoingMsg@ PingMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::Ping);
}

OutgoingMsg@ ReportVehicleStateMsg(const iso4 &in state, const vec3 &in vel) {
    auto @j = Json::Object();
    j["state"] = Iso4ToJson(state);
    j["vel"] = Vec3ToJson(vel);
    return WrapMsgJson(j, MessageRequestTypes::ReportVehicleState);
}

OutgoingMsg@ ReportRespawnMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::ReportRespawn);
}

OutgoingMsg@ ReportFinishMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::ReportFinish);
}

OutgoingMsg@ ReportFallStartMsg(uint8 floor, vec3 pos, vec3 vel, uint startTime) {
    auto @j = Json::Object();
    j["floor"] = floor;
    j["pos"] = Vec3ToJson(pos);
    j["vel"] = Vec3ToJson(vel);
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

OutgoingMsg@ GetMyStatsMsg() {
    return OutgoingMsg(uint8(MessageRequestTypes::GetMyStats), Json::Object());
}

OutgoingMsg@ GetGlobalLBMsg() {
    return OutgoingMsg(uint8(MessageRequestTypes::GetGlobalLB), Json::Object());
}

// takes WSIDs
OutgoingMsg@ GetFriendsLBMsg(string[]@ friends) {
    auto @j = Json::Array();
    for (uint i = 0; i < friends.Length; i++) {
        j.Add(friends[i]);
    }
    return WrapMsgJson(j, MessageRequestTypes::GetFriendsLB);
}

OutgoingMsg@ StressMeMsg() {
    return OutgoingMsg(uint8(MessageRequestTypes::StressMe), Json::Object());
}
