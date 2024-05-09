[Setting hidden]
bool S_BlockCam7Drivable = true;

namespace BlockCam7Drivable {
    int64 lastBlockTime = 0;
    void Update() {
        if (!S_BlockCam7Drivable) return;
        auto app = GetApp();
        if (app.CurrentPlayground is null) return;
        try {
            auto gt = app.CurrentPlayground.GameTerminals[0];
            if (gt is null) return;
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
