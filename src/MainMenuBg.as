
namespace MainMenuBg {
    const string SKIN_ML_PATH = "Skins\\Models\\CharacterPilot\\DeepDip2_MenuItem.zip";
    // const string SKIN2_ML_PATH = "Skins\\Models\\CharacterPilot\\DD2_SponsorsSign.zip";

    // will end up populating a script under GameData/Scripts/Libs/Dd2Menu/
    const string NEW_DD2_MENU_BG_LIB = "Scripts/Libs/Dd2Menu/HomeBackgroundPatched.Script.txt";

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

    CPlugFileTextScript@ GetPreloadedScriptFromTitles(const string &in path) {
        auto fid = Fids::GetFake(path);
        if (fid is null) return null;
        return cast<CPlugFileTextScript>(Fids::Preload(fid));
    }

    /// script_rel_filepath: should be like "Scripts/Libs/Dd2Menu/HomeBackgroundPatched.Script.txt"
    /// will get saved to Docs/Trackmania/Scripts.
    void SaveScriptTextTo(const string &in body, const string &in script_rel_filepath) {
        if (!script_rel_filepath.StartsWith("GameData/Scripts/")) throw("Must start with GameData/Scripts/. provided: " + script_rel_filepath);
        // if (!script_rel_filepath.StartsWith("Scripts/")) throw("Must start with Scripts/. provided: " + script_rel_filepath);
        if (!script_rel_filepath.EndsWith("Script.txt")) throw("Must end with Script.txt. provided: " + script_rel_filepath);
        auto dir = Path::GetDirectoryName(script_rel_filepath);
        auto abs_dir = IO::FromAppFolder(dir);
        dev_trace("Saving script text to dir: " + abs_dir);
        if (!IO::FolderExists(abs_dir)) IO::CreateFolder(abs_dir, true);
        auto abs_path = IO::FromAppFolder(script_rel_filepath);
        dev_trace("Saving script text to: " + abs_path);
        IO::File f(abs_path, IO::FileMode::Write);
        f.Write(body);
        f.Close();
        dev_trace("Saved script text (len="+body.Length+") to: " + abs_path);
    }

    bool ApplyPatchToHomeBackground() {
        CPlugFileTextScript@ nod = GetPreloadedScriptFromTitles("Titles\\Trackmania\\Scripts\\Libs\\Nadeo\\Trackmania\\Components\\HomeBackground@2.Script.txt");
        if (nod is null) {
            warn("failed to load menu bg library.");
            return false;
        }
        if (nod.Text.Contains("DD2ItemId")) {
            dev_trace("MainMenuBg: Patch already applied to HomeBackground script.");
            return false;
        }
        auto patch = GetMenuPatches(S_MenuBgTimeOfDay, S_MenuBgSeason);
        nod.Text = patch.Apply(nod.Text);
        nod.MwAddRef();
        // save the script file to a GameData location so the menu can load/compile it.
        SaveScriptTextTo(nod.Text, "GameData/" + NEW_DD2_MENU_BG_LIB);
        return true;
    }

    void UnapplyPatchToHomeBackground() {
        CPlugFileTextScript@ nod = GetPreloadedScriptFromTitles("Titles\\Trackmania\\Scripts\\Libs\\Nadeo\\Trackmania\\Components\\HomeBackground@2.Script.txt");
        if (nod is null) {
            warn("failed to load menu bg library for unpatching.");
            return;
        }
        if (!nod.Text.Contains("DD2ItemId")) {
            dev_trace("MainMenuBg: Patch not applied to HomeBackground script, nothing to unpatch.");
            return;
        }
        nod.ReGenerate();
        if (Reflection::GetRefCount(nod) > 0) {
            nod.MwRelease();
        } else {
            Dev_NotifyWarning("MainMenuBg: Patch not applied to HomeBackground script, but ref count == 0, so not releasing.");
        }
    }

    const string MENU_BG_IMPORT_TO_REPLACE = '#Include "Libs/Nadeo/Trackmania/Components/HomeBackground@2.Script.txt" as Trackmania_HomeBackground2';

