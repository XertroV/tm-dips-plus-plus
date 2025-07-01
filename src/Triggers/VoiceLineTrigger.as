// VL trigger for custom maps / aux spec / JSON voice lines
class VoiceLineTrigger : GameTrigger {
    string audioFilename;
    string subtitles;
    string imageAsset;
    bool allowRepeats = false;
    bool played = false;

    VoiceLineTrigger(vec3 &in min, vec3 &in max, const string &in name, const string &in audioFilename, const string &in subtitles, const string &in imageAsset = "", bool allowRepeats = false) {
        // todo: is there a better existing trigger to use?
        super(min, max, name);
        this.debug_strokeColor = StrHashToCol(name);
        this.audioFilename = AuxiliaryAssets::GetLocalPath("audio/" + audioFilename);
        this.subtitles = subtitles;
        this.imageAsset = imageAsset.Length > 0 ? AuxiliaryAssets::GetLocalPath("img/" + imageAsset) : "";
        this.allowRepeats = allowRepeats;
        // Check if the voice line has already been played
        if (g_CustomMap !is null && g_CustomMap.hasStats) {
            played = g_CustomMap.stats.Has_CM_VoiceLinePlayed(name);
            dev_trace("VoiceLineTrigger: " + name + " already played: " + played);
        }
    }

    void OnEnteredTrigger(DipsOT::OctTreeRegion@ prevTrigger) override {
        bool hasStats = g_CustomMap !is null && g_CustomMap.hasStats;

        // check if we should exit early (if we've already played this voice line and it doesn't allow repeats)
        if (!allowRepeats) {
            if (played) return;
            if (hasStats) {
                if (g_CustomMap.stats.Has_CM_VoiceLinePlayed(name)) {
                    dev_trace("VoiceLineTrigger::OnEnteredTrigger: " + name + " already played: " + played);
                    played = true;
                    return;
                }
            }
        }

        // update stats
        if (hasStats) {
            g_CustomMap.stats.Set_CM_VoiceLinePlayed(name);
            played = true;
        }
        dev_trace("VoiceLineTrigger::OnEnteredTrigger: Playing " + name);

        // Play audio
        // must call IO::FromStorageFolder because it will default to DD2 asset folder otherwise.
        AudioChain({IO::FromStorageFolder(audioFilename)}).WithPlayAnywhere().Play();
        // Display subtitles
        DTexture@ imgTex = null;
        @imgTex = imageAsset.Length > 0 ? DTexture(imageAsset) : imgTex;
        AddSubtitleAnimation_PlayAnywhere(SubtitlesAnim("", imgTex !is null, subtitles, imgTex));
    }
}
