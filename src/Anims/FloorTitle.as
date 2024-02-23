NvgFillable@ testFillable = NvgFillableLinGradY({
    vec4(1.0, 0.0, 0.0, 1.0),
    vec4(0.0, 1.0, 0.0, 1.0),
    vec4(0.0, 0.0, 1.0, 1.0),
    vec4(1.0, 1.0, 0.0, 1.0),
    vec4(1.0, 0.0, 1.0, 1.0),
    vec4(0.0, 1.0, 1.0, 1.0),
    vec4(1.0, 1.0, 1.0, 1.0)
}, {0.0, 0.1, 0.3, 0.4, 0.6, 0.7, 1.0});

NvgFillable@ subtleBlackGradientBg = NvgFillableLinGradY({
    vec4(0),
    vec4(0, 0, 0, .4),
    vec4(0, 0, 0, .85),
    vec4(0, 0, 0, .85),
    vec4(0, 0, 0, .4),
    vec4(0)
}, {0.0, 0.1, 0.3, 0.6, 0.9, 1.0});
class FloorTitleGeneric : Animation {
    string titleName;
    NvgFillable@[] colors = {
        NvgFillableColor(vec4(.153, .588, .733, 1.0)),
        NvgFillableColor(vec4(1.0)),
        // NvgFillableColor(vec4(0, 0, 0, .4)),
        // NvgFillableColor(vec4(.153, .588, .733, .5)),
        // testFillable,
        subtleBlackGradientBg,
        NvgFillableColor(vec4(1.0))
    };
    // kf -1 (t=0): r1 starts, 0: r1 full, 1: r1 ends r2 full, 2: r2 ends, 3: 3rd rect starts, 4: 3rd rect full, 5: 3rd rect ends
    float[] keyframes = {
        0.4,
        0.8,
        1.2,
        1.2,
        6.6,
        7.0,
        7.4
    };

    vec2 pos;
    vec2 size;
    float durationSec;
    float currTime;

    FloorTitleGeneric(const string &in titleName, vec2 pos, vec2 size) {
        super("Floor Title Generic: " + titleName);
        this.titleName = titleName;
        this.pos = pos;
        this.size = size;
        this.durationSec = keyframes[keyframes.Length - 1];
    }

    void SetStageTime(uint stage, float time) {
        float origTime = keyframes[stage];
        keyframes[stage] = time;
        float delta = time - origTime;
        for (uint i = stage + 1; i < keyframes.Length; i++) {
            keyframes[i] += delta;
        }
        durationSec = keyframes[keyframes.Length - 1];
    }

    uint stage;
    float stageStartTime;
    float stageEndTime;
    float stageT;

	bool Update() override {
        // frame 1 glitch?
        currTime += g_DT * 0.001;
        for (uint i = stage; i < keyframes.Length; i++) {
            if (currTime >= keyframes[i]) {
                stageStartTime = keyframes[i];
                stage = i + 1;
            } else {
                stageEndTime = keyframes[i];
                break;
            }
        }
        // if (stage == keyframes.Length - 1) {
        //     stageT = 1.0;
        //     return false;
        // }
        if (stageEndTime == stageStartTime) {
            stageT = 0.0;
        } else {
            stageT = Math::Clamp((currTime - stageStartTime) / (stageEndTime - stageStartTime), 0.0, 1.0);
        }
        // print("currTime: " + currTime + ", stage: " + stage + ", stageT: " + stageT);
        return currTime <= durationSec;
	}

	vec2 Draw() override {
        nvg_Reset();
        // nvg::Scissor(pos.x, pos.y, size.x, size.y);
        PushScissor(vec4(pos, size));

        if (stage < 1) DrawStage1(stageT);
        else if (stage < 2) DrawStage2(stageT);
        else if (stage < 3) DrawStage3(stageT);
        else if (stage < 4) DrawStage4(stageT);
        else if (stage < 5) DrawStage5(stageT);
        else if (stage < 6) DrawStage6(stageT);
        else if (stage < 7) DrawStage7(stageT);
        else {
            NotifyWarning("FloorTitleGeneric: stage out of bounds: " + stage);
        }
        PopScissor();
        return size;
	}

    /*
        stage1: r1 animates in from left
        stage2: r2 animates in from left (r1 @ 1.0)
        stage3: r2 animates out to right (r3 @ 0.0)
        stage4: r3 is static
        stage5: r4 animates in from left (r3 @ 1.0)
        stage6: r4 animates out to right
    */

    vec4 rect;

    void DrawStage1(float t) {
        nvg::BeginPath();
        rect = vec4(pos.x - size.x * (1.0 - t), pos.y, size.x, size.y);
        nvg::Rect(rect.xy, rect.zw);
        colors[0].RunFill(rect);
        nvg::ClosePath();
    }

