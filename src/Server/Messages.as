
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
    ReportPlayerColor = 40,
    ReportTwitch = 41,
    DowngradeStats = 42,
    // ReportSessionCL = ??,

    // uid, pos
    ReportMapCurrPos = 64,

    // Aux Map Spec
    ReportCustomMapAuxSpec = 65,
    DeleteCustomMapAuxSpec = 66,
    ListCustomMapAuxSpecs = 67,
    // CM stats
    ReportMapStats = 68,

    // getters
    GetMyStats = 128,
    GetGlobalLB = 129,
    GetFriendsLB = 130,
    GetGlobalOverview = 131,
    GetServerStats = 132,
    GetMyRank = 133,
    GetPlayersPb = 134,
    GetDonations = 135,
    GetGfmDonations = 136,
    GetTwitch = 137,

    GetMyProfile = 138,
    SetMyProfile = 139,
    GetMyPreferences = 140,
    SetMyPreferences = 141,
    GetUsersProfile = 142,
    GetPlayersSpecInfo = 143,

    // uid
    GetMapOverview = 192,
    // uid, start, end
    GetMapLB = 193,
    // uid
    GetMapLive = 194,
    // uid
    GetMapMyRank = 195,
    // uid, wsid
    GetMapRank = 196,

    GetSecretAssets = 254,

    StressMe = 255,
}

enum MessageResponseTypes {
    AuthFail = 1,
    AuthSuccess = 2,
    ContextAck = 3,

    Ping = 8,
    ServerInfo = 9,
    NonFatalErrorMsg = 10,

    NewRecord = 32,

    Stats = 128,
    GlobalLB = 129,
    FriendsLB = 130,
    GlobalOverview = 131,
    Top3 = 132,
    MyRank = 133,
    PlayersPB = 134,
    Donations = 135,
    GfmDonations = 136,
    TwitchName = 137,
    UsersProfile = 138,
    YourPreferences = 139,
    // space for preference/profile stuff
    PlayersSpecInfo = 143,

    MapOverview = 192,
    MapLB = 193,
    MapLivePlayers = 194,
    MapRank = 195,

    TaskResponseJson = 252,
    TaskResponse = 253,
    SecretAssets = 254,
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

// OutgoingMsg@ ReportSessionCL() {
//     auto @j = Json::Object();
//     j["cl"] = CL::GetInfo();
//     return WrapMsgJson(j, MessageRequestTypes::SessionCL);
// }

OutgoingMsg@ ReportContextMsg(uint64 sf, uint64 mi, nat2 bi, bool relevant) {
    auto @j = Json::Object();
    j["sf"] = Text::FormatPointer(sf);
    j["mi"] = Text::FormatPointer(mi);
    j["map"] = Map::GetMapInfo(relevant);
    yield();
    j["i"] = relevant; // Map::I();
    j["bi"] = Nat2ToJson(bi);
    j["e"] = GetApp().Editor !is null;
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

OutgoingMsg@ ReportRespawnMsg(int raceTime) {
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

OutgoingMsg@ DowngradeStatsMsg(Json::Value@ statsJson) {
    auto @j = Json::Object();
    j["stats"] = statsJson;
    return WrapMsgJson(j, MessageRequestTypes::DowngradeStats);
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

OutgoingMsg@ ReportMyColorMsg() {
    auto @j = Json::Object();
    j["wsid"] = LocalPlayersWSID();
    j["color"] = Vec3ToJson(LocalPlayersColor());
    return WrapMsgJson(j, MessageRequestTypes::ReportPlayerColor);
}

OutgoingMsg@ ReportTwitchMsg(const string &in twitch_name) {
    auto @j = Json::Object();
    j["twitch_name"] = twitch_name;
    return WrapMsgJson(j, MessageRequestTypes::ReportTwitch);
}

// use Tasks::GetTaskId or Tasks::GetNewTaskWaiter to get an id
OutgoingMsg@ ReportCustomMapAuxSpecMsg(uint req_id, const string &in name_id, Json::Value@ spec) {
    auto @j = Json::Object();
    j["id"] = req_id;
    j["name_id"] = name_id;
    j["spec"] = spec;
    return WrapMsgJson(j, MessageRequestTypes::ReportCustomMapAuxSpec);
}

// use Tasks::GetTaskId or Tasks::GetNewTaskWaiter to get an id
OutgoingMsg@ DeleteCustomMapAuxSpecMsg(uint req_id, const string &in name_id) {
    auto @j = Json::Object();
    j["id"] = req_id;
    j["name_id"] = name_id;
    return WrapMsgJson(j, MessageRequestTypes::DeleteCustomMapAuxSpec);
}

// use Tasks::GetTaskId or Tasks::GetNewTaskWaiter to get an id
OutgoingMsg@ ListCustomMapAuxSpecsMsg(uint req_id) {
    auto @j = Json::Object();
    j["id"] = req_id;
    return WrapMsgJson(j, MessageRequestTypes::ListCustomMapAuxSpecs);
}

OutgoingMsg@ ReportMapStatsMsg(const string &in uid, Json::Value@ stats) {
    auto @j = Json::Object();
    j["uid"] = uid;
    j["stats"] = stats;
    return WrapMsgJson(j, MessageRequestTypes::ReportMapStats);
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

OutgoingMsg@ GetGlobalOverviewMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::GetGlobalOverview);
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

OutgoingMsg@ GetPlayersPbMsg(const string &in wsid) {
    auto @j = Json::Object();
    j["wsid"] = wsid;
    return WrapMsgJson(j, MessageRequestTypes::GetPlayersPb);
}

OutgoingMsg@ GetDonationsMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::GetDonations);
}

OutgoingMsg@ GetGfmDonationsMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::GetGfmDonations);
}

