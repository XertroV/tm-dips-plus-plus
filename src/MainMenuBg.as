
namespace MainMenuBg {
    const string SKIN_ML_PATH = "Skins\\Models\\CharacterPilot\\DeepDip2_MenuItem.zip";
    // const string SKIN2_ML_PATH = "Skins\\Models\\CharacterPilot\\DD2_SponsorsSign.zip";

    string origML;
    bool gotOrigML = false;

    void OnPluginLoad() {
// #if DEV && DEPENDENCY_MLHOOK
//         MLHook::RegisterPlaygroundMLExecutionPointCallback(MLHook::MLFeedFunction(OnPlaygroundMLExec));
// #endif
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

    bool _UpdateMenuPositions = false;
    void OnPlaygroundMLExec(ref@ _meh) {
        if (!_UpdateMenuPositions) return;
        _UpdateMenuPositions = false;
        UpdateMenuItemPosRot_All();
    }

    bool IsReady() {
        return origML.Length > 0
            && MenuItemExists();
    }

    bool _MenuItemExists = false;
    bool MenuItemExists() {
        if (_MenuItemExists) return true;
        _MenuItemExists = IO::FileExists(IO::FromUserGameFolder(MENU_ITEM_RELPATH))
            && IO::FileExists(IO::FromUserGameFolder(MENU_ITEM2_RELPATH));
        return _MenuItemExists;
    }

    bool ApplyMenuBg() {
        if (!IsReady()) return false;
        if (applied) return true;
        auto l = GetMenuSceneLayer(false);
        if (l is null) return false;
        if (!l.ManialinkPageUtf8.Contains("DD2ItemId")) {
            auto patch = GetMenuPatches(S_MenuBgTimeOfDay, S_MenuBgSeason);
            EngageIntercepts();
            l.ManialinkPageUtf8 = patch.Apply(origML);
        } else {
            gotOrigML = false;
        }
        applied = true;
        return true;
    }

    void Unapply() {
        if (hasIntProcs) {
            DisengageIntercepts();
        }
        if (!applied) return;
        if (!gotOrigML) return;
        auto l = GetMenuSceneLayer(false);
        if (l is null) return;
        l.ManialinkPageUtf8 = origML;
        applied = false;
    }

    CGameUILayer@ GetMenuSceneLayer(bool canYield = true) {
        auto app = cast<CTrackMania>(GetApp());
        while (app.MenuManager is null) {
            if (!canYield) return null;
            yield();
        }
        auto mm = app.MenuManager;
        while (mm.MenuCustom_CurrentManiaApp is null) {
            if (!canYield) return null;
            yield();
        }
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
    const uint nbItemMwIdsToCollect = 3 + 2;

    bool observeMwIds = false;
    MwId[] DD2MenuBgItemIds = {};
    vec3[] DD2MenuBgItemPos = {};
    float[] DD2MenuBgItemRot = {};
    MwId SceneId = MwId();
    CGameMenuSceneScriptManager@ MenuSceneMgr;

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
        @MenuSceneMgr = cast<CGameMenuSceneScriptManager>(nod);
        return true;
    }

    bool CGameMenuSceneScriptManager_ItemSetLocation(CMwStack &in stack) {
        if (!observeMwIds) return true;
        DD2MenuBgItemRot.InsertLast(stack.CurrentFloat(1));
        DD2MenuBgItemPos.InsertLast(stack.CurrentVec3(2));
        DD2MenuBgItemIds.InsertLast(stack.CurrentId(3));
        SceneId = stack.CurrentId(4);
        if (DD2MenuBgItemIds.Length >= nbItemMwIdsToCollect) {
            observeMwIds = false;
        }
        return true;
    }

    bool CGameMenuSceneScriptManager_SceneDestroy(CMwStack &in stack) {
        observeMwIds = false;
        @MenuSceneMgr = null;
        DD2MenuBgItemIds.RemoveRange(0, DD2MenuBgItemIds.Length);
        return true;
    }

    bool SetMenuItemPosRot(uint ix, const vec3 &in pos, float rot, bool onTurntable = false) {
        if (MenuSceneMgr is null) return false;
        MenuSceneMgr.ItemSetLocation(SceneId, DD2MenuBgItemIds[ix], pos, rot, onTurntable);
        // trace("SetMenuItemPosRot: S:"+SceneId.Value+" / I:" + DD2MenuBgItemIds[ix].Value + " /P:" + pos.ToString() + " /R:" + rot);
        // startnew(UpdateMenuItemPosRot_All).WithRunContext(Meta::RunContext::BeforeScripts);
        return true;
    }

    void UpdateMenuItemPosRot_All() {
        if (MenuSceneMgr is null) return;
        for (uint i = 0; i < DD2MenuBgItemIds.Length; i++) {
            MenuSceneMgr.ItemSetLocation(SceneId, DD2MenuBgItemIds[i], DD2MenuBgItemPos[i], DD2MenuBgItemRot[i], false);
            // trace("SetMenuItemPosRot: S:"+SceneId.Value+" / I:" + DD2MenuBgItemIds[i].Value + " /P:" + DD2MenuBgItemPos[i].ToString() + " /R:" + DD2MenuBgItemRot[i]);
        }
    }




    void DrawPromoMenuSettings() {
        if (UI::BeginMenu("Main Menu")) {
            S_EnableMainMenuPromoBg = UI::Checkbox("Enable Main Menu Thing", S_EnableMainMenuPromoBg);
            S_MenuBgTimeOfDay = ComboTimeOfDay("Time of Day", S_MenuBgTimeOfDay);
            S_MenuBgSeason = ComboSeason("Season", S_MenuBgSeason);
            if (UI::Button("Refresh Now")) {
                Unapply();
                ApplyMenuBg();
                // startnew(ApplyMenuBg);
            }
#if DEV
            DrawDevPositionMenuItem();
#endif
            UI::EndMenu();
        }
    }

    void ClearRefs() {
        @MenuSceneMgr = null;
        @update_menuBgLayer = null;
    }

    CGameUILayer@ update_menuBgLayer;
    void Update() {
        auto app = GetApp();
        if (int(app.LoadProgress.State) != 0) return;
        if (app.Viewport.Cameras.Length != 1) return;
        if (MenuSceneMgr is null) return;
        if (update_menuBgLayer is null) {
            @update_menuBgLayer = GetMenuSceneLayer(false);
        }
        if (update_menuBgLayer is null) return;
        if (!update_menuBgLayer.IsVisible) return;
        // trace('menu bg update start');
        auto mouseUv = UI::GetMousePos() / g_screen;
        if (mouseUv.x < 0.0) mouseUv.x = 0.5;
        auto rot = Math::Lerp(-20., 0., Math::Clamp(mouseUv.x, 0., 1.));
        MenuSceneMgr.ItemSetPivot(SceneId, DD2MenuBgItemIds[0], vec3(-2.0, 0.0, 0.0));
        SetMenuItemPosRot(0, DD2MenuBgItemPos[0] + vec3(-2.0, 0.0, 0.0), rot, false);
        // trace('menu bg update end');
    }


    int m_ModItemPosIx = 0;

    // does not work after item position set? not working from angelscript regardless of exec context
    void DrawDevPositionMenuItem() {
        if (DD2MenuBgItemIds.Length < 1) {
            UI::Text("No menu item(s) found");
            return;
        }
        UI::Text("Mouse: " + UI::GetMousePos().ToString());
        UI::Text("Mouse: " + (UI::GetMousePos() / g_screen).ToString());
        UI::Text("Nb Menu Items: " + DD2MenuBgItemIds.Length);
        m_ModItemPosIx = UI::SliderInt("Item Index", m_ModItemPosIx, 0, DD2MenuBgItemIds.Length - 1);
        auto origPos = DD2MenuBgItemPos[m_ModItemPosIx];
        auto origRot = DD2MenuBgItemRot[m_ModItemPosIx];
        DD2MenuBgItemPos[m_ModItemPosIx] = UI::SliderFloat3("Position##"+m_ModItemPosIx, DD2MenuBgItemPos[m_ModItemPosIx], -20., 20.);
        DD2MenuBgItemRot[m_ModItemPosIx] = UI::SliderFloat("Rotation##"+m_ModItemPosIx, DD2MenuBgItemRot[m_ModItemPosIx], -720., 720.);

        bool changed = origRot != DD2MenuBgItemRot[m_ModItemPosIx] || !Vec3Eq(origPos, DD2MenuBgItemPos[m_ModItemPosIx]);
        if (changed) {
            _UpdateMenuPositions = true;
            SetMenuItemPosRot(m_ModItemPosIx, DD2MenuBgItemPos[m_ModItemPosIx], DD2MenuBgItemRot[m_ModItemPosIx]);
        }

        if (UI::Button("Update")) {
            _UpdateMenuPositions = true;
            SetMenuItemPosRot(m_ModItemPosIx, DD2MenuBgItemPos[m_ModItemPosIx], DD2MenuBgItemRot[m_ModItemPosIx]);
        }
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
    patches.AddPatch(AppendPatch("Ident PodiumItemId;", "\n\tIdent[] DD2ItemIds;"));
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
	HomeBackground.CameraScene.DD2ItemIds.add(MenuSceneMgr.ItemCreate(
		HomeBackground.CameraScene.SceneId,
		HomeBackground_C_PilotModel,
		"Skins\\Models\\CharacterPilot\\DeepDip2_MenuItem.zip"
	));
	HomeBackground.CameraScene.DD2ItemIds.add(MenuSceneMgr.ItemCreate(
		HomeBackground.CameraScene.SceneId,
		HomeBackground_C_PilotModel,
		"Skins\\Models\\CharacterPilot\\DD2_SponsorsSign.zip"
	));
	if (HomeBackground.CameraScene.DD2ItemIds[0] != NullId) {
		MenuSceneMgr.ItemSetLocation(
			HomeBackground.CameraScene.SceneId,
			HomeBackground.CameraScene.DD2ItemIds[0],
			HomeBackground_C_DD2Position,
			HomeBackground_C_DD2Rotation,
			False
		);
		MenuSceneMgr.ItemSetLocation(
			HomeBackground.CameraScene.SceneId,
			HomeBackground.CameraScene.DD2ItemIds[1],
			<-1.1, .25, -1.6>,
			170.,
			False
		);
	}"""));
    patches.AddPatch(AppendPatch("""	if (HomeBackground.CameraScene.PodiumItemId != NullId) {
		MenuSceneMgr.ItemDestroy(HomeBackground.CameraScene.SceneId, HomeBackground.CameraScene.PodiumItemId);
		HomeBackground.CameraScene.PodiumItemId = NullId;
	}""", """
	if (HomeBackground.CameraScene.DD2ItemIds.count > 0) {
		MenuSceneMgr.ItemDestroy(HomeBackground.CameraScene.SceneId, HomeBackground.CameraScene.DD2ItemIds[0]);
		MenuSceneMgr.ItemDestroy(HomeBackground.CameraScene.SceneId, HomeBackground.CameraScene.DD2ItemIds[1]);
		HomeBackground.CameraScene.DD2ItemIds.clear();
	}"""));
    patches.AddPatch(AppendPatch("""		if (HomeBackground.CameraScene.PodiumItemId != NullId) {
			MenuSceneMgr.ItemDestroy(HomeBackground.CameraScene.SceneId, HomeBackground.CameraScene.PodiumItemId);
			HomeBackground.CameraScene.PodiumItemId = NullId;
		}""", """
		if (HomeBackground.CameraScene.DD2ItemIds.count > 0) {
			MenuSceneMgr.ItemDestroy(HomeBackground.CameraScene.SceneId, HomeBackground.CameraScene.DD2ItemIds[0]);
			MenuSceneMgr.ItemDestroy(HomeBackground.CameraScene.SceneId, HomeBackground.CameraScene.DD2ItemIds[1]);
			HomeBackground.CameraScene.DD2ItemIds.clear();
		}"""));
    return patches;
}
