[Setting hidden]
bool S_EnableForEasyMap = true;

// checked when getting stats from server
[Setting hidden]
bool F_HaveDoneEasyMapCheck = false;

[Setting hidden]
bool F_PlayedDD2BeforeEasyMap = false;

// before post processing
const string DD2_EASY_MAP_UID2 = "NKvTW5AJPyoibZmpNhuEqkLpCB9";

namespace EasyMap {
    void DrawMenu() {
        if (UI::BeginMenu("Easy Map")) {
            bool pre = S_EnableForEasyMap;
            S_EnableForEasyMap = UI::Checkbox("Enable Dips++ for Easy Map", S_EnableForEasyMap);
            if (S_EnableForEasyMap != pre) {
                MatchDD2::lastMapMwId = 0;
            }
            if (F_PlayedDD2BeforeEasyMap) {
                UI::TextWrapped("\\$f80Warning\\$z, if you enable this, your stats will count both the normal DD2 map and the [E] version. Recommendation: do \\$f80NOT\\$z climb the [E] tower with this enabled. (Respawning and spectating or whatever is okay.)");
            }
            UI::EndMenu();
        }
    }
}
