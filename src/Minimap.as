/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
const uint AFTER_FALL_MINIMAP_SHOW_DURATION = 10000;
const uint AFTER_FALL_STABLE_AFTER = 4000;

/// A vertical minimap for showing falls in real time
/// ~~Rotates in 3d depending on camera orientation~~

[Setting hidden]
float S_MinimapLeftPad = 50.0;
[Setting hidden]
float S_MinimapTopBottomPad = 150.0;
[Setting hidden]
float S_MinimapMaxFallingGlobalExtraScale = 1.3;
[Setting hidden]
bool S_ScaleMinimapToPlayers = false;

namespace Minimap {
    vec3 camPos;
    mat4 camProjMat;
    vec2 minimapCenterPos;
    float minimapPad;
    vec2 minimapOuterPos;
    vec2 minimapSize = vec2(12, 900);
    vec2 minimapOuterSize = vec2(16, 900);
    float minimapYOffset = 0.;
    // vec2 worldMin = vec2(0, -64);
    // vec2 worldMax = vec2(1650, 2000);
    // mat3 worldXYToUv;
    // mat3 worldXYToScreen;
    float vScale;
    float widthScaleForRelative;
    uint lastMapMwId;
    vec2 lastScreenSize;
    vec2 mapMinMax = vec2(8, 2000);
    vec2 origMapMinMax = vec2(8, 2000);
    float mapHeightDelta = 2000;
    vec2 mmPadding = vec2(50.0, 150);
    const float stdHeightPx = 1440.0;
    const float stdWidthPx = 2560.0;
    const float stdTriLableTextOffset = 16.0;
    bool updateMatrices = true;

    void DrawMinimapDebug() {
        CopiableLabeledValue("lastMapMwId", Text::Format("%08x", lastMapMwId));
        CopiableLabeledValue("lastScreenSize", lastScreenSize.ToString());
        CopiableLabeledValue("mapMinMaxY", mapMinMax.ToString());
        CopiableLabeledValue("mapHeightDelta", '' + mapHeightDelta);
        CopiableLabeledValue("vScale", '' + vScale);
        CopiableLabeledValue("minimapCenterPos", minimapCenterPos.ToString());
        CopiableLabeledValue("minimapOuterPos", minimapOuterPos.ToString());
        CopiableLabeledValue("minimapSize", minimapSize.ToString());
    }


    void RenderEarly() {
        auto app = GetApp();

        if (lastMapMwId != GetMapMwIdVal(app.RootMap) && app.CurrentPlayground !is null) {
            startnew(UpdateMapValues);
        }

        if (updateMatrices || S_ScaleMinimapToPlayers || lastScreenSize != g_screen) {
            lastScreenSize = g_screen;
            if (g_screen.y > 1.0) {
                vScale = g_screen.y / stdHeightPx;
                widthScaleForRelative = Math::Max(g_screen.x / g_screen.y * stdHeightPx / stdWidthPx, 1.0);
            }
            if (!g_Active) return;
            mmPadding = vec2(S_MinimapLeftPad, S_MinimapTopBottomPad);
            minimapSize.y = (stdHeightPx - mmPadding.y * 2.) * vScale;
            minimapCenterPos = mmPadding * vScale;
            minimapYOffset = 0.;
            if (S_ScaleMinimapToPlayers) {
                auto @heights = GetDd2FloorHeights();
                int drawToBottomOfFloor = Math::Clamp(int(HeightToFloor(playerMaxHeightLast)) + 2, 0, heights.Length - 1);
                auto maxH = heights[drawToBottomOfFloor];
                auto propShown = (maxH - heights[0]) / heights[heights.Length - 1];
                minimapSize.y /= propShown;
                minimapYOffset = minimapSize.y * (1. - propShown);
                minimapCenterPos.y -= minimapYOffset;
            }
            mmPadding *= vScale;
            minimapPad = minimapSize.x / 2.0;
            minimapOuterPos = minimapCenterPos - minimapPad;
            minimapOuterSize = minimapSize + vec2(0, minimapSize.x);
            playerLabelBaseHeight = S_MinimapPlayerLabelFS * vScale;
            floorNumberBaseHeight = playerLabelBaseHeight * 0.8;
            stdTriHeight = playerLabelBaseHeight * 0.7;
            minMaxLabelHeight = vec2(-2. * stdTriHeight, g_screen.y + stdTriHeight * 2.);
            triLabelTextOffsetX = stdTriLableTextOffset * vScale;
            updateMatrices = false;
        }
    }

