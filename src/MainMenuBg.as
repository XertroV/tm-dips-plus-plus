/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
namespace MainMenuBg {
    const string SKIN_ML_PATH = "Skins\\Models\\CharacterPilot\\DeepDip2_MenuItem.zip";

    string origML;
    bool gotOrigML = false;

    void OnPluginLoad() {
        CGameUILayer@ l;
        while ((@l = GetMenuSceneLayer()) is null) {
            sleep(200);
        }
        origML = l.ManialinkPageUtf8;
        gotOrigML = true;
        while (!S_EnableMainMenuPromoBg) sleep(100);
        while (!IsReady()) sleep(100);
        while (GetMenuSceneLayer() is null) sleep(100);
        ApplyMenuBg();
    }

    bool IsReady() {
        return origML.Length > 0
            && MenuItemExists();
    }

    bool _MenuItemExists = false;
    bool MenuItemExists() {
        if (_MenuItemExists) return true;
        _MenuItemExists = IO::FileExists(IO::FromUserGameFolder(MENU_ITEM_RELPATH));
        return _MenuItemExists;
    }

    bool ApplyMenuBg() {
        if (!IsReady()) return false;
        auto l = GetMenuSceneLayer();
        if (l is null) return false;
        auto patch = GetMenuPatches(S_MenuBgTimeOfDay, S_MenuBgSeason);
        EngageIntercepts();
        l.ManialinkPageUtf8 = patch.Apply(origML);
        applied = true;
        return true;
    }

    void Unapply() {
        if (hasIntProcs) {
            DisengageIntercepts();
        }
        if (!applied) return;
        if (!gotOrigML) return;
        auto l = GetMenuSceneLayer();
        if (l is null) return;
        l.ManialinkPageUtf8 = origML;
        applied = false;
    }

    CGameUILayer@ GetMenuSceneLayer() {
        auto app = cast<CTrackMania>(GetApp());
        while (app.MenuManager is null) yield();
        auto mm = app.MenuManager;
        while (mm.MenuCustom_CurrentManiaApp is null) yield();
        auto mca = mm.MenuCustom_CurrentManiaApp;
        mca.DataFileMgr.Media_RefreshFromDisk(CGameDataFileManagerScript::EMediaType::Skins, 4);
        while (mca.UILayers.Length < 30) yield();
        for (uint i = 0; i < mca.UILayers.Length; i++) {
            auto l = mca.UILayers[i];
            if (l is null) continue;
            if (IsLayerMainMenuBg(l)) {
                return l;
            }
            // if (l.ManialinkPageUtf8.Length < 55) continue;
            // if (!l.ManialinkPageUtf8.SubStr(0, 60).Trim().StartsWith("<manialink name=\"Overlay_MenuBackground\" version=\"3\">")) {
            //     continue;
            // }
            // return l;
        }
        return null;
    }

    bool IsLayerMainMenuBg(CGameUILayer@ l) {
        if (l.LocalPage is null) return false;
        if (l.LocalPage.MainFrame is null) return false;
        if (l.LocalPage.MainFrame.Controls.Length < 1) return false;
        auto c = cast<CGameManialinkFrame>(l.LocalPage.MainFrame.Controls[0]);
        if (c is null) return false;
        if (c.Controls.Length < 1) return false;
        @c = cast<CGameManialinkFrame>(c.Controls[0]);
        if (c is null) return false;
        return c.ControlId == "frame-home-background";
    }

    bool applied = false;

    void Unload() {
        if (hasIntProcs) {
            DisengageIntercepts();
        }
        if (!gotOrigML) return;
        if (!applied) return;
        Unapply();
    }

    // can be increased for more items
    const uint nbItemMwIdsToCollect = 1;

    bool observeMwIds = true;
    MwId[] DD2MenuBgItemIds = {};
    MwId SceneId = MwId();
    // CGameMenuSceneScriptManager@ msm;

    bool hasIntProcs = false;
    void EngageIntercepts() {
        hasIntProcs = true;
        Dev::InterceptProc("CGameMenuSceneScriptManager", "ItemCreate0", CGameMenuSceneScriptManager_ItemCreate0);
        Dev::InterceptProc("CGameMenuSceneScriptManager", "ItemSetLocation", CGameMenuSceneScriptManager_ItemSetLocation);
        Dev::InterceptProc("CGameMenuSceneScriptManager", "SceneDestroy", CGameMenuSceneScriptManager_SceneDestroy);
    }

    void DisengageIntercepts() {
        hasIntProcs = false;
        Dev::ResetInterceptProc("CGameMenuSceneScriptManager", "ItemCreate0", CGameMenuSceneScriptManager_ItemCreate0);
        Dev::ResetInterceptProc("CGameMenuSceneScriptManager", "ItemSetLocation", CGameMenuSceneScriptManager_ItemSetLocation);
        Dev::ResetInterceptProc("CGameMenuSceneScriptManager", "SceneDestroy", CGameMenuSceneScriptManager_SceneDestroy);
    }

    bool CGameMenuSceneScriptManager_ItemCreate0(CMwStack &in stack, CMwNod@ nod) {
        if (observeMwIds) return true;
        string modelName = stack.CurrentWString(1);
        if (modelName != "CharacterPilot") return true;
        string skinNameOrUrl = stack.CurrentWString(0);
        if (skinNameOrUrl != SKIN_ML_PATH) return true;
        observeMwIds = true;
        SceneId = stack.CurrentId(2);
        // @msm = cast<CGameMenuSceneScriptManager>(nod);
        return true;
    }

