[Setting hidden]
bool S_ShowUpdateAtStartup = true;

bool g_ShowWelcome = false;


// not done but render not called yet.
namespace WelcomeScreen {
    bool loading = true;
    void OnLoad() {
        g_ShowWelcome = S_ShowUpdateAtStartup;
        while (g_api is null || !g_api.HasContext) yield();
        loading = false;
    }

    void Render() {
        if (!g_ShowWelcome) return;
        if (UI::Begin("dips++ welcome", UI::WindowFlags::NoCollapse | UI::WindowFlags::NoResize | UI::WindowFlags::NoDecoration)) {
            DrawCenteredText("Deep Dip 2 | Updates", f_DroidBigger, 26.);
            // lb with time ago
            // prizepool
            // donation cheers
            if (UI::Button("Close")) {
                g_ShowWelcome = false;
            }
        }
    }
}
