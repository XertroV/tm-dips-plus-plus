[Setting hidden]
bool S_PauseWhenGameUnfocused = true;

namespace Volume {
    string vtFile = "subtitles/volume_test.txt";
    AudioChain@ vtAudio;
    SubtitlesAnim@ vtSubtitlesAnim;

    void VolumeOnPluginStart() {
        @vtAudio = AudioChain({"vt/volume_test.mp3"}).WithPlayAnywhere();
    }

    float volSetting {
        get {
            return Math::Clamp(Math::Log10(1. + 9. * S_VolumeGain), 0., 1.);
        }
        set {
            S_VolumeGain = (Math::Pow(10., Math::Clamp(value, 0.0, 1.0)) - 1.) / 9.;
        }
    }

    bool IsAudioTestRunning() {
        return vtAudio !is null && vtAudio.isPlaying;
    }

    void DrawMenu() {
        if (UI::BeginMenu("Audio")) {
            DrawVolumeSlider();
            S_PauseWhenGameUnfocused = UI::Checkbox("Pause audio when the game is unfocused", S_PauseWhenGameUnfocused);
            S_JustSilenceMovieTitles = UI::Checkbox("Silence fake movie titles?", S_JustSilenceMovieTitles);
            S_VoiceLinesInSpec = UI::Checkbox("Play Voice Lines when Spectating", S_VoiceLinesInSpec);
            S_TitleGagsInSpec = UI::Checkbox("Play Title Gags when Spectating", S_TitleGagsInSpec);
            UI::EndMenu();
        }
    }

    void DrawVolumeSlider(bool showLabel = true) {
        volSetting = UI::SliderFloat(showLabel ? "Volume##slider" : "##volsldier", volSetting * 100., 0, 100) / 100.;
    }

    void DrawAudioTest() {
        if (UI::Button("Play audio test")) {
            ToggleAudioTest();
        }
    }

    void ToggleAudioTest() {
        if (vtAudio is null) return;
        if (vtAudio.isPlaying) {
            StopAudioTest();
            return;
        }
        PlayAudioTest();
    }

    void PlayAudioTest() {
        ClearSubtitleAnimations();
        VolumeOnPluginStart();
        @vtSubtitlesAnim = SubtitlesAnim(vtFile, false);
        AddSubtitleAnimation(vtSubtitlesAnim);
        vtAudio.Play();
    }

    void StopAudioTest() {
        ClearSubtitleAnimations();
        if (vtAudio is null) return;
        vtAudio.StartFadeOutLoop();
    }

    void RenderSubtitlesVolumeIfNotActive() {
        if (g_Active) return;

        if (vtSubtitlesAnim !is null) {
            if (vtSubtitlesAnim.Update()) {
                vtSubtitlesAnim.Draw();
            } else {
                if (subtitleAnims.Length > 0 && subtitleAnims[0] is vtSubtitlesAnim) {
                    subtitleAnims.RemoveAt(0);
                }
                @vtSubtitlesAnim = null;
            }
        }
    }

}
