/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
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
    string pbHeightLabel;

    void Render(PlayerState@ player) {
        if (player is null) {
            return;
        }
        if (player.pos.y > 3000 || player.pos.y < -1000) {
            // we read some bad data
            return;
        }

        vec2 pos = S_HudPos * Minimap::vScale;
        vec2 fallingPos = S_HudFallingPos * Minimap::vScale + vec2(g_screen.x, 0);
        if (IsTitleGagPlaying()) {
            auto anim = titleScreenAnimations[0];
            float minY = anim.pos.y + anim.size.y + 32. * Minimap::vScale;
            pos.y = Math::Max(pos.y, minY);
            fallingPos.y = Math::Max(fallingPos.y, minY);
        }
        float h = S_HudHeight * Minimap::vScale;
        vec2 lineHeightAdj = vec2(0, S_HudHeight * 1.18) * Minimap::vScale;

        vec2 fallsPos = pos + lineHeightAdj;
        vec2 pbHeightPos = fallsPos + lineHeightAdj;

        vec2 jumpSpeedPos = fallingPos + lineHeightAdj;

        float carYPos = player.pos.y;
        float heightPct = (carYPos - Minimap::mapMinMax.x) / (Minimap::mapMinMax.y - Minimap::mapMinMax.x) * 100;
        mainHudLabel = Text::Format("Height: %4.0f m", Math::Round(carYPos)) + Text::Format(" (%.1f %%)", heightPct);
        DrawHudLabel(h, pos, mainHudLabel, cWhite);
        int currFallFloors = 0;
        float distFallen = 0;
        float absDistFallen = 0;
        bool fallTrackerActive = player.fallTracker !is null;
        auto fallTracker = fallTrackerActive ? player.fallTracker : player.lastFall;
        int fallAdj = 0;
        if (fallTracker !is null) {
            fallAdj = fallTracker.IsFallPastMinFall() ? 0 : -1;
            currFallFloors = fallTracker.FloorsFallen();
            distFallen = fallTracker.HeightFallen();
            absDistFallen = fallTracker.HeightFallenFromFlying();
            fallingHudLabel = "Fell " + Text::Format("%.0f m / ", distFallen) + currFallFloors + (currFallFloors == 1 ? " floor" : " floors");
            float alpha = fallTrackerActive ? 1.0 : 0.5;
            DrawHudLabel(h, fallingPos, fallingHudLabel, cWhite, nvg::Align::Right | nvg::Align::Top, cBlack85, alpha);
            DrawHudLabel(h, jumpSpeedPos, Text::Format("%.1f km/h", fallTracker.startSpeed), cWhite, nvg::Align::Right | nvg::Align::Top, cBlack85, alpha);
        }
        if (player.isLocal) {
            fallsHudLabel = "Falls: " + (Stats::GetTotalFalls() + fallAdj) + " / Floors: " + (Stats::GetTotalFloorsFallen() + currFallFloors)
                + Text::Format(" / %.1f m", Stats::GetTotalDistanceFallen() + distFallen)
#if DEV
                + Text::Format(" / abs m: %.1f", absDistFallen);
#endif
                ;
            DrawHudLabel(h, fallsPos, fallsHudLabel, cWhite);

            float pbHeight = Stats::GetPBHeight();
            pbHeightLabel = Text::Format("PB: %4.0f m", pbHeight);
            bool isPBing = player.pos.y + 16. > pbHeight;

            DrawHudLabel(h, pbHeightPos, pbHeightLabel, isPBing ? cGoldLight : cWhite);
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
