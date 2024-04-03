[Setting hidden]
vec2 S_HudPos = vec2(64, 64);
[Setting hidden]
float S_HudHeight = 50;

namespace HUD {
    void Render(PlayerState@ player) {
        if (player is null) {
            return;
        }
        if (player.pos.y > 100000 || player.pos.y < -100000) {
            // we read some bad data
            return;
        }

        vec2 pos = S_HudPos * Minimap::vScale;
        float h = S_HudHeight * Minimap::vScale;

        nvg::Reset();
        nvg::BeginPath();
        nvg::TextAlign(nvg::Align::Left | nvg::Align::Top);
        nvg::FontSize(h);
        nvg::FontFace(f_Nvg_ExoMediumItalic);
        float yPos = player.pos.y;
        float heightPct = (yPos - Minimap::mapMinMax.x) / (Minimap::mapMinMax.y - Minimap::mapMinMax.x) * 100;
        DrawTextWithStroke(pos, Text::Format("Height: %04.0f m", Math::Round(yPos))
            + Text::Format(" (%.1f %%)", heightPct), cWhite, S_HudHeight * 0.08);
        nvg::ClosePath();
    }
}
