/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
/*
    General idea:
    - watch for MT changes
    - current playground > game terminals [0] > mt clip
*/

string lastMtClipName = "";

// not final
const string DD2_MAP_UID = "DeepDip2__The_Storm_Is_Here";

bool IsDD2Map() {
    auto map = GetApp().RootMap;
    if (map is null) return false;
    return map.MapInfo !is null
        ? map.MapInfo.MapUid == DD2_MAP_UID
        : map.EdChallengeId == DD2_MAP_UID;
}

void MTWatcherForMap() {
    auto app = GetApp();
    if (app.RootMap is null) throw("map null");
    if (app.CurrentPlayground is null) throw("current pg null");
    uint uidMwIdV = app.RootMap.Id.Value;
    CGameCtnMediaClipPlayer@ clipPlayer = null;
    while (true) {
        try {
            if (app.RootMap is null) break;
            if (app.RootMap.Id.Value != uidMwIdV) break;
            if (app.CurrentPlayground is null) break;
            if (app.CurrentPlayground.GameTerminals.Length == 0) break;
            if (app.CurrentPlayground.GameTerminals[0].UISequence_Current != SGamePlaygroundUIConfig::EUISequence::Playing) {
                if (lastMtClipName.Length > 0) {
                    OnMtClipGoneNull();
                    @clipPlayer = null;
                    lastMtClipName = "";
                }
                yield();
                continue;
            }
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
        } catch {
            warn("MTWatcherForMap error: " + getExceptionInfo());
        }

        yield();
    }
    lastMtClipName = "";
    trace('MTWatcherForMap ending');
}

void OnMtClipGoneNull() {
    // don't care
}

void OnMtClipChanged(const string &in clipName) {
    if (!IsDD2Map()) return;
    // check for voice lines
    trace("Active MT Clip became: " + clipName);
    if (clipName.StartsWith("VAE")) {
        CheckSilenceVoiceLine();
    }
}

void CheckSilenceVoiceLine() {
    if (!IsDD2Map()) return;
    auto @clipPlayer = GetApp().CurrentPlayground.GameTerminals[0].MediaClipPlayer;
    if (clipPlayer.Clip is null) return;
    auto @clip = clipPlayer.Clip;
    for (uint i = 0; i < clip.Tracks.Length; i++) {
        CheckSilenceVoiceLineTrack(clip.Tracks[i]);
    }
}

void CheckSilenceVoiceLineTrack(CGameCtnMediaTrack@ track) {
    for (uint i = 0; i < track.Blocks.Length; i++) {
        CheckSilenceVoiceLineBlock(track.Blocks[i]);
    }
}

void CheckSilenceVoiceLineBlock(CGameCtnMediaBlock@ block) {
    auto text = cast<CGameCtnMediaBlockText>(block);
    auto tris2d = cast<CGameCtnMediaBlockTriangles2D>(block);
    auto sound = cast<CGameCtnMediaBlockSound>(block);
    if (text !is null) {
        trace('silencing VL text, was: ' + text.Text);
        text.Text = "";
    } else if (tris2d !is null) {
        trace('silencing VL tris2d');
        auto timesOffset = GetOffset(tris2d, 'Mobil') + 0x8;
        auto timesPtr = Dev::GetOffsetUint64(tris2d, timesOffset);
        if (timesPtr > 0xFFFFFFFF && timesPtr % 8 == 0) {
            trace("Setting tris2d mid/end to start at " + Text::FormatPointer(timesPtr));
            Dev::Write(timesPtr + 0x4, float(tris2d.Start));
            Dev::Write(timesPtr + 0x8, float(tris2d.Start));
        }
        // Dev::SetOffset(tris2d, GetOffset(tris2d, 'End'), tris2d.Start);
        // tris2d.End = tris2d.Start;
    } else if (sound !is null) {
        trace('silencing VL sound');
        sound.PlayCount = 0;
        if (sound.AudioSource !is null) {
            sound.AudioSource.VolumedB = -100;
        }
    }
}