    void UpdateMapValues() {
        auto app = GetApp();
        lastMapMwId = GetMapMwIdVal(app.RootMap);
        auto cp = cast<CSmArenaClient>(app.CurrentPlayground);
        // mapMinMax = GetMinMaxHeight(cp);
        // mapHeightDelta = mapMinMax.y - mapMinMax.x;
        // mapMinMax += vec2(-0.05, 0.05) * mapHeightDelta;
        // mapHeightDelta *= 1.1;
        // updateMatrices = true;
        while ((@cp = cast<CSmArenaClient>(app.CurrentPlayground)) !is null && cp.Arena !is null && cp.Arena.MapLandmarks.Length == 0) {
            yield();
        }
        yield();
        if (app.CurrentPlayground is null) return;
        if (lastMapMwId != GetMapMwIdVal(GetApp().RootMap)) return;
        mapMinMax = GetMinMaxHeight(cp);
        origMapMinMax = mapMinMax;
        mapHeightDelta = Math::Max(mapMinMax.y - mapMinMax.x, 8.0);
        // (-0.013, 0.01) and 1.04 perfect for dd2
        mapMinMax += vec2(-0.013, 0.009) * mapHeightDelta;
        mapHeightDelta *= 1.04;
        updateMatrices = true;
    }

    PlayerState@[] fallers;
    PlayerState@[] drivingPlayers;
    // PlayerState@[] afkPlayers;

    int SortFallersAsc(PlayerState@ &in a, PlayerState@ &in b) {
        if (a.HasFallTracker()) {
            if (!b.HasFallTracker()) return 1;
            float ah = a.GetFallTracker().HeightFallenFromFlying();
            float bh = b.GetFallTracker().HeightFallenFromFlying();
            return ah < bh ? -1 : ah > bh ? 1 : 0;
        }
        if (b.HasFallTracker()) return -1;
        return 0;
    }

    PlayerState@ hovered;
    float playerMaxHeightLast = 2000.;

    void Render(bool doDraw) {
        @hovered = null;
        // if (!g_Active) return;
        if (!S_ShowMinimap || !doDraw) return;
        if (lastMapMwId == -1) return;
        RenderMinimapBg();
        RenderMinimapFloors();
        // auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        // if (editor !is null) {
        //     DrawEditorCameraTargetHeight(editor);
        // }
        auto nbPlayers = PS::players.Length;
        float h;
        vec2 screenPos = minimapCenterPos;
        UpdatePlayerLabelGlobals();
        PlayerState@ p;
        PlayerState@ localPlayer;
        float size;
        nvg::FontFace(f_Nvg_ExoRegular);
        playerMaxHeightLast = 0.;
        for (uint i = 0; i < nbPlayers; i++) {
            @p = PS::players[i];
            if (p.IsIdleOrNotUpdated()) continue;
            h = p.pos.y;
            playerMaxHeightLast = Math::Max(h, playerMaxHeightLast);
            if (Math::IsNaN(h)) continue;
            screenPos.y = HeightToMinimapY(h);
            if (screenPos.y < minMaxLabelHeight.x || screenPos.y > minMaxLabelHeight.y) continue;
            size = 5 * vScale;
            p.lastMinimapPos = screenPos;
            if (p.isViewed) {
                @localPlayer = p;
            } else if (p.HasFallTracker() && p.GetFallTracker().IsFallPastMinFall() && !p.IsLowVelocityTurtleIdle) {
                fallers.InsertLast(p);
            } else if (!p.IsLowVelocityTurtleIdle) {
                _InsertPlayerSortedByHeight(drivingPlayers, p);
            } else {
                // lowest level: low velocity turtly / idle
                nvgDrawPointCircle(screenPos, size, cGreen, cMagenta);
                p.minimapLabel.Draw(p, cWhite25, cGray35);
                if (p.minimapLabel.isHovered_Right) @hovered = p;
            }
        }

        for (int i = drivingPlayers.Length - 1; i >= 0; i--) {
            @p = drivingPlayers[i];
            nvgDrawPointCircle(p.lastMinimapPos, size, cGreen, cMagenta);
            p.minimapLabel.Draw(p, cWhite, cBlack);
            if (p.minimapLabel.isHovered_Right) @hovered = p;
        }
        if (drivingPlayers.Length > 0)
        drivingPlayers.RemoveRange(0, drivingPlayers.Length);

        if (fallers.Length > 1) {
            playerQuicksort(fallers, PlayerLessF(SortFallersAsc));
        }

        for (uint i = 0; i < fallers.Length; i++) {
            @p = fallers[i];
            nvgDrawPointCircle(p.lastMinimapPos, 5 * vScale, cBlue, cRed);
            p.minimapLabel.Draw(p, cWhite, cBlack);
            if (p.minimapLabel.isHovered_Right) @hovered = p;
        }
        fallers.RemoveRange(0, fallers.Length);

        if (localPlayer !is null) {
            bool lowVelTurtle = localPlayer.IsLowVelocityTurtleIdle;
            nvgDrawPointCircle(localPlayer.lastMinimapPos, 5 * vScale, cMagenta, cWhite);
            localPlayer.minimapLabel.Draw(localPlayer, lowVelTurtle ? cWhite25 : cWhite, lowVelTurtle ? cGray35 : cBlack);
            if (localPlayer.minimapLabel.isHovered_Right) @hovered = localPlayer;
        }

        if (hovered !is null) {
            hovered.minimapLabel.DrawHovered(hovered);
            // if clicked and fulfil conditions to spectate
            if (UI::IsMouseClicked(UI::MouseButton::Left) && (Spectate::IsSpectator || S_ClickMinimapToMagicSpectate)) {
                Spectate::SpectatePlayer(hovered);
            }
        }

        pbHeight = (localPlayer is null || localPlayer.isLocal) ? Stats::GetPBHeight() : Global::GetPlayersPBHeight(localPlayer);
        RenderMinimapTop3();
    }

