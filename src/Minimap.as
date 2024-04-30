const uint AFTER_FALL_MINIMAP_SHOW_DURATION = 10000;
const uint AFTER_FALL_STABLE_AFTER = 4000;

/// A vertical minimap for showing falls in real time
/// ~~Rotates in 3d depending on camera orientation~~
namespace Minimap {
    vec3 camPos;
    mat4 camProjMat;
    vec2 minimapCenterPos;
    float minimapPad;
    vec2 minimapOuterPos;
    vec2 minimapSize = vec2(12, 900);
    vec2 minimapOuterSize = vec2(16, 900);
    // vec2 worldMin = vec2(0, -64);
    // vec2 worldMax = vec2(1650, 2000);
    // mat3 worldXYToUv;
    // mat3 worldXYToScreen;
    float vScale;
    float widthScaleForRelative;
    uint lastMapMwId;
    vec2 lastScreenSize;
    vec2 mapMinMax = vec2(8, 2000);
    float mapHeightDelta = 2000;
    vec2 mmPadding = vec2(50.0, 150);
    const float stdHeightPx = 1440.0;
    const float stdWidthPx = 2560.0;
    const float stdTriLableTextOffset = 16.0;
    bool updateMatrices = false;

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

        if (updateMatrices || lastScreenSize != g_screen) {
            lastScreenSize = g_screen;
            if (g_screen.y > 1.0) {
                vScale = g_screen.y / stdHeightPx;
                widthScaleForRelative = Math::Max(g_screen.x / g_screen.y * stdHeightPx / stdWidthPx, 1.0);
            }
            mmPadding = vec2(50.0, 150);
            minimapSize.y = (stdHeightPx - mmPadding.y * 2.) * vScale;
            minimapCenterPos = mmPadding * vScale;
            mmPadding *= vScale;
            minimapPad = minimapSize.x / 2.0;
            minimapOuterPos = minimapCenterPos - minimapPad;
            minimapOuterSize = minimapSize + vec2(0, minimapSize.x);
            playerLabelBaseHeight = S_MinimapPlayerLabelFS * vScale;
            floorNumberBaseHeight = playerLabelBaseHeight * 0.8;
            stdTriHeight = playerLabelBaseHeight * 0.6;
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
        mapHeightDelta = Math::Max(mapMinMax.y - mapMinMax.x, 8.0);
        // (-0.013, 0.01) and 1.04 perfect for dd2
        mapMinMax += vec2(-0.013, 0.009) * mapHeightDelta;
        mapHeightDelta *= 1.04;
        updateMatrices = true;
    }

    PlayerState@[] fallers;

