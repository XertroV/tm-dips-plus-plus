
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
            case 0: return GetGameAddr("8B 15 ?? ?? ?? ?? 33 DB 4C 8B 6C 24 30 48 8B 74 24 40 85 D2 74 5E 0F 1F 44 00 00", 6);
            case 1: return GetGameAddr("8B 05 ?? ?? ?? ?? 8B FA 85 C0 74 1C 85 D2 75 18 45 33 C0 8D 57 01 48 8D 0D", 6);
            case 2: return GetGameAddr("83 3D ?? ?? ?? ?? 00 0F 84 08 01 00 00 45 85 C9 0F 84 FF 00 00 00", 7, 2);
            case 4: return GetGameAddr("44 39 05 ?? ?? ?? ?? 74 2A 49 8B 82 98 04 00 00 44 89 05 ?? ?? ?? ?? 48 8B", 7);
            case 5: return GetGameAddr("8B 05 ?? ?? ?? ?? 89 43 40 8B 05 ?? ?? ?? ?? 89 43 44 8B 86 80 00 00 00 89 43 74 8B", 6);
            case 6: return GetGameAddr("8B 0D ?? ?? ?? ?? 33 D2 8B 05 ?? ?? ?? ?? 44 8B C2 0F 10 05 ?? ?? ?? ?? 89 05", 6);
            case 8: return GetGameAddr("44 8B 0D ?? ?? ?? ?? F3 0F 5C CA F3 0F 58 E5 F3 0F 58 D0 F3 0F 11 5C 24 60", 7);
            case 9: return GetGameAddr("39 35 ?? ?? ?? ?? 8D 04 45 01 00 00 00 41 89 87 18 03 00 00 0F 85 33 01 00 00", 6);
            case 12: return GetGameAddr("83 3D ?? ?? ?? ?? 00 4C 8B AC 24 90 01 00 00 74 2B 83 3D ?? ?? ?? ?? 00 74 22", 7, 2);
            case 13: return GetGameAddr("83 3D ?? ?? ?? ?? 00 44 0F 28 84 24 80 01 00 00 0F 28 B4 24 A0 01 00 00 75 0A C7", 7, 2);
            case 14: return GetGameAddr("89 05 ?? ?? ?? ?? 48 8B 07 4C 89 68 10 48 8B 37 48 8B 4E 10 48 8D 56 10 41", 6);
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
            if (ptr % 4 != 0) continue;
            if (ptr < ba) continue;
            auto x = Math::Clamp(Dev::ReadInt32(ptr), 0, 1);
            if (x == 0) continue;
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

// namespace CL {
//     uint64 ptr1 = 0;
//     const string pat = "48 8B 05 ?? ?? ?? ?? 81 B8 84 00 00 00 A0 25 00 00";
//     uint64 GetPtr1() {
//         if (ptr1 == 0) {
//             ptr1 = SF::GetGameAddr(pat, 7);
//         }
//         return ptr1;
//     }
//     string GetInfo() {
//         auto ptr = GetPtr1();
//         if (ptr == 0) return "no_ptr1";
//         auto ptr2 = Dev::ReadUInt64(ptr) + 0x78;
//         if (ptr2 == 0 || ptr2 % 8 != 0 || ptr < 0xFFFFFFFF) return "no_ptr2";
//         auto c1 = Dev::ReadUInt32(ptr2 + 0x8);
//         auto c2 = Dev::ReadUInt32(ptr2 + 0xC);
//         if (c1 == 0 || c2 < 0x10) return "no_c1_c2";
//         auto ptr3 = Dev::ReadUInt64(ptr2);
//         if (ptr3 == 0 || ptr3 < 0xFFFFFFFF) return "no_ptr3";
//         auto res = Dev::ReadCString(ptr3);
//         auto ix = Math::Max(0, res.IndexOf("] Lo") - 5);
//         return res.SubStr(ix);
//     }
// }

namespace Map {
    Json::Value@ lastMapInfo = Json::Value();
    uint lastMapMwId;

    Json::Value@ GetMapInfo(bool relevant) {
        Json::Value@ j = Json::Object();

        auto map = GetApp().RootMap;
        if (map is null) {
            lastMapMwId = 0;
            @lastMapInfo = Json::Value();
            return lastMapInfo;
        }
        if (map.Id.Value == lastMapMwId) return lastMapInfo;

        try {
            lastMapMwId = map.Id.Value;
            string mnLower = string(map.MapName).ToLower();
            relevant = relevant || (mnLower.Contains("deep") || mnLower.Contains("dip") || mnLower.Contains("dd2"));
            if (relevant) {
                j["uid"] = map.EdChallengeId;
            } else {
                j["uid"] = Crypto::MD5(map.EdChallengeId).SubStr(0, 30);
            }
            j["name"] = relevant ? string(map.MapName) : "<!:;not relevant>";
            j["hash"] = GetMapHash(map);
        } catch {
            string info = getExceptionInfo();
            warn("Failed to get map info: " + info);
            j["uid"] = "exception";
            j["name"] = "exception";
            j["hash"] = "exception";
        }

        @lastMapInfo = j;

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
        CGameCtnAnchoredObject@ ao;
        for (int i = nb - 1; i >= Math::Max(0, nb - 7777); i--) {
            @ao = map.AnchoredObjects[i];
            if (ao is null) continue;
            @item = ao.ItemModel;
            if (item is null) continue;
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
            f.Close();
            buf.Seek(0);
            yield();
            string acc;
            while (!buf.AtEnd()) {
                // trace('b:' + buf.GetPosition());
                acc += Crypto::Sha256(buf.ReadToBase64(Math::Min(0x40000, buf.GetSize() - buf.GetPosition())));
                // trace('a1:' + buf.GetPosition());
                buf.Seek(Math::Min(0x40000, buf.GetSize() - buf.GetPosition()), 1);
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