    float HeightToMinimapY(float h) {
        return minimapCenterPos.y + minimapSize.y * (1.0 - (h - mapMinMax.x) / Math::Max(mapHeightDelta, 8));
    }

    void RenderMinimapBg() {
        nvg::Reset();
        nvg::StrokeWidth(0.0);
        nvg::BeginPath();
        nvg::RoundedRect(minimapOuterPos, minimapOuterSize, minimapPad);
        nvg::FillColor(cBlack);
        nvg::Fill();
        nvg::ClosePath();
        nvg::BeginPath();
        float innerSize = minimapSize.x / 4.0;
        float innerPad = (minimapSize.x - innerSize) / 2.0;
        nvg::RoundedRect(minimapOuterPos + innerPad, minimapOuterSize - innerPad * 2, innerSize / 2.0);
        nvg::FillColor(cWhite);
        nvg::Fill();
        nvg::ClosePath();
    }

    // void DrawPlayerMinimapPoint(PlayerState@ p) {
    //     // if (Math::IsNaN(p.pos.x) || Math::IsNaN(p.pos.y) || Math::IsNaN(p.pos.z)) return;
    //     auto pos = worldXYToScreen * vec3(p.pos.xy, 1);
    //     auto size = 5 * vScale;
    //     p.lastMinimapPos = pos.xy;
    //     try {
    //         nvgDrawPointCircle(pos.xy, size, cGreen);
    //     } catch {
    //         NotifyWarning("Error drawing minimap point for " + p.DebugString());
    //         warn(Text::Format("%08x", Dev::GetOffsetUint32(p.vehicle.AsyncState, 0x0)));
    //         warn(Text::Format("%08x", Dev::GetOffsetUint32(p.vehicle.AsyncState, 0x4)));
    //         warn(Text::Format("%08x", Dev::GetOffsetUint32(p.vehicle.AsyncState, 0x8)));
    //         warn(Text::Format("%08x", Dev::GetOffsetUint32(p.vehicle.AsyncState, 0xC)));
    //         warn(Text::Format("%08x", Dev::GetOffsetUint32(p.vehicle.AsyncState, 0x10)));
    //         warn(Text::Format("%08x", Dev::GetOffsetUint32(p.vehicle.AsyncState, 0x14)));
    //         warn(Text::Format("%08x", Dev::GetOffsetUint32(p.vehicle.AsyncState, 0x18)));
    //         warn(Text::Format("%08x", Dev::GetOffsetUint32(p.vehicle.AsyncState, 0x1C)));
    //     }
    // }

    float playerLabelBaseHeight = 24;
    float floorNumberBaseHeight = 20;
    float triLabelTextOffsetX = 20;
    float stdTriHeight = playerLabelBaseHeight * 0.7;
    vec2 minMaxLabelHeight;

    // void DrawNvgPlayerLabel(PlayerState@ p) {
    //     nvg::Reset();
    //     nvgDrawTriangleLabel(p, cWhite, cBlack, playerLabelBaseHeight);


    //     // nvg::FontSize(playerLabelBaseHeight);
    //     // nvg::FillColor(cWhite);
    //     // nvg::TextAlign(nvg::Align::Left | nvg::Align::Middle);
    //     // nvg::Text(p.lastMinimapPos + vec2(textOffsetX, 0), p.playerName);
    // }

