uint debug_srcNonce = 0;

class MainTitleScreenAnim : FloorTitleGeneric {
    string secLine;
    CollectionItem@ audioMain;
    CollectionItem@ audioSec;
    AudioChain@ audioChain;

    bool started = false;

    MainTitleScreenAnim(const string &in titleName, const string &in secLine, CollectionItem@ audioMain, CollectionItem@ audioSec) {
        auto pos = vec2(0, g_screen.y * 0.1);
        auto size = vec2(g_screen.x, g_screen.y * 0.3);
        super(titleName, pos, size);
        this.secLine = secLine;
        @this.audioMain = audioMain;
        @this.audioSec = audioSec;
        auto sampleNb = debug_srcNonce % 6;
        @audioChain = AudioChain({
            Audio_GetPath("deepdip2.mp3"),
            sampleNb == 0 ? Audio_GetPath("theredipening.mp3")
            : sampleNb == 1 ? Audio_GetPath("theyseemedippintheyhatinpatrollinandtyrnacatchmedeepanddippy.mp3")
            : sampleNb == 2 ? Audio_GetPath("thelegendofdeepdadiparinaoftime.mp3")
            : sampleNb == 3 ? Audio_GetPath("todipornottodipthatisthequestion.mp3")
            : sampleNb == 4 ? Audio_GetPath("dipsoutforharambe.mp3")
            // : sampleNb == 4 ? Audio_GetPath("theredipening.mp3")
            : Audio_GetPath("totaldipcall.mp3")
        });
        this.secLine = sampleNb == 0 ? "The Redipening"
            : sampleNb == 1 ? "They Seem Dippin', They Hatin', Patrollin' and Tryna Catch Me Deep and Dippy"
            : sampleNb == 2 ? "The Legend of Deepda - Diparina of Time"
            : sampleNb == 3 ? "To Dip or Not to Dip, That is the Question"
            : sampleNb == 4 ? "Dips Out for Harambe"
            // : sampleNb == 4 ? "The Redipening"
            : "Total Dipcall";
        debug_srcNonce++;
        this.SetStageTime(MainTextStageIx, audioChain.totalDuration);
    }

    bool Update() override {
        bool ret = FloorTitleGeneric::Update();
        return ret;
    }


    float titleHeight = 0.45;
    float secHeight = 0.3;
    vec4 textColor = vec4(1);

    void DrawText(float t) override {
        if (stage == MainTextStageIx && !started) {
            audioChain.Play();
            started = true;
        }
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
