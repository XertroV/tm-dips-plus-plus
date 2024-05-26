namespace MapCustomInfo {
    const string BEGIN_DPP_COMMENT = "--BEGIN-DPP--";
    const string END_DPP_COMMENT = "--END-DPP--";

    class DipsSpec {
        string url;
        float start;
        float finish;
        float[] floors;

        DipsSpec(const string &in mapComment) {
            auto @parts = mapComment.Split(BEGIN_DPP_COMMENT, 2);
            if (parts.Length < 2) throw("missing " + BEGIN_DPP_COMMENT);
            @parts = parts[1].Split(END_DPP_COMMENT, 2);
            if (parts.Length < 2) throw("missing " + END_DPP_COMMENT);
            ParseCommentInner(parts[0]);
        }

        void ParseCommentInner(const string &in comment) {
            auto lines = comment.Split("\n");
            for (uint i = 0; i < lines.Length; i++) {
                auto line = lines[i].Trim();
                if (line.Length == 0) {
                    continue;
                }
                if (line.StartsWith("#") || line.StartsWith("--") || line.StartsWith("//")) {
                    continue;
                }
                auto parts = line.Split("=", 2);
                if (parts.Length < 2) throw("missing '=' in line: " + i + " : " + line);
                auto key = parts[0].Trim();
                auto value = parts[1].Trim();
                if (key == "url") {
                    url = value;
                } else {
                    SetKv(key, value);
                }
            }
            if (url.Length > 0) {
                LoadFromUrl();
            }
            if (floors.Find(finish) < 0) {
                floors.InsertLast(finish);
            }
        }

        void LoadFromUrl() {
            warn("todo: LoadFromUrl");
            // handle !2xx & non json errors
        }

        void SetKv(const string &in key, const string &in value) {
            if (key.StartsWith("floor")) {
                auto floorIx = ParseFloorNum(key);
                if (floorIx < 0) {
                    throw("Invalid floor index: " + key);
                    return;
                }
                while (floorIx >= floors.Length) {
                    floors.InsertLast(-1.0);
                }
                floors[floorIx] = ParseFloat(value);
            } else if (key == "start") start = ParseFloat(value);
            else if (key == "finish") finish = ParseFloat(value);
            else {
                warn("Unknown key: " + key + " with value: " + value);
            }
        }
    }

    float ParseFloat(const string &in value) {
        try {
            return Text::ParseFloat(value);
        } catch {
            throw("Failed to parse float from string: " + value + " / raw exception: " + getExceptionInfo());
        }
        return -1.0;
    }

    int ParseFloorNum(const string &in key) {
        auto parts = key.Split("floor", 2);
        if (parts.Length < 2) {
            return -1;
        }
        try {
            return Text::ParseInt(parts[1]);
        } catch {
            throw("Failed to parse floor number from string: " + key + " / raw exception: " + getExceptionInfo());
        }
        return -1;
    }

    bool ShouldActivateForMap(CGameCtnChallenge@ map) {
        return HasBuiltInInfo(map.Id.Value)
            || CommentContainsBegin(map.Comments)
            || map.MapInfo.MapUid == S_DD2EasyMapUid
            || map.MapInfo.MapUid == DD2_MAP_UID;
    }

    bool CommentContainsBegin(const string &in comment) {
        return comment.Contains(BEGIN_DPP_COMMENT);
    }

    string lastParseFailReason;
    DipsSpec@ TryParse_Async(const string &in comment) {
        if (comment.Length < 10 || !CommentContainsBegin(comment)) {
            return null;
        }
        try {
            auto s = DipsSpec(comment);
            trace("parsed dips spec successfully");
            lastParseFailReason = "";
            return s;
        } catch {
            lastParseFailReason = getExceptionInfo();
            NotifyWarning("error parsing dips spec: " + lastParseFailReason);
            return null;
        }
    }

    uint[] builtInUidMwIds;
    string[] builtInMapComments;

    bool HasBuiltInInfo(uint uidMwId) {
        if (builtInUidMwIds.Length == 0) {
            PopulateBuiltInMaps();
        }
        return builtInUidMwIds.Find(uidMwId) >= 0;
    }

    DipsSpec@ GetBuiltInInfo_Async(uint uidMwId) {
        if (builtInUidMwIds.Length == 0) {
            PopulateBuiltInMaps();
        }
        int ix;
        if ((ix = builtInUidMwIds.Find(uidMwId)) < 0) {
            trace("Did not find built in map info for uidMwId: " + uidMwId);
            return null;
        }
        trace("Found built in map info for uidMwId: " + uidMwId + " at ix: " + ix);
        return TryParse_Async(builtInMapComments[ix]);
    }

    void PopulateBuiltInMaps() {
        if (builtInUidMwIds.Length > 0) {
            return;
        }
        builtInUidMwIds.InsertLast(GetMwIdValue("368fb3vahQeVfD0mP6amCNoYqWc"));
        builtInMapComments.InsertLast(DeepDip1_MapComment);
    }
}



const string DeepDip1_MapComment = """
--BEGIN-DPP--
--
-- Dips++ Custom Map example; comments using `--`, `//` or `#`
--   * Structured as `<key> = <value>` pairs.
--
-- `url` is optional; this is where features like custom triggers,
--   asset lists, etc will go in future.
url = https://assets.xk.io/d++/deepdip1-spec.json

-- start and finish will be inferred if not present based on map waypoint locations.
start = 26.0
finish = 1938.0

-- floors start at 00 for the ground and increase from there. If you miss a number,
--   it will be set to a height of -1.0.
floor00 = 4.0
floor01 = 138
floor02 = 266.0
floor03 = 394.0
floor04 = 522.0
floor05 = 650.0
floor06 = 816.0
floor07 = 906.0
floor08 = 1026.0
floor09 = 1170.0
floor10 = 1296.0
floor11 = 1426.0
floor12 = 1554.0
floor13 = 1680.0
floor14 = 1824.0

-- blank lines are ignored.

--END-DPP--
""";