    // void nvgDrawTriangleLabel(PlayerState@ p, const vec4 &in fg, const vec4 &in bg, float baseHeight) {
    //     nvg::Reset();
    //     nvg::StrokeWidth(0.0);
    //     nvg::FontFace(f_Nvg_ExoRegular);
    //     vec2 pos = p.lastMinimapPos;
    //     nvg::FontSize(baseHeight);
    //     vec2 textBounds = nvg::TextBounds(p.playerName) + vec2(textPad * 2, 0);
    //     vec2 textPos = pos + textPosOff;
    //     float triHeight = baseHeight * 0.6;
    //     vec2 origPos = pos;

    //     vec2 extraPos = textPos + vec2(textBounds.x, 0);
    //     bool isFalling = p.isFalling;
    //     float extraScale = 0.0;
    //     float extraFS = 0.0;
    //     float fallDist;
    //     string fallString;
    //     vec2 extraBounds;
    //     if (isFalling) {
    //         fallDist = p.FallYDistance();
    //         extraScale = Math::Clamp(fallDist / 100.0, 0.1, 1.1) - 0.1;
    //         if (extraScale > 0.0) {
    //             extraFS = baseHeight * extraScale;
    //             nvg::FontSize(extraFS);
    //             fallString = Text::Format(" -%.0f", fallDist);
    //             extraBounds = nvg::TextBounds(fallString);
    //             textBounds += vec2(extraBounds.x, 0);
    //         } else {
    //             isFalling = false;
    //         }
    //     }

    //     nvg::BeginPath();
    //     nvg::PathWinding(nvg::Winding::CW);
    //     nvg::MoveTo(pos);
    //     pos += vec2(baseHeight, triHeight);
    //     nvg::LineTo(pos);
    //     pos += vec2(textBounds.x, 0);
    //     nvg::LineTo(pos);
    //     pos += vec2(0, -2.0 * triHeight);
    //     nvg::LineTo(pos);
    //     pos -= vec2(textBounds.x, 0);
    //     nvg::LineTo(pos);
    //     nvg::LineTo(origPos);
    //     nvg::FillColor(bg);
    //     nvg::Fill();
    //     nvg::ClosePath();

    //     nvg::FontSize(baseHeight);
    //     nvg::BeginPath();
    //     nvg::FillColor(fg);
    //     nvg::TextAlign(nvg::Align::Left | nvg::Align::Middle);
    //     nvg::Text(textPos, p.playerName);
    //     nvg::ClosePath();
    // }

    void UpdatePlayerLabelGlobals() {
        textPosOff = vec2(playerLabelBaseHeight * 1.2, playerLabelBaseHeight * 0.12);
        textPad = playerLabelBaseHeight * 0.2;
    }

    vec2 textPosOff;
    float textPad;

    class PlayerMinimapLabel {
        vec2 pos;
        float textPad;
        vec2 textBounds;
        vec2 textPos;
        vec2 origPos;
        vec2 extraPos;
        bool isFalling;
        float extraScale;
        float extraGlobalScale;
        float fallMag;
        float extraFS = 0.0;
        float fallDist;
        string fallString;
        vec2 extraBounds;
        string name;
        uint lastFalling;
        bool afterFall;
        float fallDegree;
        vec4 playerCol = vec4(1);
        float hoverAreaExtraWidth = 0.;

        PlayerMinimapLabel(PlayerState@ p) {
            name = p.playerName;
            playerCol = p.color;
        }

