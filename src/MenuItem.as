/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
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

void DrawPluginMenuInner(bool isMenuBar = false) {
    if (!isMenuBar) {
        g_MainUiVisible = UI::Checkbox("Main UI", g_MainUiVisible);
    }
    Visibility::DrawMenu();
    Volume::DrawMenu();
    HUD::DrawMenu();
    Minimap::DrawMenu();
    GreenTimer::DrawSettings();
    Signs3d::DrawMenu();
    DrawLoadingScreenMenu();
    MainMenuBg::DrawPromoMenuSettings();
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
            UI::EndMenu();
        }
    }
}
