
[Setting hidden]
vec2 S_HudPos = vec2(64, 64);
// [Setting hidden]
// vec2 S_HudFallsPos = vec2(64, 128);
[Setting hidden]
vec2 S_HudFallingPos = vec2(-64, 64);

[Setting hidden]
float S_HudHeight = 50;

[Setting hidden]
bool S_HUDShowHeight = true;

[Setting hidden]
bool S_HUDShowFalls = true;
[Setting hidden]
bool S_HUDShowFloorsFallen = true;
[Setting hidden]
bool S_HUDShowMetersFallen = true;

[Setting hidden]
bool S_HUDShowPB = true;

[Setting hidden]
bool S_HUDShowCurrentFall = true;

[Setting hidden]
bool S_HUDJumpSpeed = true;


namespace HUD {
    string mainHudLabel;
    string fallsHudLabel;
    string fallingHudLabel;
    string pbHeightLabel;

    void DrawMenu() {
        if (UI::BeginMenu("HUD")) {
            S_HudHeight = UI::SliderFloat("Font Size", S_HudHeight, 10, 100);
            UI::Text("Left Side");
            S_HudPos = UI::SliderFloat2("Position##lhs", S_HudPos, 0, g_screen.y);
            S_HUDShowHeight = UI::Checkbox("Show Height", S_HUDShowHeight);
            S_HUDShowFalls = UI::Checkbox("Show Falls", S_HUDShowFalls);
            S_HUDShowFloorsFallen = UI::Checkbox("Show Floors Fallen", S_HUDShowFloorsFallen);
            S_HUDShowMetersFallen = UI::Checkbox("Show Meters Fallen", S_HUDShowMetersFallen);
            S_HUDShowPB = UI::Checkbox("Show PB", S_HUDShowPB);

            UI::Text("Right Side");
            S_HudFallingPos = UI::SliderFloat2("Position##rhs", S_HudFallingPos, -g_screen.x, g_screen.y);
            S_HUDShowCurrentFall = UI::Checkbox("Show Current Fall", S_HUDShowCurrentFall);
            S_HUDJumpSpeed = UI::Checkbox("Show Jump Speed", S_HUDJumpSpeed);

            UI::EndMenu();
        }
    }

    void Render(PlayerState@ player, bool doDraw) {
        if (player is null || !doDraw) {
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
        if (!S_HUDShowHeight) {
            fallsPos = pos;
        }

        vec2 pbHeightPos = fallsPos + lineHeightAdj;
        if (!S_HUDShowFalls || !player.isLocal) pbHeightPos = fallsPos;

        vec2 jumpSpeedPos = fallingPos + lineHeightAdj;
        if (!S_HUDShowCurrentFall) jumpSpeedPos = fallingPos;

        float carYPos = player.pos.y;
        float heightPct = (carYPos - Minimap::mapMinMax.x) / (Minimap::mapMinMax.y - Minimap::mapMinMax.x) * 100;
        if (S_HUDShowHeight) {
            mainHudLabel = Text::Format("Height: %4.0f m", Math::Round(carYPos))
                + Text::Format("  (%.1f %%)", heightPct)
                + Text::Format("  f-%02d", int(HeightToFloor(carYPos)));

            DrawHudLabel(h, pos, mainHudLabel, cWhite);
        }
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
            if (S_HUDShowCurrentFall) DrawHudLabel(h, fallingPos, fallingHudLabel, cWhite, nvg::Align::Right | nvg::Align::Top, cBlack85, alpha);
            if (S_HUDJumpSpeed) DrawHudLabel(h, jumpSpeedPos, Text::Format("%.1f km/h", fallTracker.startSpeed), cWhite, nvg::Align::Right | nvg::Align::Top, cBlack85, alpha);
        }
        if (player.isLocal) {
            fallsHudLabel = "Falls: " + (Stats::GetTotalFalls() + fallAdj);
            if (S_HUDShowFloorsFallen) fallsHudLabel += " / Floors: " + (Stats::GetTotalFloorsFallen() + currFallFloors);
            if (S_HUDShowMetersFallen) fallsHudLabel += Text::Format(" / %.1f m", Stats::GetTotalDistanceFallen() + distFallen);
#if DEV
            fallsHudLabel += Text::Format(" / abs m: %.1f", absDistFallen);
#endif
            if (S_HUDShowFalls) DrawHudLabel(h, fallsPos, fallsHudLabel, cWhite);
        }
        if (S_HUDShowPB) {
            float pbHeight = player.isLocal ? Stats::GetPBHeight() : Global::GetPlayersPBHeight(player);
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