        void Update(PlayerState@ p) {
            nvg::Reset();
            nvg::StrokeWidth(0.0);
            nvg::FontFace(f_Nvg_ExoBold);

            pos = p.lastMinimapPos;
            nvg::FontSize(playerLabelBaseHeight);
            textPad = playerLabelBaseHeight * 0.2;
            textBounds = nvg::TextBounds(p.playerName) + vec2(textPad * 2.0, 0);
            textPos = pos + textPosOff;
            origPos = pos;
            hoverAreaExtraWidth = stdTriHeight / -2.;
            isFalling = p.isFalling;
            afterFall = !isFalling && Time::Now - lastFalling < AFTER_FALL_MINIMAP_SHOW_DURATION;
            if (isFalling || afterFall) {
                if (!afterFall) {
                    fallDist = p.FallYDistance();
                    if (Time::Now - p.fallStartTs < 15.) fallDist = 0.;
                    // about 2 floors per magnitude
                    fallMag = fallDist / (mapHeightDelta / 16.0);
                    float fallMagQ = fallMag * .25;
                    extraScale = Math::Clamp(fallMag, 0.1, 1.1) - 0.1;
                    // going slow after falling
                    if (fallMagQ > 1.0 && p.vel.LengthSquared() < 1.0) {
                        extraGlobalScale = SmoothLerp(extraGlobalScale, 1.0);
                    } else {
                        extraGlobalScale = SmoothLerp(extraGlobalScale, Math::Clamp(fallMagQ, 1.0, S_MinimapMaxFallingGlobalExtraScale));
                    }
                    // exaggerated for debug
                    // extraGlobalScale = SmoothLerp(extraGlobalScale, Math::Clamp(fallMag * 1., 1.0, S_MinimapMaxFallingGlobalExtraScale));
                    lastFalling = Time::Now;
                    fallDegree = Math::Clamp(fallDist / mapHeightDelta * 2.0, 0.0, 1.0);
                } else {
                    extraGlobalScale = SmoothLerp(extraGlobalScale, 1.0);
                }
                hoverAreaExtraWidth += textPad * extraGlobalScale;
                textPos = pos + textPosOff * extraGlobalScale;
                extraGlobalScale = Math::Clamp(extraGlobalScale, 1.0, S_MinimapMaxFallingGlobalExtraScale);
                extraPos = textPos + vec2(textBounds.x - textPad / 2.0, 0) * extraGlobalScale;
                if (extraScale > 0.001 || playerLabelBaseHeight * extraScale > 2.001) {
                    extraFS = Math::Lerp(extraFS, playerLabelBaseHeight * extraScale, 0.05);
                    nvg::FontFace(f_Nvg_ExoMediumItalic);
                    nvg::FontSize(extraFS);
                    fallString = tostring(int(p.pos.y)) + " (-" + int(fallDist) + ")";
                    extraBounds = Math::Lerp(extraBounds, nvg::TextBounds(fallString), 0.15);
                    textBounds += vec2(extraBounds.x + textPad * 2.0, 0);
                } else {
                    isFalling = false;
                    afterFall = false;
                    extraBounds = vec2();
                    extraFS = 0;
                }
            } else {
                fallDist = 0.0;
                fallDegree = 0.0;
                extraGlobalScale = 1.0;
                extraBounds = vec2();
                extraPos = textPos + vec2(textBounds.x - textPad / 2.0, 0);
            }
            rect = vec4(pos.x + stdTriHeight / 2. * extraGlobalScale,
                        pos.y - stdTriHeight * extraGlobalScale,
                        extraPos.x + (extraBounds.x + hoverAreaExtraWidth) * extraGlobalScale - pos.x,
                        stdTriHeight * 2.0 * extraGlobalScale);
            isHovered_Right = IsWithin(g_MousePos, rect.xy, rect.zw);
        }

        vec4 rect;
        bool isHovered_Right;

        void Draw(PlayerState@ p, const vec4 &in fg, const vec4 &in bg) {
            Update(p);
            nvg::Reset();

            // debug hover/click rect
            // nvg::BeginPath();
            // nvg::Rect(rect.xy, rect.zw);
            // nvg::StrokeColor(cRed);
            // nvg::StrokeWidth(2.0);
            // nvg::Stroke();

            nvg::FontFace(f_Nvg_ExoBold);
            nvg::BeginPath();
            nvg::Scale(extraGlobalScale);
            nvg::LineCap(nvg::LineCapType::Round);
            drawLabelBackgroundTagLines(pos / extraGlobalScale, playerLabelBaseHeight, stdTriHeight, textBounds);
            nvg::FillColor(bg);
            nvg::Fill();
            if (p.isLocal || p.isViewed) {
                nvg::StrokeWidth(1.5 * vScale);
                nvg::StrokeColor(playerCol);
                nvg::Stroke();
            }
            nvg::ClosePath();

            nvg::FontSize(playerLabelBaseHeight);
            nvg::BeginPath();
            nvg::FillColor((fg + playerCol) / 2.0);
            nvg::TextAlign(nvg::Align::Left | nvg::Align::Middle);
            nvg::Text(textPos / extraGlobalScale, name);

            if (extraFS > 1.0 && (isFalling || afterFall)) {
                if (afterFall) {
                    nvg::FillColor(cLightYellow);
                } else {
                    nvg::FillColor(Math::Lerp(cLimeGreen, cOrange, fallDegree));
                }
                nvg::FontFace(f_Nvg_ExoMediumItalic);
                nvg::FontSize(extraFS);
                // nvg::Text(extraPos, tostring(Math::Rand(100, 1000)));
                nvg::Text(extraPos / extraGlobalScale, fallString);
            }

            nvg::ClosePath();

            nvg::ResetTransform();
        }

