// checked when getting stats from server
[Setting hidden]
bool F_HaveDoneEasyMapCheck = false;

[Setting hidden]
bool F_PlayedDD2BeforeEasyMap = false;

[Setting hidden]
bool S_EnableSavingStatsOnEasyMap = true;

[Setting hidden]
bool S_EnableForEasyMap = true;

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
            S_EnableSavingStatsOnEasyMap = UI::Checkbox("Enable saving stats on Easy Map", S_EnableSavingStatsOnEasyMap);
            if (F_PlayedDD2BeforeEasyMap) {
                if (UI::BeginChild("ezmwarn", vec2(300., 300))) {
                    UI::TextWrapped("\\$f80Warning\\$z, if you enable the easy map, your stats will count both the normal DD2 map and the [E] version unless you disable saving stats. Recommendation: do \\$f80NOT\\$z climb the [E] tower with these options enabled. (Respawning and spectating or whatever is okay.)");
                    UI::Dummy(vec2(0, 10));
                }
                UI::EndChild();
            }
            UI::EndMenu();
        }
    }
}