    bool CGameMenuSceneScriptManager_ItemSetLocation(CMwStack &in stack) {
        if (!observeMwIds) return true;
        DD2MenuBgItemIds.InsertLast(stack.CurrentId(3));
        SceneId = stack.CurrentId(4);
        if (DD2MenuBgItemIds.Length >= nbItemMwIdsToCollect) {
            observeMwIds = false;
        }
        return true;
    }

    bool CGameMenuSceneScriptManager_SceneDestroy(CMwStack &in stack) {
        observeMwIds = false;
        DD2MenuBgItemIds.RemoveRange(0, DD2MenuBgItemIds.Length);
        return true;
    }

    bool SetMenuItemPosRot(uint ix, const vec3 &in pos, float rot, bool onTurntable = false) {
        CGameMenuSceneScriptManager@ msm;
        try {
            @msm = cast<CGameManiaPlanet>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp.MenuSceneManager;
        } catch {
            return false;
        }
        if (msm is null) return false;
        msm.ItemSetLocation(SceneId, DD2MenuBgItemIds[ix], pos, rot, onTurntable);
        return true;
    }
}


class APatch {
    string find;
    string replace;

    APatch(const string &in find, const string &in replace) {
        this.find = find;
        this.replace = replace;
    }

    string Apply(const string &in src) {
        return src.Replace(find, replace);
    }
}

class AppendPatch : APatch {
    AppendPatch(const string &in find, const string &in append) {
        super(find, find + append);
    }
}

class PrependPatch : APatch {
    PrependPatch(const string &in find, const string &in prepend) {
        super(find, prepend + find);
    }
}

class APatchSet {
    array<APatch@> patches;

    void AddPatch(const string &in find, const string &in replace) {
        patches.InsertLast(APatch(find, replace));
    }

    void AddPatch(APatch@ patch) {
        patches.InsertLast(patch);
    }

    string Apply(const string &in src) {
        string result = src;
        for (uint i = 0; i < patches.Length; i++) {
            result = patches[i].Apply(result);
        }
        return result;
    }
}

enum TimeOfDay {
    DoNotOverride = -1,
    Morning = 1,
    Day = 3,
    Evening = 5,
    Night = 7
}

enum Season {
    DoNotOverride = -1,
    Spring = 0,
    Summer = 1,
    Autumn = 2,
    Winter = 3
}


APatchSet@ GetMenuPatches(int setTimeOfDay = -1, int setSeason = -1) {
    APatchSet@ patches = APatchSet();
    patches.AddPatch(AppendPatch("Ident PodiumItemId;", "\n\tIdent DD2ItemId;"));
    patches.AddPatch(AppendPatch("#Const HomeBackground_C_PilotInCar False", "\n#Const HomeBackground_C_DD2Position <2.65, 1.05, 10.0>\n#Const HomeBackground_C_DD2Rotation 10."));
    if (setTimeOfDay >= 0) {
        patches.AddPatch(PrependPatch("HomeBackground_TimeOfDay::GetDayPart(HomeBackground_TimeOfDay::GetDayProgression(), False),", "" + setTimeOfDay + ", //"));
    }
    if (setSeason >= 0) {
        patches.AddPatch(PrependPatch("HomeBackground_Tools::GetTimestampSeason(HomeBackground_TiL::GetCurrent())", "" + setSeason + " //"));
    }
    patches.AddPatch(AppendPatch("""	HomeBackground.CameraScene.PodiumItemId = MenuSceneMgr.ItemCreate(
		HomeBackground.CameraScene.SceneId,
		HomeBackground_C_PodiumModel,
		"",
		""
	);""", """
	HomeBackground.CameraScene.DD2ItemId = MenuSceneMgr.ItemCreate(
		HomeBackground.CameraScene.SceneId,
		HomeBackground_C_PilotModel,
		"Skins\\Models\\CharacterPilot\\DeepDip2_MenuItem.zip"
	);
	if (HomeBackground.CameraScene.DD2ItemId != NullId) {
		MenuSceneMgr.ItemSetLocation(
			HomeBackground.CameraScene.SceneId,
			HomeBackground.CameraScene.DD2ItemId,
			HomeBackground_C_DD2Position,
			HomeBackground_C_DD2Rotation,
			False
		);
	}"""));
    patches.AddPatch(AppendPatch("""	if (HomeBackground.CameraScene.PodiumItemId != NullId) {
		MenuSceneMgr.ItemDestroy(HomeBackground.CameraScene.SceneId, HomeBackground.CameraScene.PodiumItemId);
		HomeBackground.CameraScene.PodiumItemId = NullId;
	}""", """
	if (HomeBackground.CameraScene.DD2ItemId != NullId) {
		MenuSceneMgr.ItemDestroy(HomeBackground.CameraScene.SceneId, HomeBackground.CameraScene.DD2ItemId);
		HomeBackground.CameraScene.DD2ItemId = NullId;
	}"""));
    patches.AddPatch(AppendPatch("""		if (HomeBackground.CameraScene.PodiumItemId != NullId) {
			MenuSceneMgr.ItemDestroy(HomeBackground.CameraScene.SceneId, HomeBackground.CameraScene.PodiumItemId);
			HomeBackground.CameraScene.PodiumItemId = NullId;
		}""", """
		if (HomeBackground.CameraScene.DD2ItemId != NullId) {
			MenuSceneMgr.ItemDestroy(HomeBackground.CameraScene.SceneId, HomeBackground.CameraScene.DD2ItemId);
			HomeBackground.CameraScene.DD2ItemId = NullId;
		}"""));
    return patches;
}