        void DrawHovered(PlayerState@ p) {
            vec2 hovTL = rect.xy + vec2(rect.z + textPad * 2., 0);
            string l = Text::Format("%.1f m", p.pos.y) + Text::Format(" | PB: %.1f m", Global::GetPlayersPBHeight(p));

            if ((S_ClickMinimapToMagicSpectate && MAGIC_SPEC_ENABLED) || Spectate::IsSpectator) {
                UI::SetMouseCursor(UI::MouseCursor::Hand);
            }
            nvg::Reset();
            nvg::BeginPath();
            nvg::FontFace(f_Nvg_ExoBold);
            float fs = playerLabelBaseHeight * .9 * extraGlobalScale;
            nvg::FontSize(fs);
            vec2 bounds = nvg::TextBounds(l) + textPad * 4.;
            vec2 size = vec2(bounds.x, rect.w);
            vec2 midPoint = hovTL + size / 2.;
            nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
            nvg::Rect(hovTL, size);
            nvg::FillColor(cBlack75);
            nvg::Fill();
            nvg::StrokeColor(cBlack);
            nvg::StrokeWidth(2.0);
            nvg::Stroke();
            nvg::FillColor((cWhite + p.color) / 2.);
            nvg::Text(midPoint + vec2(0, fs * .1), l);
        }
    }

    LBEntry@[]@ top3;
    float pbHeight;
    float hoverTime = 0.;
    float hoverDelta;
    void RenderMinimapTop3() {
        nvg::Reset();
        nvg::FontFace(f_Nvg_ExoBold);
        nvg::FontSize(floorNumberBaseHeight);
        vec2 textBounds = nvg::TextBounds("00") + vec2(textPad * 2.0, 0);
        vec2 pos = vec2(minimapCenterPos.x, 0);
        uint rank;
        int[] hovered = {};
        @top3 = Global::GetTop3();
        for (int i = Math::Min(S_NbTopTimes, top3.Length) - 1; i >= 0; i--) {
            // render pb under WR
            if (i == 0) {
                if (RenderTop3Instance(pos, -1, textBounds, pbHeight)) {
                    hovered.InsertLast(-1);
                }
            }
            rank = i + 1;
            if (RenderTop3Instance(pos, rank, textBounds, top3[i].height)) {
                hovered.InsertLast(rank);
            }
        }
        // ! todo: show stats on hover
        hoverDelta = g_DT / 333.;
        if (hovered.Length > 0) {
            hoverTime = Math::Clamp(hoverTime + hoverDelta, 0., 1.);
            DrawRecordHovered(hovered, hoverTime);
        } else {
            hoverTime = Math::Clamp(hoverTime - hoverDelta, 0.0, 1.0);
        }
    }

    void DrawRecordHovered(int[]@ ranks, float alpha) {
        float height = 0.;
        float heightSum = 0.;
        string name;
        string label;
        int rank;
        for (int i = int(ranks.Length)-1; i >= 0; i--) {
            rank = ranks[i];
            if (label.Length > 0) label += " / ";
            if (rank < 1) {
                height = pbHeight;
                name = "Personal Best";
            } else {
                height = top3[rank - 1].height;
                name = top3[rank - 1].name;
            }
            heightSum += height;
            label += name + Text::Format(" @ %.1f m", height);
        }
        heightSum /= float(ranks.Length);
        nvg::Reset();
        nvg::FontFace(f_Nvg_ExoExtraBold);
        nvg::GlobalAlpha(alpha);
        nvg::BeginPath();
        nvg::LineCap(nvg::LineCapType::Round);
        auto textBounds = nvg::TextBounds(label);
        float pxH = HeightToMinimapY(heightSum);
        vec2 pos = vec2(minimapCenterPos.x, pxH);
        drawLabelBackgroundTagLines(pos, playerLabelBaseHeight, stdTriHeight, textBounds + vec2(playerLabelBaseHeight * 0.4, 0));
        nvg::FillColor(cWhite75);
        nvg::Fill();
        nvg::StrokeWidth(1.5 * vScale);
        nvg::StrokeColor(cBlack);
        nvg::Stroke();
        nvg::ClosePath();
        nvg::BeginPath();
        nvg::FillColor(cBlack);
        nvg::TextAlign(nvg::Align::Left | nvg::Align::Middle);
        nvg::Text(vec2(minimapCenterPos.x + playerLabelBaseHeight * 1.2, pxH + playerLabelBaseHeight * 0.1), label);
        nvg::ClosePath();
        nvg::GlobalAlpha(1.0);
    }

    vec4[] rankColors = {
        cGold, cSilver, cBronze,
    };

