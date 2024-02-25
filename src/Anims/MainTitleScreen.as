uint debug_srcNonce = 0;

class MainTitleScreenAnim : FloorTitleGeneric {
    string secLine;
    AudioChain@ audio;

    bool started = false;

    MainTitleScreenAnim(const string &in titleName, const string &in secLine, AudioChain@ audioArg) {
        auto ps = GetPosSize();
        super(titleName, pos, size);
        this.secLine = secLine;
        @this.audio = audioArg;
        auto sampleNb = debug_srcNonce % 6;
        if (this.audio is null) {
            @this.audio = AudioChain({
                Audio_GetPath(DEF_TITLE_AUDIO),
                sampleNb == 0 ? Audio_GetPath("what_we_dip_in_the_shadows.mp3")
                : sampleNb == 1 ? Audio_GetPath("tomorrowwhenthedipsbegan.mp3")
                : sampleNb == 2 ? Audio_GetPath("truediptective.mp3")
                : sampleNb == 3 ? Audio_GetPath("todipornottodipthatisthequestion.mp3")
                : sampleNb == 4 ? Audio_GetPath("whoframeddeeperdippit.mp3")
                // : sampleNb == 4 ? Audio_GetPath("theredipening.mp3")
                : Audio_GetPath("withvindeepsalastripledip.mp3")
            });
            this.secLine = sampleNb == 0 ? "What We Dip in the Shadows"
                : sampleNb == 1 ? "Tomorrow, When the Dips Began"
                : sampleNb == 2 ? "True Diptective"
                : sampleNb == 3 ? "To Dip or Not to Dip, That is the Question"
                : sampleNb == 4 ? "Who Framed Deeper Dippit?"
                // : sampleNb == 4 ? "The Redipening"
                : "With Vin Deepsal as Triple Dip";
        }
        debug_srcNonce++;
        // sub 0.8 to account for starting to play early
        this.SetStageTime(MainTextStageIx, this.audio.totalDuration - 0.8);
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
        auto ps = GetPosSize();
        pos = ps.xy;
        size = ps.zw;
        if (!started) {
            audio.Play();
            started = true;
        }
        return ret;
    }


    float titleHeight = 0.45;
    float secHeight = 0.3;
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

        nvg::FontFace(f_Nvg_ExoRegularItalic);
        // want to have title as 45% height, and subtitle as 30% height, evenly spaced
        float gapH = size.y * (1.0 - titleHeight - secHeight) / 5.0;
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
        DrawTextWithShadow(vec2(currPos.x + size.x / 2, currPos.y + size.y * titleHeight / 2.0), titleName, textColor, fontSize * 0.05);
        currPos.y += size.y * (titleHeight) + gapH;
        // PopScissor();

        fontSize = size.y * secHeight;
        nvg::FontSize(fontSize);
        textSize = nvg::TextBounds(secLine);
        if (textSize.x > (size.x - 20.0)) {
            fontSize *= (size.x - 20.0) / textSize.x;
            nvg::FontSize(fontSize);
        }
        // PushScissor(pos + vec2(slide2X, 0), size + vec2());
        DrawTextWithShadow(vec2(currPos.x + size.x / 2, currPos.y + size.y * secHeight / 2.0), secLine, textColor, fontSize * 0.03);
        // PopScissor();
    }
}


float ClampScale(float t, float start, float end) {
    if (t < start) return 0;
    if (t > end) return 1;
    return (t - start) / (end - start);
}
