
class TextOverlayAnim : Animation {
    // stages: fade in, hold (at 0.5), fade out
    float t = 0.0;
    float fadeDuration = 500.0;
    float prog = 0.0;
    float maxWidth = g_screen.x * .5;
    string text;
    AudioChain@ audio;
    uint playingStartTime = 0;

    TextOverlayAnim(const string &in triggerName, const string &in text, AudioChain@ audio = null) {
        super(triggerName);
        this.text = text;
        @this.audio = audio;
        startnew(CoroutineFunc(AwaitVoiceLinesEndedThenPlayAudio));
    }

    void AwaitVoiceLinesEndedThenPlayAudio() {
        while (IsVoiceLinePlaying()) yield();
        SetTextOverlayAudio(audio);
        playingStartTime = Time::Now;
    }

    bool fadingOut = false;
    bool fadingIn = true;

    string ToString(int i = -1) override {
        return "TextOverlayAnim: " + name + " / t = " + t + " / prog = " + prog + " / fadingOut = " + fadingOut + " / fadingIn = " + fadingIn + " / text = " + text + " / StillInTrigger = " + StillInTrigger + " / NotInTrigger = " + NotInTrigger;
    }

    bool get_StillInTrigger() {
        return currTriggerHit !is null && currTriggerHit.name == name;
    }

    bool get_NotInTrigger() {
        return !StillInTrigger;
        // return currTriggerHit is null || currTriggerHit.name != triggerName;
    }

    bool Update() override {
        if (fadingIn) {
            return UpdateFadeIn();
        }
        if (fadingOut || !StillInTrigger) {
            if (!fadingOut) audio.StartFadeOutLoop();
            fadingOut = true;
            return UpdateFadeOut() || IsVoiceLinePlaying();
        }
        return true;
    }

    bool UpdateFadeIn() {
        t += g_DT;
        if (t >= fadeDuration) {
            prog = 1.0;
            t = fadeDuration;
            fadingIn = false;
            return true;
        }
        prog = t / fadeDuration;
        return true;
    }

    bool UpdateFadeOut() {
        t -= g_DT;
        prog = t / fadeDuration;
        if (t <= 0.0) {
            t = 0.0;
            prog = 0.0;
            return IsVoiceLinePlaying();
        }
        return true;
    }

    vec2 textSize;
    vec2 Draw() override {
        if (t == 0.0) {
            return vec2(0.0, 0.0);
        }
        float alpha = prog;
        float fs = g_screen.y / 40.0;
        vec2 centerPos = g_screen * vec2(.5, .65);
        maxWidth = g_screen.x * .5;

        nvg::Reset();
        nvg::FontFace(f_Nvg_ExoMediumItalic);
        nvg::FontSize(fs);
        nvg::TextLineHeight(1.2);
        auto textSize = nvg::TextBoxBounds(maxWidth, text);

        nvg::GlobalAlpha(alpha);

        float round = g_screen.y * .03;
        vec2 pad = vec2(round / 2.);
        auto yPosOff = g_screen.y * .1 * (1.0 - alpha);
        auto textTL = centerPos - textSize * .5 + vec2(0, yPosOff);
        auto tl = textTL + vec2(round / 5., fs * -0.65) - pad;
        auto bgSize = textSize + vec2(round) + pad * 2.0;
        nvg::BeginPath();
        nvg::FillColor(cBlack85);
        nvg::RoundedRect(tl, bgSize, round);
        nvg::Fill();
        nvg::ClosePath();
        nvg::BeginPath();
        nvg::FillColor(cWhite);
        nvg::FontFace(f_Nvg_ExoMediumItalic);
        nvg::FontSize(fs);
        nvg::TextAlign(nvg::Align::Top | nvg::Align::Center);
        nvg::TextBox(textTL, maxWidth, text);
        nvg::ClosePath();
        return bgSize;
    }
}

TextOverlayAnim@ Jave_TextOverlayAnim() {
    // dev_trace("adding monument overlay anim: Jave");
    return TextOverlayAnim("Jave Monument", MONUMENT_JAVE, AudioChain({"after_months_of_grinding_the_tower_jave_finally_managed_to_secure_the_deep_dip_world_record_on_o_2.mp3"}));
}

TextOverlayAnim@ Bren_TextOverlayAnim() {
    // dev_trace("adding monument overlay anim: Bren");
    return TextOverlayAnim2("Bren Monument", MONUMENT_BREN, 29350, MONUMENT_BREN_CLOVER, 22400,
        AudioChain({"following_a_spectacular_battle_bren_managed_to_be_the_first_to_conquer_deep_dip_on_november_23rd_3.mp3",
            "monument_bren_correction_12_finishers.mp3"}));
}


class TextOverlayAnim2 : TextOverlayAnim {
    string text2;
    uint audio1Len;
    uint audio2Len;
    SubtitlesAnim@ cloverSubs;

    TextOverlayAnim2(const string &in triggerName, const string &in text, uint audio1Len, const string &in text2, uint audio2Len, AudioChain@ audio = null) {
        super(triggerName, text, audio);
        this.text2 = text2;
        this.audio1Len = audio1Len;
        this.audio2Len = audio2Len;
        @cloverSubs = SubtitlesAnim("subtitles/clover.txt", false);
    }
    //playingStartTime

    bool triggered2 = false;
    uint lastUpdate = 0;
    bool Update() override {
        if (IsPauseMenuOpen(S_PauseWhenGameUnfocused)) {
            if (lastUpdate > 0) {
                playingStartTime += (Time::Now - lastUpdate);
            }
            lastUpdate = Time::Now;
            return true;
        }
        auto r = TextOverlayAnim::Update();
        if (!r) {
            dev_trace('TextOverlayAnim2: TextOverlayAnim::Update() returned false');
            triggered2 = true;
            audio.StartFadeOutLoop();
            cloverSubs.Reset();
        }
        if (!triggered2 && playingStartTime > 0 && (Time::Now - playingStartTime) > audio1Len) {
            triggered2 = true;
            startnew(CoroutineFunc(this.BeginAudio2Subs));
        }
        lastUpdate = Time::Now;
        return r;
    }

    void BeginAudio2Subs() {
        dev_trace('TextOverlayAnim2: BeginAudio2Subs');
        AddSubtitleAnimation(cloverSubs);
        while (Time::Now < audio2Len + playingStartTime + audio1Len + 1000 && StillInTrigger) yield();
        dev_trace('TextOverlayAnim2: Ending Audio2Subs');
        cloverSubs.Reset();
        audio.StartFadeOutLoop();
    }
}


AudioChain@ textOverlayAudio;

void SetTextOverlayAudio(AudioChain@ newAudio) {
    if (textOverlayAudio !is null) {
        textOverlayAudio.StartFadeOutLoop();
    }
    @textOverlayAudio = newAudio;
    if (newAudio !is null) {
        newAudio.PlayDelayed(200);
    }
}

void RemoveTextOverlayAudioIfMatching(AudioChain@ audio) {
    if (textOverlayAudio is audio) {
        SetTextOverlayAudio(null);
    }
}