    void DrawStage2(float t) {
        DrawStage1(1.0);

        nvg::BeginPath();
        rect = vec4(pos.x - size.x * (1.0 - t), pos.y, size.x, size.y);
        nvg::Rect(rect.xy, rect.zw);
        colors[1].RunFill(rect);
        nvg::ClosePath();
    }

    void DrawStage3(float t) {
        DrawStage4(0.0);

        nvg::BeginPath();
        rect = vec4(pos.x + size.x * t, pos.y, size.x, size.y);
        nvg::Rect(rect.xy, rect.zw);
        colors[1].RunFill(rect);
        nvg::ClosePath();
    }

    // we skip this
    void DrawStage4(float t) {
        DrawStage5(0.0);
    }

    uint MainTextStageIx = 4;
    void DrawStage5(float t) {
        nvg::BeginPath();
        rect = vec4(pos.x, pos.y, size.x, size.y);
        nvg::Rect(rect.xy, rect.zw);
        colors[2].RunFill(rect);
        nvg::FillColor(vec4(1.0));
        this.DrawText(t);
        nvg::ClosePath();
    }

    void DrawStage6(float t) {
        DrawStage5(1.0);

        nvg::BeginPath();
        rect = vec4(pos.x - size.x * (1.0 - t), pos.y, size.x, size.y);
        nvg::Rect(rect.xy, rect.zw);
        colors[3].RunFill(rect);
        nvg::ClosePath();
    }

    void DrawStage7(float t) {
        // DrawStage5(1.0);

        nvg::BeginPath();
        rect = vec4(pos.x + size.x * t, pos.y, size.x, size.y);
        nvg::Rect(rect.xy, rect.zw);
        colors[3].RunFill(rect);
        nvg::ClosePath();
    }

    // can be overridden
    void DrawText(float t) {
        nvg::FontFace(f_Nvg_ExoRegularItalic);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        auto fontSize = size.y / 2.;
        nvg::FontSize(fontSize);
        auto textSize = nvg::TextBounds(titleName);
        if (textSize.x > (size.x - 20.0)) {
            fontSize *= (size.x - 20.0) / textSize.x;
            nvg::FontSize(fontSize);
        }
        nvg::FontFace(f_Nvg_ExoRegularItalic);
        nvg::Text(pos.x + size.x / 2, pos.y + size.y / 2, titleName);
    }

    string ToString(int i) override {
        return "FloorTitleGeneric: " + titleName + ", stage: " + stage + ", stageT: " + stageT + ", currTime: " + currTime + " / " + durationSec;
    }

    void DebugSlider() {
        currTime = UI::SliderFloat("Time##"+id, currTime, 0.0, durationSec);
    }
}


class NvgFillable {
    bool isColor;
    bool isLinearGradient;

    // calls a combination of nvg::FillColor and nvg::FillPaint
    void RunFill(vec4 rect) {
        throw("NvgFillable: RunFill must be overridden");
    }
}

class NvgFillableLinGradY : NvgFillable {
    // the color at each boundary in the gradient
    vec4[]@ colors;
    // 0.0 to 1.0, should correspond to how far along the linear gradient they are. first and last MUST be 0.0 and 1.0
    float[]@ positions;

    NvgFillableLinGradY(vec4[]@ colors, float[]@ positions) {
        if (colors.Length != positions.Length) throw("NvgFillableLinGrad: colors and positions must be the same length");
        if (colors.Length < 2) throw("NvgFillableLinGrad: colors and positions must have at least 2 elements");
        if (positions[0] != 0.0 || positions[positions.Length - 1] != 1.0) throw("NvgFillableLinGrad: positions must start at 0.0 and end at 1.0");
        @this.colors = colors;
        @this.positions = positions;
        this.isLinearGradient = true;
    }

    void RunFill(vec4 full_rect) override {
        float start, stop;
        vec4 rect;
        float lastEndPos = 0.0;
        for (uint i = 0; i < colors.Length - 1; i++) {
            // between 0 and 1
            start = positions[i];
            stop = positions[i + 1];
            // lastEndPos ~ full_rect.w * start
            rect = vec4(full_rect.x, full_rect.y + lastEndPos, full_rect.z, Math::Round(full_rect.w * stop - lastEndPos));
            lastEndPos += rect.w;
            PushScissor(rect);
            nvg::FillPaint(nvg::LinearGradient(rect.xy, vec2(rect.x, rect.y + rect.w), colors[i], colors[i + 1]));
            nvg::Fill();
            PopScissor();
        }
        // nvg::Fill();
    }
}

class NvgFillableColor : NvgFillable {
    vec4 color;
    NvgFillableColor(const vec4 &in color) {
        this.color = color;
        this.isColor = true;
    }

    void RunFill(vec4 rect) override {
        nvg::FillColor(color);
        nvg::Fill();
    }
}
