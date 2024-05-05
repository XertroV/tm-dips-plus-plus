/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
namespace DipsPPSettings {
    vec2 texDims = vec2(0);
    vec2 brCoord = vec2(-40, -20);
    vec2 br;
    vec2 tl;
    vec2 size;

    float hoverProg = 0.0;
    bool hovering = false;
    float hovRound = 5.0;
    uint lastDraw = 0;

    void RenderButton() {
        if (dips_pp_logo_sm is null) return;
        lastDraw = Time::Now;
        size = texDims * Minimap::vScale * .6;
        br = brCoord * Minimap::vScale + g_screen;
        tl = br - vec2(Math::Round(size.x), Math::Round(size.y));
        hovering = IsWithin(g_MousePos, tl, size) && !IsImguiHovered();
        if (hovering) {
            hovRound = 20.0 * Minimap::vScale;
            UI::SetMouseCursor(UI::MouseCursor::Hand);
            hoverProg = Math::Min(hoverProg + g_DT / 150., 1.0);
        } else {
            hoverProg = Math::Max(hoverProg - g_DT / 150., 0.0);
        }

        nvg::Reset();
        nvg::BeginPath();
        if (hoverProg > 0.0) {
            nvg::FillColor(vec4(0, 0, 0, 0.5 * hoverProg));
            nvg::RoundedRect(tl - hovRound / 2., size + hovRound, hovRound);
            nvg::Fill();
            nvg::BeginPath();
        }
        nvg::Rect(tl, size);
        nvg::FillPaint(nvg::TexturePattern(tl, size, 0., dips_pp_logo_sm, 1.0));
        nvg::Fill();
        nvg::ClosePath();
    }

    bool TestClick() {
        if (!g_Active) return false;
        if (hoverProg <= 0.) return false;
        if (Time::Now > lastDraw + 1000) return false;
        if (tl.LengthSquared() < 1 || size.LengthSquared() < 10) return false;
        if (IsWithin(g_MousePos, tl, size)) {
            OnClickSettingsButton();
            return true;
        }
        return false;
    }

    void OnClickSettingsButton() {
        g_MainUiVisible = true;
        UI::ShowOverlay();
    }
}



bool IsWithin(vec2 pos, vec2 tl, vec2 size) {
    return pos.x >= tl.x && pos.x <= tl.x + size.x && pos.y >= tl.y && pos.y <= tl.y + size.y;
}
