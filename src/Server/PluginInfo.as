/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
string GetPluginInfo() {
    auto p = Meta::ExecutingPlugin();
    string[] infos;
    infos.InsertLast("Name:" + p.Name);
    infos.InsertLast("Version:" + p.Version);
    infos.InsertLast("Type:" + tostring(p.Type));
    infos.InsertLast("Source:" + tostring(p.Source));
    infos.InsertLast("SourceP:" + p.SourcePath.Replace(IO::FromDataFolder(""), ""));
    infos.InsertLast("SigLvl:" + tostring(p.SignatureLevel));
    return string::Join(infos, "\n");
}

string GetGameInfo() {
    auto app = GetApp();
    auto platform = app.SystemPlatform;
    string[] infos;
    infos.InsertLast("ExeVersion:" + platform.ExeVersion);
    infos.InsertLast("Timezone:" + platform.CurrentTimezoneTimeOffset);
    infos.InsertLast("ExtraTool_Info:" + platform.ExtraTool_Info);
    infos.InsertLast("ExtraTool_Data:" + platform.ExtraTool_Data);
    return string::Join(infos, "\n");
}

string GetGameRunningInfo() {
    auto app = GetApp();
    auto platform = app.SystemPlatform;
    string[] infos;
    infos.InsertLast("Now:" + Time::Now);
    infos.InsertLast("SinceInit:" + app.TimeSinceInitMs);
    infos.InsertLast("TS:" + Time::Stamp);
    infos.InsertLast("D:" + tostring(Meta::IsDeveloperMode()));
    return string::Join(infos, "\n");
}

string ServerInfo() {
    auto net = cast<CTrackManiaNetwork>(GetApp().Network);
    auto si = cast<CTrackManiaNetworkServerInfo>(net.ServerInfo);
    if (si is null) return "no_server";
    return si.ServerLogin;
}

namespace GC {
    uint16 _offset = 0;
    uint16 GetOffset() {
        if (_offset == 0) {
            auto ty = Reflection::GetType("CGameCtnApp");
            _offset = ty.GetMember("GameScene").Offset + 0x10;
        }
        return _offset;
    }

    string GetInfo() {
        auto app = GetApp();
        if (app.GameScene is null) return "no_scene";
        auto ptr = Dev::GetOffsetUint64(app, GC::GetOffset());
        if (ptr == 0) return "no_ptr";
        if (ptr % 8 != 0) return "bad_ptr";
        auto buf = MemoryBuffer(0x2E0);
        for (uint o = 0; o < 0x2E0; o += 8) {
            buf.Write(Dev::ReadUInt64(ptr + o));
        }
        buf.Seek(0);
        return buf.ReadToBase64(0x2E0, true);
    }
}

namespace MI {
    uint16 _offset = 0;
    uint16 GetOffset() {
        if (_offset == 0) {
            auto ty = Reflection::GetType("ISceneVis");
            _offset = ty.GetMember("HackScene").Offset - 0x18;
        }
        return _offset;
    }

    uint GetLen(ISceneVis@ scene) {
        if (scene is null) return 0;
        return Dev::GetOffsetUint32(scene, GetOffset() + 0x8);
    }

    uint64 GetPtr(ISceneVis@ scene) {
        if (scene is null) return 0;
        return Dev::GetOffsetUint64(scene, GetOffset());
    }

    uint64 GetInfo() {
        auto app = GetApp();
        if (app.GameScene is null) return 0;
        auto len = GetLen(app.GameScene);
        auto ptr = GetPtr(app.GameScene);
        if (ptr == 0 || len == 0) return 0;
        if (ptr % 8 != 0) return 0;
        // return ptr << 16 | len;
        uint64 ret = 0;
        for (uint i = 0; i < len; i++) {
            auto x = Dev::ReadUInt32(ptr + i * 0x18 + 0x10);
            ret = ret | (uint64(1) << x);
        }
        return ret;
    }
}

namespace SF {
    uint64[] ptrs = {};
    uint64[]@ GetPtrs(bool do_yield = false) {
        if (ptrs.Length == 0) {
            for (uint i = 0; i < 15; i++) {
                if (do_yield && i > 0) {
                    yield();
                }
                ptrs.InsertLast(FindPtr(i));
            }
        };
        return ptrs;
    }

    void LoadPtrs() {
        GetPtrs(true);
    }

