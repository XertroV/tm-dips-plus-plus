/*
    General idea:
    - watch for MT changes
    - current playground > game terminals [0] > mt clip
*/

string lastMtClipName = "";

void MTWatcherForMap() {
    auto app = GetApp();
    if (app.RootMap is null) throw("map null");
    if (app.CurrentPlayground is null) throw("current pg null");
    uint uidMwIdV = app.RootMap.Id.Value;
    CGameCtnMediaClipPlayer@ clipPlayer = null;
    while (true) {
        if (app.RootMap is null) break;
        if (app.RootMap.Id.Value != uidMwIdV) break;
        if (app.CurrentPlayground is null) break;
        if (app.CurrentPlayground.GameTerminals.Length == 0) break;
        @clipPlayer = app.CurrentPlayground.GameTerminals[0].MediaClipPlayer;
        if (clipPlayer is null) throw("clipPlayer null");

        if (clipPlayer.Clip is null) {
            if (lastMtClipName.Length > 0) {
                OnMtClipGoneNull();
                lastMtClipName = "";
            }
        } else {
            if (lastMtClipName != clipPlayer.Clip.Name) {
                OnMtClipChanged(clipPlayer.Clip.Name);
                lastMtClipName = clipPlayer.Clip.Name;
            }
        }

        yield();
    }
    lastMtClipName = "";
}

void OnMtClipGoneNull() {
    // don't care
}

void OnMtClipChanged(const string &in clipName) {
    // check for voice lines

}