OutgoingMsg@ GetTwitchMsg(const string &in wsid = "") {
    auto @j = Json::Object();
    if (wsid.Length > 0) j['wsid'] = wsid;
    return WrapMsgJson(j, MessageRequestTypes::GetTwitch);
}


OutgoingMsg@ StressMeMsg() {
    return OutgoingMsg(uint8(MessageRequestTypes::StressMe), Json::Object());
}




OutgoingMsg@ ReportMapCurrPosMsg(const string &in uid, const vec3 &in pos, int64 race_time) {
    auto @j = Json::Object();
    j["uid"] = uid;
    j["pos"] = Vec3ToJson(pos);
    j["race_time"] = race_time;
    return WrapMsgJson(j, MessageRequestTypes::ReportMapCurrPos);
}

OutgoingMsg@ GetMapOverviewMsg(const string &in uid) {
    auto @j = Json::Object();
    j["uid"] = uid;
    return WrapMsgJson(j, MessageRequestTypes::GetMapOverview);
}

OutgoingMsg@ GetMapLBMsg(const string &in uid, uint start, uint end) {
    auto @j = Json::Object();
    j["uid"] = uid;
    j["start"] = start;
    j["end"] = end;
    return WrapMsgJson(j, MessageRequestTypes::GetMapLB);
}

OutgoingMsg@ GetMapLiveMsg(const string &in uid) {
    auto @j = Json::Object();
    j["uid"] = uid;
    return WrapMsgJson(j, MessageRequestTypes::GetMapLive);
}

OutgoingMsg@ GetMapMyRankMsg(const string &in uid) {
    auto @j = Json::Object();
    j["uid"] = uid;
    return WrapMsgJson(j, MessageRequestTypes::GetMapMyRank);
}

OutgoingMsg@ GetMapRankMsg(const string &in uid, const string &in wsid) {
    auto @j = Json::Object();
    j["uid"] = uid;
    j["wsid"] = wsid;
    return WrapMsgJson(j, MessageRequestTypes::GetMapRank);
}

OutgoingMsg@ GetServerStatsMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::GetServerStats);
}


OutgoingMsg@ GetMyProfileMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::GetMyProfile);
}

OutgoingMsg@ SetMyProfileMsg(Json::Value@ profile) {
    auto @j = Json::Object();
    j["body"] = profile;
    return WrapMsgJson(j, MessageRequestTypes::SetMyProfile);
}

OutgoingMsg@ GetMyPreferencesMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::GetMyPreferences);
}

OutgoingMsg@ SetMyPreferencesMsg(Json::Value@ prefs) {
    auto @j = Json::Object();
    j["body"] = prefs;
    return WrapMsgJson(j, MessageRequestTypes::SetMyPreferences);
}

OutgoingMsg@ GetPlayersSpecInfoMsg(const string &in wsid, const string &in uid) {
    auto @j = Json::Object();
    j["wsid"] = wsid;
    j["uid"] = uid;
    return WrapMsgJson(j, MessageRequestTypes::GetPlayersSpecInfo);
}



OutgoingMsg@ GetSecretAssetsMsg() {
    return WrapMsgJson(Json::Object(), MessageRequestTypes::GetSecretAssets);
}
