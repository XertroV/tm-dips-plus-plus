[Setting hidden]
vec2 S_HudPos = vec2(64, 64);
// [Setting hidden]
// vec2 S_HudFallsPos = vec2(64, 128);
[Setting hidden]
vec2 S_HudFallingPos = vec2(-64, 64);

[Setting hidden]
float S_HudHeight = 50;

namespace HUD {
    string mainHudLabel;
    string fallsHudLabel;
    string fallingHudLabel;

    void Render(PlayerState@ player) {
        if (player is null) {
            return;
        }
        if (player.pos.y > 3000 || player.pos.y < -1000) {
            // we read some bad data
            return;
        }

        vec2 pos = S_HudPos * Minimap::vScale;
        float h = S_HudHeight * Minimap::vScale;
        vec2 fallsPos = (S_HudPos + vec2(0, S_HudHeight * 1.18)) * Minimap::vScale;
        vec2 fallingPos = S_HudFallingPos * Minimap::vScale + vec2(g_screen.x, 0);

        float yPos = player.pos.y;
        float heightPct = (yPos - Minimap::mapMinMax.x) / (Minimap::mapMinMax.y - Minimap::mapMinMax.x) * 100;
        mainHudLabel = Text::Format("Height: %04.0f m", Math::Round(yPos)) + Text::Format(" (%.1f %%)", heightPct);
        DrawHudLabel(h, pos, mainHudLabel, cWhite);
        int currFallFloors = 0;
        bool fallTrackerActive = player.fallTracker !is null;
        auto fallTracker = fallTrackerActive ? player.fallTracker : player.lastFall;
        if (fallTracker !is null) {
            currFallFloors = fallTracker.FloorsFallen();
            auto fallDist = fallTracker.HeightFallen();
            fallingHudLabel = "Fell " + Text::Format("%.0f m / ", fallDist) + fallTracker.FloorsFallen() + " floors";
            float alpha = fallTrackerActive ? 1.0 : 0.5;
            DrawHudLabel(h, fallingPos, fallingHudLabel, cWhite, nvg::Align::Right | nvg::Align::Top, globalAlpha: alpha);
        }
        if (player.isLocal) {
            if (player.lastFall !is null) {
                currFallFloors += player.lastFall.FloorsFallen();
            }

            fallsHudLabel = "Falls: " + Stats::GetTotalFalls() + " / Floors: " + (Stats::GetTotalFloorsFallen() + currFallFloors);
            DrawHudLabel(h, fallsPos, fallsHudLabel, cWhite);
        }
    }

    void DrawHudLabel(float h, vec2 pos, const string &in msg, const vec4 &in col = cWhite, int textAlign = nvg::Align::Left | nvg::Align::Top, const vec4 &in strokeCol = cBlack85, float globalAlpha = 1.0) {
        nvg::Reset();
        nvg::BeginPath();
        nvg::TextAlign(textAlign);
        nvg::FontSize(h);
        nvg::FontFace(f_Nvg_ExoMediumItalic);
        nvg::GlobalAlpha(globalAlpha);
        DrawTextWithStroke(pos, msg, col, h * 0.08, strokeCol);
        nvg::GlobalAlpha(1.0);
        nvg::ClosePath();
    }

}
