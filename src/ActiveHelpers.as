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

bool MapMatchesDD2Uid(CGameCtnChallenge@ map) {
    if (map is null) return false;
    if (map.EdChallengeId.Length == 0) return false;
    if (S_ActiveForMapUids != "*" && !S_ActiveForMapUids.Contains(map.EdChallengeId)) return false;
    return true;
}

// [Setting hidden]
const string S_ActiveForMapUids = DD2_MAP_UID;
