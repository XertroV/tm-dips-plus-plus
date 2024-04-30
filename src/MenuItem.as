const string PLUGIN_NAME = Meta::ExecutingPlugin().Name;
string MENU_LABEL = "                                ##"+PLUGIN_NAME; //

void DrawPluginMenuItem(bool short = false) {
    // if (dips_pp_logo_horiz_vsm !is null) {
    //     UI::SetNextItemWidth(dips_pp_logo_horiz_vsm_dims.x);
    // }
    if (UI::BeginMenu(MENU_LABEL, true)) {
        // DrawPluginMenuLabel();
        UI::Separator();
        DrawPluginMenuInner();
        UI::Separator();
        UI::EndMenu();
    }
    DrawPluginMenuLabel();
}

void DrawPluginMenuLabel() {
    if (dips_pp_logo_horiz_vsm is null) return;
    MenuLogo::UpdateRenderVarsForMenu(UI::GetItemRect());
    MenuLogo::DrawImage(UI::GetWindowDrawList());
}

void DrawPluginMenuInner() {
    UI::Text("Menu!");
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
        dl.AddImage(dips_pp_logo_horiz_vsm, mainTL, mainSize, 0xFFFFFFFF, 0.0);
    }
}