    bool ApplyMenuBg() {
        if (!IsReady()) return false;
        ApplyPatchToHomeBackground();
        if (applied) return true;
        auto l = GetMenuSceneLayer(false);
        if (l is null) return false;
        if (l.ManialinkPageUtf8.Contains(MENU_BG_IMPORT_TO_REPLACE)) {
            // auto patch = GetMenuPatches(S_MenuBgTimeOfDay, S_MenuBgSeason);
            EngageIntercepts();
            auto new_import = '#Include "' + NEW_DD2_MENU_BG_LIB.SubStr(8) + '" as Trackmania_HomeBackground2';
            dev_trace("MainMenuBg: Applying import patch. From: " + MENU_BG_IMPORT_TO_REPLACE + " to: " + new_import);
            l.ManialinkPageUtf8 = origML.Replace(MENU_BG_IMPORT_TO_REPLACE, new_import);
        } else {
            gotOrigML = false;
        }
        applied = true;
        return true;
    }

    void Unapply() {
        UnapplyPatchToHomeBackground();
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
        mca.DataFileMgr.Media_RefreshFromDisk(CGameDataFileManagerScript::EMediaType::Script, 4);
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
            UI::TextWrapped("\\$i\\$888  Time of day and season has been deprecated. Tell XertroV if you want it back.");
            // S_MenuBgTimeOfDay = ComboTimeOfDay("Time of Day", S_MenuBgTimeOfDay);
            // S_MenuBgSeason = ComboSeason("Season", S_MenuBgSeason);
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

    // add new constants
    patches.AddPatch(AppendPatch("#Const C_Private_PilotEmoteCooldownDuration 10000", "\n#Const C_DD2Position <2.15, 0.85, 11.2>\n#Const C_DD2Rotation 10."));

    // extend K_Private_CameraScene with DD2ItemIds
    patches.AddPatch(AppendPatch("Ident PilotItemId;", "\n\tIdent[] DD2ItemIds;"));

    // deprecate time of day controls
    // if (setTimeOfDay >= 0) {
    //     patches.AddPatch(PrependPatch("HomeBackground_TimeOfDay::GetDayPart(HomeBackground_TimeOfDay::GetDayProgression(), False),", "" + setTimeOfDay + ", //"));
    // }
    // if (setSeason >= 0) {
    //     patches.AddPatch(PrependPatch("HomeBackground_Tools::GetTimestampSeason(HomeBackground_TiL::GetCurrent())", "" + setSeason + " //"));
    // }

    // Patches Private_CreateCameraScene_Podium
    patches.AddPatch(AppendPatch("""	Component.CameraScene.PodiumItemId = _Context.MenuSceneMgr.ItemCreate(
			Component.CameraScene.SceneId,
			C_Private_PodiumModelName,
			C_Private_PodiumSkinName,
			C_Private_PodiumSkinUrl
		);""", """
	Component.CameraScene.DD2ItemIds.add(_Context.MenuSceneMgr.ItemCreate(
		Component.CameraScene.SceneId,
		C_Private_PilotModelName,
		"Skins\\Models\\CharacterPilot\\DeepDip2_MenuItem.zip"
	));
	Component.CameraScene.DD2ItemIds.add(_Context.MenuSceneMgr.ItemCreate(
		Component.CameraScene.SceneId,
		C_Private_PilotModelName,
		"Skins\\Models\\CharacterPilot\\DD2_SponsorsSign.zip"
	));
	if (Component.CameraScene.DD2ItemIds[0] != NullId) {
		_Context.MenuSceneMgr.ItemSetLocation(
			Component.CameraScene.SceneId,
			Component.CameraScene.DD2ItemIds[0],
			C_DD2Position,
			C_DD2Rotation,
			False
		);
		_Context.MenuSceneMgr.ItemSetLocation(
			Component.CameraScene.SceneId,
			Component.CameraScene.DD2ItemIds[1],
			<-1.91, 0.240, -0.65>, // <+ right, + up, + back>
			155.,
			False
		);
	}"""));

    // Patches Private_DestroyCameraScene_Podium
    patches.AddPatch(AppendPatch("""	declare K_Private_Component Component = _Component;
	_Context.MenuSceneMgr.ItemDestroy(Component.CameraScene.SceneId, Component.CameraScene.PodiumItemId);
	Component.CameraScene.PodiumItemId = NullId;
	}""", """
	if (Component.CameraScene.DD2ItemIds.count > 0) {
		_Context.MenuSceneMgr.ItemDestroy(Component.CameraScene.SceneId, Component.CameraScene.DD2ItemIds[0]);
		_Context.MenuSceneMgr.ItemDestroy(Component.CameraScene.SceneId, Component.CameraScene.DD2ItemIds[1]);
		Component.CameraScene.DD2ItemIds.clear();
	}"""));
    return patches;
}
