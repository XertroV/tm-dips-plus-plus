[Setting hidden]
bool S_ShowGreenTimer = true;

[Setting hidden]
vec2 S_GreenTimerPos = vec2(0.95, 0.5);

[Setting hidden]
int S_GreenTimerAlign = nvg::Align::Right | nvg::Align::Middle;

[Setting hidden]
vec4 S_GreenTimerColor = vec4(0.14f, 0.74f, 0.3f, 1.f);

[Setting hidden]
float S_GreenTimerFontSize = 120.;

const string WRITUAL_LOGIN = "vUUgTIDxSAm5gziz8P_B7w";
const string XERTROV_LOGIN = "Ci0bwEqqQ3Sy2z1WG9qxyQ";

[Setting hidden]
bool wirtModeDone = false;

bool wirtualMode = false;

namespace GreenTimer {
    bool wirtualMode = false;
    vec2[] extraPos = {};

    void OnPluginStart() {
        // wirtualMode = GetLocalLogin() == WRITUAL_LOGIN;
    }

    void Render() {
        if (!S_ShowGreenTimer) return;
        nvg::Reset();
        nvg::FontSize(S_GreenTimerFontSize * Minimap::vScale);
        nvg::FontFace(f_Nvg_ExoBold);
        nvg::TextAlign(S_GreenTimerAlign);
        nvg::BeginPath();
        _DrawGreenTimer(S_GreenTimerPos);
        if (!wirtModeDone && wirtualMode) {
            for (uint i = 0; i < extraPos.Length; i++) {
                nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
                _DrawGreenTimer(extraPos[i]);
            }
        }
        nvg::ClosePath();
    }

    void _DrawGreenTimer(vec2 pos) {
        DrawTextWithShadow(g_screen * pos, Time::Format(Stats::msSpentInMap, false, true, true), S_GreenTimerColor);
    }

    string setTimerTo = "";

    void DrawSettings() {
        if (UI::BeginMenu("Green Timer")) {
#if DEV
            // UI::Text("wm: " + wirtualMode);
            // UI::Text("wmd:" + wirtModeDone);
#endif
            S_ShowGreenTimer = UI::Checkbox("Green Timer", S_ShowGreenTimer);
            S_GreenTimerFontSize = UI::SliderFloat("Font Size", S_GreenTimerFontSize, 10, 200);
            if (!wirtModeDone && wirtualMode) {
                startnew(WirtModeIncrement);
            }
            S_GreenTimerPos = UI::InputFloat2("Pos (0-1)", S_GreenTimerPos);
            S_GreenTimerAlign = InputAlign("Align", S_GreenTimerAlign);
            string curr = Time::Format(Stats::msSpentInMap, false, true, true);
            if (setTimerTo == "") setTimerTo = curr;
            UI::Text("Current Timer: " + curr);
            bool changed = false;
            setTimerTo = UI::InputText("Set Timer To", setTimerTo, changed);
            if (changed) {
                tryUpdateTimeInMap(setTimerTo);
            }
            if (parseErr != "") {
                UI::TextWrapped("\\$f80Parse Error: " + parseErr);
            }
            UI::EndMenu();
        }
    }

    string parseErr;

    void tryUpdateTimeInMap(const string &in setTimerTo) {
        try {
            auto parts = setTimerTo.Trim().Split(":");
            if (parts.Length != 3) {
                parseErr = "format: h:mm:ss";
                return;
            }
            int hours = Text::ParseInt(parts[0]);
            int min = Text::ParseInt(parts[1]);
            int sec = Text::ParseInt(parts[2]);
            Stats::msSpentInMap = (hours * 3600 + min * 60 + sec) * 1000;
            parseErr = "";
        } catch {
            parseErr = "exception: " + getExceptionInfo();
        }
    }

    void WirtModeIncrement() {
        yield();
        yield();
        yield();
        if (S_ShowGreenTimer) return;
        if (extraPos.Length > 10) {
            wirtModeDone = true;
            wirtualMode = false;
            Meta::SaveSettings();
        } else {
            extraPos.InsertLast(RandVec2(0.1, 0.9));
            S_ShowGreenTimer = true;
        }
    }
}



nvg::Align InputAlign(const string &in label, uint v) {
    bool l = (v & nvg::Align::Left) > 0;
    bool c = (v & nvg::Align::Center) > 0;
    bool r = (v & nvg::Align::Right) > 0;
    bool t = (v & nvg::Align::Top) > 0;
    bool m = (v & nvg::Align::Middle) > 0;
    bool b = (v & nvg::Align::Bottom) > 0;
    bool bl = (v & nvg::Align::Baseline) > 0;
    UI::Text(label + ": " + (l ? "Left" : c ? "Center" : "Right") + " | " + (t ? "Top" : m ? "Middle" : b ? "Bottom" : "Baseline"));
    if (ButtonSL("Left"))       v = (v & 0b1111000) | nvg::Align::Left;
    if (ButtonSL("Center"))     v = (v & 0b1111000) | nvg::Align::Center;
    if (UI::Button("Right"))    v = (v & 0b1111000) | nvg::Align::Right;
    if (ButtonSL("Top"))        v = (v & 0b0000111) | nvg::Align::Top;
    if (ButtonSL("Middle"))     v = (v & 0b0000111) | nvg::Align::Middle;
    if (ButtonSL("Bottom"))     v = (v & 0b0000111) | nvg::Align::Bottom;
    if (UI::Button("Baseline")) v = (v & 0b0000111) | nvg::Align::Baseline;
    return nvg::Align(v);
}

bool ButtonSL(const string &in label) {
    bool ret = UI::Button(label);
    UI::SameLine();
    return ret;
}
