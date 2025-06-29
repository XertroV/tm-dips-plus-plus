class VoiceLineTrigger : GameTrigger {
    string audioFilename;
    string subtitles;
    string imageAsset;

    VoiceLineTrigger(vec3 &in min, vec3 &in max, const string &in name, const string &in audioFilename, const string &in subtitles, const string &in imageAsset = "") {
        // todo: is there a better existing trigger to use?
        super(min, max, name);
        this.audioFilename = audioFilename;
        this.subtitles = subtitles;
        this.imageAsset = imageAsset;
        this.debug_strokeColor = vec4(0, 1, 0, 1);
    }

    void OnEnteredTrigger(DipsOT::OctTreeRegion@ prevTrigger) override {
        // Play audio
        AudioChain({IO::FromStorageFolder(AuxiliaryAssets::GetLocalPath("audio/" + audioFilename))}).WithPlayAnywhere().Play();
        // Display subtitles
        DTexture@ imgTex = null; // todo
        AddSubtitleAnimation_PlayAnywhere(SubtitlesAnim("", true, subtitles, imgTex));
    }
}
