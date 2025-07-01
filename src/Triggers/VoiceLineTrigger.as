class VoiceLineTrigger : GameTrigger {
    string audioFilename;
    string subtitles;
    string imageAsset;

    VoiceLineTrigger(vec3 &in min, vec3 &in max, const string &in name, const string &in audioFilename, const string &in subtitles, const string &in imageAsset = "") {
        // todo: is there a better existing trigger to use?
        super(min, max, name);
        this.audioFilename = AuxiliaryAssets::GetLocalPath("audio/" + audioFilename);
        this.subtitles = subtitles;
        this.imageAsset = imageAsset.Length > 0 ? AuxiliaryAssets::GetLocalPath("img/" + imageAsset) : "";
        this.debug_strokeColor = StrHashToCol(name);
    }

    void OnEnteredTrigger(DipsOT::OctTreeRegion@ prevTrigger) override {
        // Play audio
        // must call IO::FromStorageFolder because it will default to DD2 asset folder otherwise.
        AudioChain({IO::FromStorageFolder(audioFilename)}).WithPlayAnywhere().Play();
        // Display subtitles
        DTexture@ imgTex = null;
        @imgTex = imageAsset.Length > 0 ? DTexture(imageAsset) : imgTex;
        AddSubtitleAnimation_PlayAnywhere(SubtitlesAnim("", imgTex !is null, subtitles, imgTex));
    }
}
