// Helpers for whether we're active or not

bool MapMatches(CGameCtnChallenge@ map) {
    if (map is null) return false;
    if (map.EdChallengeId.Length == 0) return false;
    if (S_ActiveForMapUids != "*" && !S_ActiveForMapUids.Contains(map.EdChallengeId)) return false;
    return true;
}

[Setting hidden]
string S_ActiveForMapUids = "";
