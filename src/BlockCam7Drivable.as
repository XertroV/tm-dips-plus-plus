[Setting hidden]
bool S_BlockCam7Drivable = true;
[Setting hidden]
bool S_Cam7MovementAlert = true;

namespace BlockCam7Drivable {
    int64 lastBlockTime = 0;
    void Update(CGameTerminal@ gt) {
        if (!S_BlockCam7Drivable) return;
        try {
            if (gt is null) return;
            if (gt.UISequence_Current != SGamePlaygroundUIConfig::EUISequence::Playing) return;
            if (GetIsCam7Drivable(gt)) {
                SetCam7Drivable(gt, false);
                lastBlockTime = Time::Now;
            }
        } catch {
            // ignore
            dev_trace('exception in BlockCam7Drivable: ' + getExceptionInfo());
        }
    }

    void Render() {
        if (Time::Now - lastBlockTime < 750) {
            nvg::Reset();
            nvg::FontSize(50. * Minimap::vScale);
            nvg::FontFace(f_Nvg_ExoExtraBold);
            nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
            nvg::BeginPath();
            DrawTextWithStroke(vec2(.5, .2) * g_screen, "Blocked Cam7 Drivable!", cOrange, 4. * Minimap::vScale);
        }
    }

    bool GetIsCam7Drivable(CGameTerminal@ gt) {
        return Dev::GetOffsetUint32(gt, 0x60) == 0;
    }

    void SetCam7Drivable(CGameTerminal@ gt, bool value) {
        Dev::SetOffset(gt, 0x60, value ? 0 : 1);
    }
}

namespace Cam7 {
    bool GetIsInCam7(CGameTerminal@ gt) {
        // setting 0x34 to 2 does nothing; setting 0x40 will change to freecam, so use that for test
        // return Dev::GetOffsetUint32(gt, 0x34) == 2;
        return Dev::GetOffsetUint32(gt, 0x40) == 2;
    }

    int64 lastCam7Time = -1;
    bool cartoonPlayed = false;
    void Update(CGameTerminal@ gt) {
        if (!S_Cam7MovementAlert || gt is null) return;
        if (GetIsInCam7(gt)) {
            lastCam7Time = Time::Now;
            if (PS::localPlayer.isFalling && !cartoonPlayed) {
                // play cartoon sound when fall started in cam7
                AudioChain({"cartoon.mp3"}).WithPlayAnywhere().Play();
                cartoonPlayed = true;
            }
        } else {
            lastCam7Time = -1; // reset if not in cam7
            cartoonPlayed = false;
        }
    }

    // todo: play cartoon sound when falling in cam7
    void MovementAlertRender() {
        // could add a visual indicator here, but funnier (at least to start with) if we just play a sound when falling starts.
    }
}
