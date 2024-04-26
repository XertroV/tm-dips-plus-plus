const uint PB_ANIM_DURATION = 8000;


class ProgressAnim : Animation {
    int startTime = 0;
    int endTime = 1000;
    int duration;
    int delta;
    int time;
    int lastUpdate;
    int progressMs;
    bool pauseWhenMenuOpen;
    float t;
    float gAlpha;
    uint fadeIn = 500;
    uint fadeOut = 500;

    ProgressAnim(const string &in name, nat2 startEndMsTimes) {
        super(name);
        startTime = startEndMsTimes.x;
        endTime = startEndMsTimes.y;
        duration = endTime - startTime;
    }

    string ToString(int i) override {
        return Animation::ToString(i) + " t=" + t + " progressMs=" + progressMs + " gAlpha: " + gAlpha;
    }

    void OnEndAnim() override {
        lastUpdate = 0;
        time = 0;
        delta = 0;
        progressMs = 0;
    }

    bool Update() override {
        time = Time::Now;
        if (lastUpdate == 0) {
            delta = 0;
        } else {
            delta = time - lastUpdate;
        }
        if (!pauseWhenMenuOpen || !IsPauseMenuOpen()) {
            progressMs += delta;
            t = Math::Clamp(float(progressMs - startTime) / float(endTime - startTime), 0., 1.);
            UpdateInner();
        }
        lastUpdate = time;
        return progressMs < endTime;
    }

    void UpdateInner() {
        // override this
    }
}


class PersonalBestStatusAnim : ProgressAnim {
    PlayerState@ player;

    PersonalBestStatusAnim(PlayerState@ player) {
        super("PB Status Anim", nat2(0, PB_ANIM_DURATION));
        @this.player = player;
    }

    void UpdateInner() override {
        // progressMs = 1500;
        gAlpha = progressMs < fadeIn
            ? float(progressMs) / fadeIn
            : duration - progressMs <= fadeOut
                ? float(duration - progressMs) / fadeOut
                : 1.;
    }

    string pbText;
    vec2 pos;
    vec2 tl;
    vec2 textSize;
    float charWidth;
    vec4 fullRect;
    uint currCharIx;
    uint nbChars;
    float heightOffset;

    vec2 Draw() override {
        nvg::Reset();
        nvg::GlobalAlpha(gAlpha);

        // nvg::BeginPath();
        // nvg::MoveTo(vec2(.5, 0) * g_screen);
        // nvg::LineTo(vec2(.5, 1) * g_screen);
        // nvg::MoveTo(vec2(0, .5) * g_screen);
        // nvg::LineTo(vec2(1, .5) * g_screen);
        // nvg::StrokeColor(cWhite);
        // nvg::StrokeWidth(3);
        // nvg::Stroke();

        // nvg::BeginPath();
        // nvg::Rect(tl, textSize);
        // nvg::Stroke();

        nvg::BeginPath();

        pbText = Text::Format("NEW PB %.0f m", Stats::GetPBHeight());
        nbChars = pbText.Length;
        textSize.y = S_PBAlertFontSize * Minimap::vScale;
        charWidth = textSize.y * .8;
        textSize.x = charWidth * nbChars;
        pos = vec2(0.5, 0.1) * g_screen;
        tl = pos - textSize / 2.;
        fullRect = vec4(tl, textSize);
        float heightOffsetMag = textSize.y / 3.;
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        nvg::FontSize(textSize.y);
        nvg::FontFace(f_Nvg_ExoExtraBold);


        vec4 activeRect;
        for (currCharIx = 0; currCharIx < pbText.Length; currCharIx++) {
            if (pbText[currCharIx] == 0x20) {
                continue;
            }
            heightOffset = Math::Sin((t * -70. + float(currCharIx) / nbChars * 5.)) * heightOffsetMag;
            // activeRect = fullRect;
            activeRect = vec4(tl.x + charWidth * currCharIx - 20, tl.y + heightOffset, charWidth + 40., textSize.y);
            pbNotificationTextFill.RunFillAnim(fullRect + vec4(0, heightOffset, 0, 0), activeRect, CoroutineFunc(this.DrawCurrChar), true, true);
        }

        nvg::ClosePath();
        nvg::GlobalAlpha(1.0);

        return vec2(0);
    }

    void DrawCurrChar() {
        // nvg::Fill();
        // todo: height offset (sinusoidal)
        nvg::Text(pos + vec2(charWidth * float(currCharIx) - textSize.x / 2. + charWidth / 2., heightOffset), pbText.SubStr(currCharIx, 1));
        // nvg::Text(pos, pbText);
    }
}
