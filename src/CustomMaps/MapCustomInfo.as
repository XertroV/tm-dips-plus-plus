namespace MapCustomInfo {
    const string BEGIN_DPP_COMMENT = "--BEGIN-DPP--";
    const string END_DPP_COMMENT = "--END-DPP--";

    class DipsSpec {
        string url;
        FloorSpec start = FloorSpec();
        FloorSpec finish = FloorSpec();
        FloorSpec[]@ floors;
        string[] customLabels;
        bool lastFloorEnd = false;
        bool minClientPass = true;

        DipsSpec(const string &in mapComment) {
            @floors = {};
            auto @parts = mapComment.Split(BEGIN_DPP_COMMENT, 2);
            if (parts.Length < 2) throw("missing " + BEGIN_DPP_COMMENT);
            @parts = parts[1].Split(END_DPP_COMMENT, 2);
            if (parts.Length < 2) throw("missing " + END_DPP_COMMENT);
            ParseCommentInner(parts[0]);
            if (!minClientPass) {
                NotifyError("This map requires a newer version of Dips++.\nYou have: " + PluginVersion + "\nRequired: " + minClientVersion);
            }
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
                SetKv(key, value);
            }
            if (url.Length > 0) {
                LoadFromUrl();
            }
            if (start.height < 0.0 || finish.height < 0.0) {
                auto minMax = GetMinMaxHeight(cast<CSmArenaClient>(GetApp().CurrentPlayground));
                if (start.height < 0) start.height = minMax.x;
                if (finish.height < 0) finish.height = minMax.y;
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
            if (key == "url") {
                url = value;
            } else if (key.StartsWith("floor")) {
                auto floorIx = ParseFloorNum(key);
                if (floorIx < 0) {
                    throw("Invalid floor index: " + key);
                    return;
                }
                while (floorIx >= int(floors.Length)) {
                    floors.InsertLast(FloorSpec());
                }
                floors[floorIx] = ParseFloorVal(value);
            } else if (key == "start") start = ParseFloorVal(value);
            else if (key == "finish") finish = ParseFloorVal(value);
            else if (key == "lastFloorEnd") lastFloorEnd = value.ToLower() == "true";
            else if (key == "minClientVersion") minClientPass = CheckMinClientVersion(value);
            else {
                warn("Unknown key: " + key + " with value: " + value);
            }
        }
    }

    string minClientVersion = "";
    // Returns true if the plugin version >= value (which is the minClientVersion from a map we want to test)
    bool CheckMinClientVersion(const string &in value, const string &in currPluginVersion = "") {
        minClientVersion = value;
        if (value.Length == 0 || value == "0.0.0") {
            return true;
        }
        string pluginVersion = currPluginVersion.Length > 0 ? currPluginVersion : PluginVersion;
        auto pvParts = pluginVersion.Split(".");
        auto mvParts = value.Split(".");

        auto nbCompare = Math::Max(mvParts.Length, pvParts.Length);
        int mv, pv;
        for (uint i = 0; i < uint(nbCompare); i++) {
            if (i < mvParts.Length) {
                if (!Text::TryParseInt(mvParts[i], mv)) mv = 0;
            } else mv = 0;
            if (i < pvParts.Length) {
                if (!Text::TryParseInt(pvParts[i], pv)) pv = 0;
            } else pv = 0;
            // print("comparing: " + i + " | mv: " + mv + " pv: " + pv);
            // int mv = i < mvParts.Length ? Text::ParseInt(mvParts[i]) : 0;
            // int pv = i < pvParts.Length ? Text::ParseInt(pvParts[i]) : 0;
            if (pv > mv) return true;
            if (pv < mv) return false;
        }
        return true;
    }

    FloorSpec@ ParseFloorVal(const string &in value) {
        string[]@ parts;
        if (value.Contains("|")) {
            @parts = value.Split("|");
        }
        // if there's no label
        if (parts is null || parts.Length == 0) {
            return FloorSpec(ParseFloat(value));
        }
        // otherwise parse height and label
        auto fHeight = ParseFloat(parts[0].Trim());
        string fLabel = parts.Length < 2 ? "" : parts[1].Trim();
        return FloorSpec(fHeight, fLabel);
    }

    float ParseFloat(const string &in value) {
        try {
            return Text::ParseFloat(value);
        } catch {
            throw("Failed to parse float from string: " + value + " / raw exception: " + getExceptionInfo());
        }
        return -1.0;
    }

    // key = floorXX
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
        return ShouldActivateForMap(map.MapInfo.MapUid, map.Comments);
    }
    bool ShouldActivateForMap(const string &in mapUid, const string &in comments) {
        return HasBuiltInInfo(GetMwIdValue(mapUid))
            || CommentContainsBegin(comments)
            || mapUid == S_DD2EasyMapUid
            || MatchDD2::VerifyIsDD2(mapUid);
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
        // deep dip
        builtInUidMwIds.InsertLast(GetMwIdValue("368fb3vahQeVfD0mP6amCNoYqWc"));
        builtInMapComments.InsertLast(DeepDip1_MapComment);
        // deep dip cp per floor
        builtInUidMwIds.InsertLast(GetMwIdValue("xkSwOrkadsrSGx6L2WSlz7gqMr3"));
        builtInMapComments.InsertLast(DeepDip1_MapComment);
        // deep dip many cps
        builtInUidMwIds.InsertLast(GetMwIdValue("NKGeJgC73K1Yw9IHHpoCzbYTXU6"));
        builtInMapComments.InsertLast(DeepDip1_MapComment);
    }

    void AddNewMapComment(const string &in uid, const string &in comment) {
        auto uidMwId = GetMwIdValue(uid);
        auto ix = builtInUidMwIds.Find(uidMwId);
        if (ix >= 0) {
            builtInMapComments[ix] = comment;
            return;
        }
        builtInUidMwIds.InsertLast(uidMwId);
        builtInMapComments.InsertLast(comment);
    }
}

class FloorSpec {
    string label;
    float height;
    FloorSpec(float h, const string &in l = "") {
        height = h;
        label = l;
    }
    FloorSpec() {
        height = -1.0;
        label = "";
    }

    bool opEquals(const FloorSpec &in other) const {
        return height == other.height && label == other.label;
    }

    string GenLabel(int ix, int finNumber, int endNumber) const {
        // endNumber checked after finNumber since it is eq when lastFloorEnd disabled.
        if (ix < 0) throw("GenLabel: invalid negative ix: " + ix);
        if (label.Length > 0) return label;
        if (ix == 0) return "F.G.";
        if (ix >= finNumber) return "Fin";
        if (ix == endNumber) return "End";
        return Text::Format("%02d", ix);
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
finish = 1970.0

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
floor15 = 1938.0

-- if true, the last floor's label will be 'End' instead of '15' or whatever floor it is.
--   (default: false)
lastFloorEnd = true

-- blank lines are ignored.

--END-DPP--
""";
