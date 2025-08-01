
const string PLUGIN_NAME = Meta::ExecutingPlugin().Name;
string MENU_LABEL = "                                ##"+PLUGIN_NAME; //

void DrawPluginMenuItem(bool short = false) {
    // if (dips_pp_logo_horiz_vsm !is null) {
    //     UI::SetNextItemWidth(dips_pp_logo_horiz_vsm_dims.x);
    // }
    if (UI::BeginMenu(!G_Initialized ? "Dips++" : MENU_LABEL, true)) {
        // DrawPluginMenuLabel();
        UI::Separator();
        DrawPluginMenuInner();
        UI::Separator();
        UI::EndMenu();
    }
    if (G_Initialized) DrawPluginMenuLabel();
}

void DrawPluginMenuLabel() {
    if (dips_pp_logo_horiz_vsm is null && dips_pp_logo_horiz_vsm_dims.LengthSquared() < 1.) return;
    MenuLogo::UpdateRenderVarsForMenu(UI::GetItemRect());
    MenuLogo::DrawImage(UI::GetWindowDrawList());
}

bool menuBarStartedDrawingExtra = false;
bool menuBarHideUnlessSDE = false;
bool get__Menu_DrawNextMenu() {
    return !menuBarHideUnlessSDE || menuBarStartedDrawingExtra;
}
void DrawPluginMenuInner(bool isMenuBar = false) {
    if (!isMenuBar) {
        g_MainUiVisible = UI::Checkbox("Main UI", g_MainUiVisible);
    }
    menuBarStartedDrawingExtra = false;
    menuBarHideUnlessSDE = false;
    float maxW = UI::GetWindowContentRegionWidth();
    // EasyMap::DrawMenu();
    // if (isMenuBar && UI::GetCursorPos().x > (maxW - 120.)) StartDrawExtra();
    if (_Menu_DrawNextMenu) Visibility::DrawMenu();
    if (isMenuBar && UI::GetCursorPos().x > (maxW - 120.)) StartDrawExtra();
    if (_Menu_DrawNextMenu) Volume::DrawMenu();
    if (isMenuBar && UI::GetCursorPos().x > (maxW - 120.)) StartDrawExtra();
    if (_Menu_DrawNextMenu) HUD::DrawMenu();
    if (isMenuBar && UI::GetCursorPos().x > (maxW - 120.)) StartDrawExtra();
    if (_Menu_DrawNextMenu) Minimap::DrawMenu();
    if (isMenuBar && UI::GetCursorPos().x > (maxW - 120.)) StartDrawExtra();
    if (_Menu_DrawNextMenu) Gameplay::DrawMenu();
    if (isMenuBar && UI::GetCursorPos().x > (maxW - 120.)) StartDrawExtra();
    if (_Menu_DrawNextMenu) Alerts::DrawMenu();
    if (isMenuBar && UI::GetCursorPos().x > (maxW - 120.)) StartDrawExtra();
    if (_Menu_DrawNextMenu) GreenTimer::DrawSettings();
    if (isMenuBar && UI::GetCursorPos().x > (maxW - 120.)) StartDrawExtra();
    if (_Menu_DrawNextMenu) Signs3d::DrawMenu();
    if (isMenuBar && UI::GetCursorPos().x > (maxW - 120.)) StartDrawExtra();
    if (_Menu_DrawNextMenu) LoadingScreens::DrawMenu();
    if (isMenuBar && UI::GetCursorPos().x > (maxW - 120.)) StartDrawExtra();
    if (_Menu_DrawNextMenu) MainMenuBg::DrawPromoMenuSettings();
    if (isMenuBar && UI::GetCursorPos().x > (maxW - 120.)) StartDrawExtra();
    if (_Menu_DrawNextMenu) DebugMenu::DrawMenu();
    if (menuBarStartedDrawingExtra) {
        UI::EndMenu();
    }
}

void StartDrawExtra() {
    if (menuBarStartedDrawingExtra) return;
    menuBarHideUnlessSDE = true;
    menuBarStartedDrawingExtra = UI::BeginMenu("More...");
}

namespace MenuLogo {
    vec2 mainSize;
    vec2 mainTL;
    vec2 drawScale;

    void UpdateRenderVarsForMenu(vec4 rect) {
        auto sq = vec2(rect.w, rect.w);
        mainSize = sq * .76;
        mainSize.x = mainSize.y * dips_pp_logo_horiz_vsm_dims.x / dips_pp_logo_horiz_vsm_dims.y;
        mainTL = vec2(rect.x, rect.y) + sq * vec2(.25, .10);
        drawScale = mainSize / dips_pp_logo_horiz_vsm_dims;
    }

    void DrawImage(UI::DrawList@ dl) {
        if (!G_Initialized) return;
        dl.AddImage(dips_pp_logo_horiz_vsm, mainTL, mainSize, 0xFFFFFFFF, 0.0);
    }
}





namespace Visibility {
    void DrawMenu() {
        if (UI::BeginMenu("Visibility")) {
            S_ShowWhenUIHidden = UI::Checkbox("Show when UI hidden?", S_ShowWhenUIHidden);
            S_HideMovieTitles = UI::Checkbox("Hide & silence fake movie titles?", S_HideMovieTitles);
            UI::Indent();
            S_JustSilenceMovieTitles = UI::Checkbox("Just silence fake movie titles?", S_JustSilenceMovieTitles);
            UI::Unindent();
            S_VoiceLinesInSpec = UI::Checkbox("Play Voice Lines when Spectating", S_VoiceLinesInSpec);
            S_HideDPPButtonInBottomRight = UI::Checkbox("Hide Dips++ button in bottom right?", S_HideDPPButtonInBottomRight);
            S_NbTopTimes = Math::Clamp(UI::InputInt("Number of Top Times to show (1-10)", S_NbTopTimes, 1), 1, 10);
            UI::EndMenu();
        }
    }
}



