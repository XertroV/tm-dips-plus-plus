/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
// Helpers for whether we're active or not

const string TESTING_MAP_UID = "dh2ewtzDJcWByHcAmI7j6rnqjga";

namespace MatchDD2 {
    uint lastMapMwId = 0;
    bool lastMapMatchesAnyDD2Uid = false;
    bool isEasyDD2Map = false;
    // only the full map
    bool isDD2Proper = false;
    // full or many cps or cp / floor
    bool isDD2Any = false;


    bool MapMatchesDD2Uid(CGameCtnChallenge@ map) {
        if (map is null) return false;
        if (map.EdChallengeId.Length == 0) return false;
        if (lastMapMwId == map.Id.Value) return lastMapMatchesAnyDD2Uid;
        lastMapMwId = map.Id.Value;
        isEasyDD2Map = (map.EdChallengeId == S_DD2EasyMapUid
                    ||  map.EdChallengeId == DD2_EASY_MAP_UID2);
        isDD2Proper = map.EdChallengeId == DD2_MAP_UID;
#if DEV
        isDD2Proper = isDD2Proper || map.EdChallengeId == TESTING_MAP_UID;
#endif
        isDD2Any = isDD2Proper || IsDD2MapUid(map.EdChallengeId);
        lastMapMatchesAnyDD2Uid = isEasyDD2Map || isDD2Any;
        return lastMapMatchesAnyDD2Uid;
    }

    bool VerifyIsDD2(CGameCtnApp@ app) {
        if (app.RootMap is null) return false;
        return VerifyIsDD2(app.RootMap.EdChallengeId);
    }

    // Check if it is a DD2 map (full, cp / floor, many cps)
    bool VerifyIsDD2(const string &in uid) {
#if DEV
        if (uid == TESTING_MAP_UID) {
            return true;
        }
#endif
        return IsDD2MapUid(uid);
    }
}

const string S_DD2EasyMapUid = "DeepDip2__The_Gentle_Breeze";