    // returns hovered
    bool RenderTop3Instance(vec2 pos, int rank, vec2 textBounds, float height) {
        pos.y = HeightToMinimapY(height);
        nvg::BeginPath();
        nvg::LineCap(nvg::LineCapType::Round);
        drawLabelBackgroundTagLinesRev(pos, floorNumberBaseHeight, stdTriHeight * .95, textBounds);
        nvg::FillColor(rank == 1 ? cGold : rank == 2 ? cSilver : rank == 3 ? cBronze : rank < 0 ?  cSkyBlue : cPaleBlue35);
        nvg::Fill();
        nvg::StrokeWidth(1.5 * vScale);
        nvg::StrokeColor(cBlack);
        nvg::Stroke();
        nvg::ClosePath();
        nvg::BeginPath();
        nvg::FillColor(cBlack);
        nvg::TextAlign(nvg::Align::Right | nvg::Align::Middle);
        pos = pos - vec2(floorNumberBaseHeight, floorNumberBaseHeight * -0.12);
        nvg::Text(pos, rank < 1 ? "PB" : rank == 1 ? "WR" : "#" + rank);
        nvg::ClosePath();
        return IsWithin(g_MousePos, vec2(0, pos.y - stdTriHeight), vec2(pos.x + stdTriHeight*.5, stdTriHeight * 2.));
    }

    void RenderMinimapFloors() {
        // use reverse labels for floors (drawLabelBackgroundTagLinesRev)
        nvg::Reset();
        // nvg::StrokeWidth(0.0);
        nvg::FontFace(f_Nvg_ExoBold);
        nvg::FontSize(floorNumberBaseHeight);

        vec2 textBounds = nvg::TextBounds("00") + vec2(textPad * 2.0, 0);

        vec2 pos = vec2(minimapCenterPos.x, 0);
        auto @heights = GetDd2FloorHeights();
        for (uint i = 0; i < heights.Length; i++) {
            pos.y = HeightToMinimapY(heights[i]);
            nvg::BeginPath();
            nvg::LineCap(nvg::LineCapType::Round);
            drawLabelBackgroundTagLinesRev(pos, floorNumberBaseHeight, stdTriHeight * .75, textBounds);
            nvg::FillColor(cWhite25);
            nvg::Fill();
            nvg::StrokeWidth(1.5 * vScale);
            nvg::StrokeColor(cBlack);
            // nvg::Stroke();
            nvg::ClosePath();
            nvg::BeginPath();
            vec2 dashSize = vec2(floorNumberBaseHeight * 0.8, floorNumberBaseHeight * 0.2);
            float rounding = dashSize.y * .3;
            nvg::RoundedRect(pos - dashSize / 2., dashSize, rounding);
            nvg::FillColor(cBlack);
            nvg::Fill();
            nvg::StrokeColor(cWhite50);
            nvg::Stroke();
            nvg::BeginPath();
            nvg::FillColor(cBlack);
            nvg::TextAlign(nvg::Align::Right | nvg::Align::Middle);
            int finNumber = heights.Length - 1.;
            int endNumber = MatchDD2::lastMapMatchesAnyDD2Uid ? 17 : (g_CustomMap !is null && g_CustomMap.lastFloorEnd ? finNumber - 1 : finNumber);
            int numbersBelowEq = MatchDD2::isEasyDD2Map ? 5 : endNumber - 1;
            nvg::Text(
                pos - vec2(floorNumberBaseHeight * (i < 1 || i > numbersBelowEq ? .8 : 1.0), floorNumberBaseHeight * -0.12),
                i == 0 ? "F.G." :
                i >= finNumber ? "Fin" :
                i == endNumber ? "End" :
                Text::Format("%02d", i)
            );
            nvg::ClosePath();
        }
    }

    vec2 editorTextBounds;

    void DrawEditorCameraTargetHeight(CGameCtnEditorFree@ editor) {
        nvg::Reset();
        nvg::FontFace(f_Nvg_ExoBold);
        nvg::FontSize(playerLabelBaseHeight);
        auto h = editor.OrbitalCameraControl.m_TargetedPosition.y;
        auto pos = vec2(minimapCenterPos.x, HeightToMinimapY(h));
        editorTextBounds = nvg::TextBounds("Editor") + vec2(textPad * 2.0, 0);

        nvg::BeginPath();
        drawLabelBackgroundTagLines(pos, playerLabelBaseHeight, stdTriHeight, editorTextBounds);

        nvg::FillColor(cWhite25);
        nvg::Fill();

        nvg::StrokeWidth(1.5 * vScale);
        nvg::StrokeColor(cWhite);
        nvg::LineCap(nvg::LineCapType::Round);
        nvg::Stroke();

        nvg::ClosePath();
        nvg::BeginPath();
        nvg::FillColor(cWhite);
        nvg::TextAlign(nvg::Align::Left | nvg::Align::Middle);
        nvg::Text(pos + vec2(playerLabelBaseHeight * 1.2, playerLabelBaseHeight * 0.12), "Editor");
        nvg::ClosePath();
    }