bool g_DebugDrawCustomMapTriggers = false;


namespace DebugMenu {
    void DrawMenu() {
        if (UI::BeginMenu("DebugInfo")) {
            if (UI::BeginMenu("Network")) {
                DrawAPIPacketsTab();
                UI::EndMenu();
            }
            if (UI::BeginMenu("PBs / LBs")) {
                DrawPBSendStats();
                UI::EndMenu();
            }
            if (UI::BeginMenu("Features")) {
                bool isEnabled = IsMLHookEnabled();
                UI::Text("Magic Spectate: " + (MAGIC_SPEC_ENABLED ? (isEnabled ? cCheckMark : cWarningMark) : cCrossMark));
                if (!isEnabled) {
                    AddSimpleTooltip("MLHook is disabled!");
                }
                UI::EndMenu();
            }

            if (g_CustomMap !is null && g_CustomMap.auxSpec !is null) {
                if (UI::BeginMenu("Custom Map")) {
                    if (UI::MenuItem("Debug: Show Triggers", "No Cheating!", g_DebugDrawCustomMapTriggers)) {
                        g_DebugDrawCustomMapTriggers = !g_DebugDrawCustomMapTriggers;
                    }

                    if (UI::MenuItem("Copy Map Aux Spec", "VLs JSON")) {
                        IO::SetClipboard(Json::Write(g_CustomMap.auxSpec));
                        NotifySuccess("Copied map aux spec to clipboard");
                    }
                    UI::EndMenu();
                }
            }

#if DEV
            if (UI::MenuItem("Wizard", "", g_WizardOpen)) {
                g_WizardOpen = !g_WizardOpen;
            }

            // problematic outside of DEV
            if (UI::MenuItem("Disable In Editor", "", S_DisableUiInEditor)) {
                S_DisableUiInEditor = !S_DisableUiInEditor;
            }
            AddSimpleTooltip("This will reset while outside the editor.\n \\$i Allows you to test voice lines for custom maps after finalization.");

            // if (UI::Button("Set current map uid to ez map testing")) {
            //     auto map = GetApp().RootMap;
            //     if (map !is null) DD2_EASY_MAP_UID2 = map.EdChallengeId;
            //     MatchDD2::lastMapMwId = 0;
            // }
            if (UI::MenuItem("Play Finish")) {
                OnFinish::isFinishSeqRunning = false;
                OnLocalPlayerFinished(null);
            }
            if (UI::MenuItem("Play Fanfare")) {
                Fanfare::OnFinishHit();
            }
            if (UI::MenuItem("Test Cam Control 15s")) {
                startnew(CameraUpdateHook::Run15Test);
            }
            if (UI::MenuItem("Explore Campaign Nod")) {
                auto fid = GetCampaignScriptFid(PatchModeTarget::Campaign);
                if (fid !is null) ExploreNod("Campaign Script Fid", fid);
                else NotifyError("No campaign script fid found");
            }
            if (UI::MenuItem("Explore PlayMap Nod")) {
                auto fid = GetCampaignScriptFid(PatchModeTarget::PlayMap);
                if (fid !is null) ExploreNod("Challenge Script Fid", fid);
                else NotifyError("No challenge script fid found");
            }
            if (UI::BeginMenu("Anims")) {
                if (UI::MenuItem("Add Bleb")) {
                    EmitStatusAnimation(RainbowStaticStatusMsg("Bleb").WithDuration(4000));
                }
                if (UI::MenuItem("Add 360")) {
                    EmitStatusAnimation(RainbowStaticStatusMsg("360!").WithDuration(3000));
                }
                UI::EndMenu();
            }
            if (UI::MenuItem("Show Debug", "", g_DebugOpen)) {
                g_DebugOpen = !g_DebugOpen;
            }
            Tasks::DrawDebugMenuItem();
#endif
            UI::EndMenu();
        }
    }

    void DrawPBSendStats() {
        UI::Text("lastCallToPBHWaitLoop: " + PBUpdate::lastCallToPBHWaitLoop);
        UI::Text("lastPBHUpdate: " + PBUpdate::lastPBHUpdate);
        UI::Text("isWaitingToUpdatePBH: " + PBUpdate::isWaitingToUpdatePBH);
        UI::Text("Count_PushPBHeightUpdateToServer: " + Count_PushPBHeightUpdateToServer);
        UI::Text("Count_PushPBHeightUpdateToServerQueued: " + Count_PushPBHeightUpdateToServerQueued);
    }
}


const string cCheckMark = "\\$<\\$2f2" + Icons::Check + "\\$>";
const string cWarningMark = "\\$<\\$fa2" + Icons::ExclamationTriangle + "\\$>";
const string cCrossMark = "\\$<\\$f22" + Icons::Times + "\\$>";


namespace Gameplay {
    void DrawMenu() {
        if (UI::BeginMenu("Gameplay")) {
            S_BlockCam7Drivable = UI::Checkbox("Block camera 7 drivable?", S_BlockCam7Drivable);
            MagicSpectate::DrawMenu();
            UI::EndMenu();
        }
    }
}


namespace Alerts {
    void DrawMenu() {
        // disable now that dd2 done
        // if (UI::BeginMenu("Alerts")) {
        //     S_NotifyOnNewWR = UI::Checkbox("Notification on new WR?", S_NotifyOnNewWR);
        //     UI::EndMenu();
        // }
    }
}
