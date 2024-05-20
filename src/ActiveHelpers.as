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
    bool lastMapMatchesDD2Uid = false;
    bool isEasyDD2Map = false;

    bool MapMatchesDD2Uid(CGameCtnChallenge@ map) {
        if (map is null) return false;
        if (map.EdChallengeId.Length == 0) return false;
        if (lastMapMwId == map.Id.Value) return lastMapMatchesDD2Uid;
        lastMapMwId = map.Id.Value;
        isEasyDD2Map = S_EnableForEasyMap
                    && (map.EdChallengeId == S_DD2EasyMapUid
                    ||  map.EdChallengeId == DD2_EASY_MAP_UID2);
        lastMapMatchesDD2Uid = isEasyDD2Map
            || S_ActiveForMapUids == map.EdChallengeId
            ;
        return lastMapMatchesDD2Uid;
            // || S_ActiveForMapUids == "*"
    }
}

// [Setting hidden]
const string S_ActiveForMapUids = DD2_MAP_UID;

const string S_DD2EasyMapUid = "DeepDip2__The_Gentle_Breeze";
