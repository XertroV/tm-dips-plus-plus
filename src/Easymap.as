[Setting hidden]
bool S_EnableForEasyMap = true;

// checked when getting stats from server
[Setting hidden]
bool F_HaveDoneEasyMapCheck = false;

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
            UI::EndMenu();
        }
    }
}