    void DrawMenu() {
        if (UI::BeginMenu("Minimap")) {
            S_ShowMinimap = UI::Checkbox("Show Minimap", S_ShowMinimap);
            if (MAGIC_SPEC_ENABLED) S_ClickMinimapToMagicSpectate = UI::Checkbox("Click Minimap to Magic Spectate", S_ClickMinimapToMagicSpectate);
            S_ScaleMinimapToPlayers = UI::Checkbox("Scale Minimap to Players", S_ScaleMinimapToPlayers);
            S_MinimapPlayerLabelFS = UI::SliderInt("Player Label Font Size", S_MinimapPlayerLabelFS, 10, 40);
            S_MinimapLeftPad = UI::SliderFloat("Minimap Left Padding", S_MinimapLeftPad, 0, 200);
            S_MinimapTopBottomPad = UI::SliderFloat("Minimap Top/Bottom Padding", S_MinimapTopBottomPad, 0, 500);
            S_MinimapMaxFallingGlobalExtraScale = Math::Clamp(UI::SliderFloat("Max Extra Scale for Fallers (> ~500m)", S_MinimapMaxFallingGlobalExtraScale, 1.0, 2.0, "%.2f"), 1.0, 2.0);
            updateMatrices = true;
            UI::EndMenu();
        }
    }
}

vec2 GetMinMaxHeight(CSmArenaClient@ cp) {
    if (cp is null || cp.Arena is null) {
        // NotifyWarning("GetMinMaxHeight: cp or cp.Arena is null! cp null: " + (cp is null));
        return vec2();
    }
    auto arena = cp.Arena;
    if (arena.MapLandmarks.Length == 0) {
        Dev_Notify("GetMinMaxHeight: arena.MapLandmarks.Length == 0");
        return vec2();
    }
    vec2 mm = vec2(arena.MapLandmarks[0].Position.y);
    float y;
    for (uint i = 1; i < arena.MapLandmarks.Length; i++) {
        y = arena.MapLandmarks[i].Position.y;
        if (y < mm.x) mm.x = y;
        if (y > mm.y) mm.y = y;
    }
    return mm;
}

uint GetMapMwIdVal(CGameCtnChallenge@ map) {
    if (map is null) return -1;
    return map.Id.Value;
}

string GetMwIdName(uint v) {
    MwId id = MwId(v);
    return id.GetName();
}
uint GetMwIdValue(const string &in name) {
    MwId id = MwId();
    id.SetName(name);
    return id.Value;
}

// Cold Beginning - f1
// xddlent
// Summer Slide
// You're Skewed
// Thawing Temple - f5
// The Knot
// The Sponge
// Koopa Troopa
// Strawberry Cheesecake
// Ice Gold - f10
// Missing Pieces
// Paarse Ramp
// Iolites Trace
// Spider Sense
// Scared Of Dragons?
// On the Edge - f16
// The End (1793m)

const float[] DD2_FLOOR_HEIGHTS = {
    8.0,
    104.0, // 01
    208.0, // 02
    312.0, // 03
    416.0, // 04
    520.0, // 05
    624.0, // 06
    728.0, // 07
    832.0, // 08
    936.0, // 09
    1040.0, // 10
    1144.0, // 11
    1264.0, // 12 -- 48 -> 64
    1376.0, // 13 -- 52 -> 76
    1480.0, // 14 -- 56 -> 80
    1584.0, // 15 -- 60 -> 84
    1688.0, // 16 -- 64 -> 88
    1793.0, // 17 - end
    1910.0  // fin
};

const float [] DD2_EASY_FLOOR_HEIGHTS = {
    8.0,
    104.0, // 01
    208.0, // 02
    312.0, // 03
    416.0, // 04
    520.0, // 05
    624.0 // Fin
};

const float[]@ GetDd2FloorHeights() {
    if (MatchDD2::isDD2Proper) return DD2_FLOOR_HEIGHTS;
    if (MatchDD2::isEasyDD2Map) return DD2_EASY_FLOOR_HEIGHTS;
    if (g_CustomMap !is null && g_CustomMap.IsEnabledNotDD2 && g_CustomMap.spec !is null) return g_CustomMap.spec.floors;
    return DD2_FLOOR_HEIGHTS;
}