    void Render() {
        // if (!g_Active) return;
        if (!S_ShowMinimap) return;
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
        for (uint i = 0; i < nbPlayers; i++) {
            @p = PS::players[i];
            if (p.IsIdleOrNotUpdated()) continue;
            h = p.pos.y;
            if (Math::IsNaN(h)) continue;
            screenPos.y = HeightToMinimapY(h);
            if (screenPos.y < minMaxLabelHeight.x || screenPos.y > minMaxLabelHeight.y) continue;
            size = 5 * vScale;
            p.lastMinimapPos = screenPos;
            if (p.isLocal) {
                @localPlayer = p;
            } else if (p.isFalling || p.minimapLabel.afterFall) {
                fallers.InsertLast(p);
            } else {
                nvgDrawPointCircle(screenPos, size, cGreen, cMagenta);
                p.minimapLabel.Draw(p, cWhite, cBlack);
            }
        }

        for (uint i = 0; i < fallers.Length; i++) {
            @p = fallers[i];
            nvgDrawPointCircle(p.lastMinimapPos, 5 * vScale, cBlue, cRed);
            p.minimapLabel.Draw(p, cWhite, cBlack);
        }
        fallers.RemoveRange(0, fallers.Length);

        if (localPlayer !is null) {
            nvgDrawPointCircle(localPlayer.lastMinimapPos, 5 * vScale, cMagenta, cWhite);
            localPlayer.minimapLabel.Draw(localPlayer, cWhite, cBlack);
            @localPlayer = null;
        }
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
    float stdTriHeight = playerLabelBaseHeight * 0.6;
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
        float extraFS = 0.0;
        float fallDist;
        string fallString;
        vec2 extraBounds;
        string name;
        uint lastFalling;
        bool afterFall;
        float fallDegree;
        vec4 playerCol = vec4(1);

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
            isFalling = p.isFalling;
            afterFall = !isFalling && Time::Now - lastFalling < AFTER_FALL_MINIMAP_SHOW_DURATION;
            if (isFalling || afterFall) {
                if (!afterFall) {
                    fallDist = p.FallYDistance();
                    extraScale = Math::Clamp(fallDist / (mapHeightDelta / 16.0), 0.1, 1.1) - 0.1;
                    lastFalling = Time::Now;
                    fallDegree = Math::Clamp(fallDist / mapHeightDelta * 2.0, 0.0, 1.0);
                }
                if (extraScale > 0.0 || playerLabelBaseHeight * extraScale > 1.0) {
                    extraPos = textPos + vec2(textBounds.x - textPad / 2.0, 0);
                    extraFS = Math::Lerp(extraFS, playerLabelBaseHeight * extraScale, 0.05);

                    nvg::FontFace(f_Nvg_ExoRegularItalic);
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
            }
        }

        void Draw(PlayerState@ p, const vec4 &in fg, const vec4 &in bg) {
            Update(p);
            nvg::Reset();
            nvg::FontFace(f_Nvg_ExoBold);
            nvg::BeginPath();
            nvg::LineCap(nvg::LineCapType::Round);
            drawLabelBackgroundTagLines(pos, playerLabelBaseHeight, stdTriHeight, textBounds);
            nvg::FillColor(bg);
            nvg::Fill();
            if (p.isLocal) {
                nvg::StrokeWidth(1.5 * vScale);
                nvg::StrokeColor(playerCol);
                nvg::Stroke();
            }
            nvg::ClosePath();

            nvg::FontSize(playerLabelBaseHeight);
            nvg::BeginPath();
            nvg::FillColor((fg + playerCol) / 2.0);
            nvg::TextAlign(nvg::Align::Left | nvg::Align::Middle);
            nvg::Text(textPos, name);

            if (extraFS > 1.0 && (isFalling || afterFall)) {
                if (afterFall) {
                    nvg::FillColor(cLightYellow);
                } else {
                    nvg::FillColor(Math::Lerp(cLimeGreen, cOrange, fallDegree));
                }
                nvg::FontFace(f_Nvg_ExoRegularItalic);
                nvg::FontSize(extraFS);
                // nvg::Text(extraPos, tostring(Math::Rand(100, 1000)));
                nvg::Text(extraPos, fallString);
            }

            nvg::ClosePath();
        }
    }

    void RenderMinimapFloors() {
        // use reverse labels for floors (drawLabelBackgroundTagLinesRev)
        nvg::Reset();
        // nvg::StrokeWidth(0.0);
        nvg::FontFace(f_Nvg_ExoBold);
        nvg::FontSize(floorNumberBaseHeight);

        vec2 textBounds = nvg::TextBounds("00") + vec2(textPad * 2.0, 0);

        vec2 pos = vec2(minimapCenterPos.x, 0);
        for (uint i = 0; i < DD2_FLOOR_HEIGHTS.Length; i++) {
            pos.y = HeightToMinimapY(DD2_FLOOR_HEIGHTS[i]);
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
            nvg::FillColor(cBlack);
            nvg::TextAlign(nvg::Align::Right | nvg::Align::Middle);
            nvg::Text(
                pos - vec2(floorNumberBaseHeight * (i < 1 || i > 16 ? .8 : 1.0), floorNumberBaseHeight * -0.12),
                i == 0 ? "F.G." :
                i >= 17 ? "Fin" : Text::Format("%02d", i)
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
}

vec2 GetMinMaxHeight(CSmArenaClient@ cp) {
    if (cp is null || cp.Arena is null) {
        // NotifyWarning("GetMinMaxHeight: cp or cp.Arena is null! cp null: " + (cp is null));
        return vec2();
    }
    auto arena = cp.Arena;
    if (arena.MapLandmarks.Length == 0) {
        NotifyWarning("GetMinMaxHeight: arena.MapLandmarks.Length == 0");
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


const float[] DD2_FLOOR_HEIGHTS = {
    4.0,
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
    1910.0  // 17 fin
};