    uint64 FindPtr(uint i) {
        switch (i) {
            case 0: return GetGameAddr("8B 15 4D A5 EF 01 33 DB 4C 8B 6C 24 30 48 8B 74 24 40 85 D2 74 5E 0F 1F 44 00 00", 6);
            case 1: return GetGameAddr("8B 05 C0 D9 CE 01 8B FA 85 C0 74 1C 85 D2 75 18 45 33 C0 8D 57 01 48 8D 0D", 6);
            case 2: return GetGameAddr("83 3D 3A 54 AA 00 00 0F 84 08 01 00 00 45 85 C9 0F 84 FF 00 00 00", 7, 2);
            case 4: return GetGameAddr("44 39 05 9A B3 48 01 74 2A 49 8B 82 98 04 00 00 44 89 05 8A B3 48 01 48 8B", 7);
            case 5: return GetGameAddr("8B 05 1F FB DB 01 89 43 40 8B 05 1A FB DB 01 89 43 44 8B 86 80 00 00 00 89 43 74 8B", 6);
            case 6: return GetGameAddr("8B 0D 29 7D 7B 01 33 D2 8B 05 AD 38 5C 01 44 8B C2 0F 10 05 7B 38 5C 01 89 05", 6);
            case 8: return GetGameAddr("44 8B 0D 49 4D 76 01 F3 0F 5C CA F3 0F 58 E5 F3 0F 58 D0 F3 0F 11 5C 24 60", 7);
            case 9: return GetGameAddr("39 35 EB 7E 58 01 8D 04 45 01 00 00 00 41 89 87 18 03 00 00 0F 85 33 01 00 00", 6);
            case 12: return GetGameAddr("83 3D B5 77 6D 01 00 4C 8B AC 24 90 01 00 00 74 2B 83 3D A8 77 6D 01 00 74 22", 7, 2);
            case 13: return GetGameAddr("83 3D 39 E5 6F 01 00 44 0F 28 84 24 80 01 00 00 0F 28 B4 24 A0 01 00 00 75 0A C7", 7, 2);
            case 14: return GetGameAddr("89 05 3D 43 10 01 48 8B 07 4C 89 68 10 48 8B 37 48 8B 4E 10 48 8D 56 10 41", 6);
        }
        return 0;
    }

    const int[] lambda = {69, 59, 136, 1, 26, 77, 41, 1, 95, 53, 1, 1, 86, 62, 89};
    uint64 GetInfo() {
        auto ptrs = GetPtrs();
        uint64 ret = 1;
        auto ba = Dev::BaseAddress();
        for (uint i = 0; i < ptrs.Length; i++) {
            auto ptr = ptrs[i];
            if (ptr == 0) continue;
            if (ptr % 8 != 0) continue;
            if (ptr < ba) continue;
            auto x = Math::Clamp(Dev::ReadInt32(ptr), 0, 1);
            ret *= (x * lambda[i]);
            if (ret & 3 == 0) {
                ret = ret >> 2;
            } else if (ret & 1 == 0) {
                ret = ret >> 1;
            }
        }
        return ret;
    }

    uint64 GetGameAddr(const string &in pattern, int offset) {
        if (offset < 4) return 0;
        return GetGameAddr(pattern, offset, offset - 4);
    }
    uint64 GetGameAddr(const string &in pattern, int offset, int offsetOfRel) {
        auto ptr = Dev::FindPattern(pattern);
        if (ptr < Dev::BaseAddress()) return 0;
        int32 rel = Dev::ReadInt32(ptr + offsetOfRel);
        uint64 ret = ptr + offset + rel;
        return ret;
    }
}

namespace Map {
    Json::Value@ lastMapInfo = Json::Value();
    uint lastMapMwId;

    bool gettingMapInfo = false;
    Json::Value@ GetMapInfo(bool relevant) {
        while (gettingMapInfo) yield();
        gettingMapInfo = true;
        Json::Value@ j = Json::Object();

        auto map = GetApp().RootMap;
        if (map is null) {
            lastMapMwId = 0;
            @lastMapInfo = Json::Value();
            gettingMapInfo = false;
            return lastMapInfo;
        }
        if (map.Id.Value == lastMapMwId) return lastMapInfo;

        try {
            lastMapMwId = map.Id.Value;
            if (relevant) {
                j["uid"] = map.EdChallengeId;
            } else {
                j["uid"] = map.EdChallengeId.SubStr(0, 23) + "xxxx";
            }
            j["name"] = relevant ? string(map.MapName) : "<!:;not relevant>";
            j["hash"] = GetMapHash(map);
        } catch {
            string info = getExceptionInfo();
            warn("Failed to get map info: " + info);
        }

        @lastMapInfo = j;
        gettingMapInfo = false;

        return j;
    }

    bool I() {
        auto map = GetApp().RootMap;
        if (map is null) return false;
        CGameItemModel@ item;
        MwId m = MwId();
        m.SetName("nice_dd_Speaker_Icon.Item.Gbx");
        auto v = m.Value;
        int nb = map.AnchoredObjects.Length;
        if (nb == 0) return false;
        for (int i = nb - 1; i >= Math::Max(0, nb - 7777); i--) {
            @item = map.AnchoredObjects[i].ItemModel;
            if (item.Id.Value == v) {
                return true;
            }
        }
        return false;
    }

    string GetMapHash(CGameCtnChallenge@ map) {
        auto fid = GetFidFromNod(map);
        if (fid is null) return "";
        if (fid.FullFileName.Length <= 9) return fid.FullFileName;
        try {
            IO::File f(fid.FullFileName, IO::FileMode::Read);
            auto buf = f.Read(f.Size());
            buf.Seek(0);
            yield();
            string acc;
            while (!buf.AtEnd()) {
                // trace('b:' + buf.GetPosition());
                acc += Crypto::Sha256(buf.ReadToBase64(Math::Min(0x20000, buf.GetSize() - buf.GetPosition())));
                // trace('a1:' + buf.GetPosition());
                buf.Seek(Math::Min(0x20000, buf.GetSize() - buf.GetPosition()), 1);
                // trace('a2:' + buf.GetPosition());
                if (!buf.AtEnd()) {
                    yield();
                }
            }
            return Crypto::Sha256(acc);
        } catch {
            string info = getExceptionInfo();
            warn("Failed to read map file: " + info);
            return info.SubStr(0, 30);
        }
        return "";
    }
}
