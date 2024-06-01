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

namespace MatchDD2 {
    uint lastMapMwId = 0;
    bool lastMapMatchesAnyDD2Uid = false;
    bool isEasyDD2Map = false;
    bool isDD2Proper = false;

    bool MapMatchesDD2Uid(CGameCtnChallenge@ map) {
        if (map is null) return false;
        if (map.EdChallengeId.Length == 0) return false;
        if (lastMapMwId == map.Id.Value) return lastMapMatchesAnyDD2Uid;
        lastMapMwId = map.Id.Value;
        isEasyDD2Map = (map.EdChallengeId == S_DD2EasyMapUid
                    ||  map.EdChallengeId == DD2_EASY_MAP_UID2);
        isDD2Proper = map.EdChallengeId == DD2_MAP_UID;
#if DEV
        isDD2Proper = isDD2Proper || map.EdChallengeId == "dh2ewtzDJcWByHcAmI7j6rnqjga";
#endif
        lastMapMatchesAnyDD2Uid = isEasyDD2Map || isDD2Proper;
        return lastMapMatchesAnyDD2Uid;
            // || S_ActiveForMapUids == "*"
    }

    bool VerifyIsDD2(CGameCtnApp@ app) {
        if (app.RootMap is null) return false;
        return VerifyIsDD2(app.RootMap.EdChallengeId);
    }

    bool VerifyIsDD2(const string &in uid) {
#if DEV
        if (uid == "dh2ewtzDJcWByHcAmI7j6rnqjga") {
            return true;
        }
#endif
        return uid == DD2_MAP_UID;
    }
}

// [Setting hidden]
const string S_ActiveForMapUids = DD2_MAP_UID;

const string S_DD2EasyMapUid = "DeepDip2__The_Gentle_Breeze";
