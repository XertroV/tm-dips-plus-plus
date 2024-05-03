[Setting hidden]
bool S_WizardFinished = false;

bool g_WizardOpen = false;

namespace Wizard {
    void OnPluginLoad() {
        g_WizardOpen = !S_WizardFinished;
    }

    const int2 windowSize = int2(800, 500);
    int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoResize | UI::WindowFlags::NoSavedSettings | UI::WindowFlags::AlwaysAutoResize;
    float ui_scale = UI::GetScale();

    void DrawWindow() {
        if (!g_WizardOpen) return;
        UI::SetNextWindowSize(windowSize.x, windowSize.y, UI::Cond::Always);
        auto pos = (int2(ui_scale * g_screen.x, ui_scale * g_screen.y) - windowSize) / 2;
        UI::SetNextWindowPos(pos.x, pos.y, UI::Cond::Always);
        if (UI::Begin("D++ Wizard", g_WizardOpen, flags)) {

        }
        UI::End();
    }

    void DrawInner() {
        if (ui_dips_pp_logo_sm is null) {
            UI::Text("Loading...");
            return;
        }
    }
}
