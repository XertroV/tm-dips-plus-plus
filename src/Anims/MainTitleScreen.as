uint debug_srcNonce = 0;

class MainTitleScreenAnim : FloorTitleGeneric {
    string secLine;
    AudioChain@ audio;
    float reduceMainTimeBy;

    bool started = false;

    MainTitleScreenAnim(const string &in titleName, const string &in secLine, AudioChain@ audioArg, float reduceMainTimeBy = 0.8) {
        auto ps = GetPosSize();
        super(titleName, ps.xy, ps.zw);
        this.secLine = secLine;
        @this.audio = audioArg;
        dev_trace("Created main title anim: " + titleName + " / " + secLine);
        this.reduceMainTimeBy = reduceMainTimeBy;
        startnew(CoroutineFunc(this.SetStageTimesFromAudio));
    }

    MainTitleScreenAnim(const string &in titleName, AudioChain@ audio) {
        auto ps = GetPosSize();
        super(titleName, ps.xy, ps.zw);
        @this.audio = audio;
        titleHeight = 0.7;
        secHeight = 0.0;
        gapPartitions = 4;
    }

    ~MainTitleScreenAnim() {
        trace('destroying MainTitleScreenAnim: ' + titleName + " / " + secLine);
        if (audio !is null) {
            audio.StartFadeOutLoop();
        }
    }

    // only used with secondary lines
    void SetStageTimesFromAudio() {
        // sub 0.8 to account for starting to play early
        if (this.audio !is null) {
            trace('set stage time');
            while (this.audio.IsLoading) yield();
            this.SetStageTime(MainTextStageIx, this.audio.totalDuration - reduceMainTimeBy);
        }
    }

    vec4 GetPosSize() {
        float yTitleOff = 0;
        if (UI::IsOverlayShown()) {
            yTitleOff = Math::Round(22 * UI::GetScale());
        }
        return vec4(0, g_screen.y * 0.0 + yTitleOff, g_screen.x, g_screen.y * 0.15);
    }

    bool Update() override {
        bool ret = FloorTitleGeneric::Update();
        if (!ret) trace('main title update: false');
        auto ps = GetPosSize();
        pos = ps.xy;
        size = ps.zw;
        if (!started) {
            if (audio !is null) audio.Play();
            started = true;
        }
        return ret;
    }


    float titleHeight = 0.45;
    float secHeight = 0.3;
    // set to 4 to center title if no secHeight
    float gapPartitions = 5;
    vec4 textColor = vec4(1);

    void DrawText(float t) override {
        // start this a bit early to account for 'deep dip 2' in title.
        // special screens should override this.
        // float in1T = ClampScale(t, 0.05, 0.1);
        // float in2T = ClampScale(t, 0.1, 0.15);
        // float out1T = ClampScale(t, 0.85, 0.9);
        // float out2T = ClampScale(t, 0.9, 0.95);

        // if (t < in1T) return;

        // float slide1X = -size.x * (1.0 - in1T);
        // float slide2X = -size.x * (1.0 - in2T);
        // if (out1T > 0)
        //     slide1X = size.x * out1T;
        // if (out2T > 0)
        //     slide2X = size.x * out2T;

        nvg::FontFace(f_Nvg_ExoMediumItalic);
        // want to have title as 45% height, and subtitle as 30% height, evenly spaced
        float gapH = size.y * (1.0 - titleHeight - secHeight) / gapPartitions;
        auto currPos = pos + vec2(0, gapH * 2.0);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        auto fontSize = size.y * titleHeight;
        nvg::FontSize(fontSize);
        auto textSize = nvg::TextBounds(titleName);
        if (textSize.x > (size.x - 20.0)) {
            fontSize *= (size.x - 20.0) / textSize.x;
            nvg::FontSize(fontSize);
        }

        // PushScissor(pos + vec2(slide1X, 0), size + vec2());
        DrawTextWithShadow(vec2(currPos.x + size.x / 2, currPos.y + size.y * titleHeight / 2.0), titleName, textColor, fontSize * 0.06);
        currPos.y += size.y * (titleHeight) + gapH;
        // PopScissor();

        if (secHeight <= 0.0) return;

        fontSize = size.y * secHeight;
        nvg::FontSize(fontSize);
        textSize = nvg::TextBounds(secLine);
        if (textSize.x > (size.x - 20.0)) {
            fontSize *= (size.x - 20.0) / textSize.x;
            nvg::FontSize(fontSize);
        }
        // PushScissor(pos + vec2(slide2X, 0), size + vec2());
        DrawTextWithShadow(vec2(currPos.x + size.x / 2, currPos.y + size.y * secHeight / 2.0), secLine, textColor, fontSize * 0.05);
        // PopScissor();
    }
}


float ClampScale(float t, float start, float end) {
    if (t < start) return 0;
    if (t > end) return 1;
    return (t - start) / (end - start);
}
