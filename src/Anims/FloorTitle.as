class FloorTitleGeneric : Animation {
    string titleName;
    NvgFillable@[] colors = {
        NvgFillableColor(vec4(.153, .588, .733, 1.0)),
        NvgFillableColor(vec4(1.0)),
        NvgFillableColor(vec4(.153, .588, .733, .5)),
        NvgFillableColor(vec4(1.0))
    };
    // kf -1 (t=0): r1 starts, 0: r1 full, 1: r1 ends r2 full, 2: r2 ends, 3: 3rd rect starts, 4: 3rd rect full, 5: 3rd rect ends
    float[] keyframes = {
        0.4,
        0.8,
        1.2,
        6.6,
        7.0,
        7.4
    };

    FloorTitleGeneric(const string &in titleName) {
        super("Floor Title Generic: " + titleName);
        this.titleName = titleName;
    }

	bool Update() override {
        return true;
	}

    NvgFillable@ testFillable = NvgFillableLinGrad({
        vec4(1.0, 0.0, 0.0, 1.0),
        vec4(0.0, 1.0, 0.0, 1.0),
        vec4(0.0, 0.0, 1.0, 1.0),
        vec4(1.0, 1.0, 0.0, 1.0),
        vec4(1.0, 0.0, 1.0, 1.0),
        vec4(0.0, 1.0, 1.0, 1.0),
        vec4(1.0, 1.0, 1.0, 1.0)
    }, {0.0, 0.1, 0.3, 0.4, 0.6, 0.7, 1.0});

	vec2 Draw() override {
        nvg::Reset();
        nvg::BeginPath();
        nvg::Rect(100, 100, 300, 500);
        testFillable.RunFill(vec4(100, 100, 300, 500));
        nvg::ClosePath();
        return vec2(0, 0);
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

class NvgFillableLinGrad : NvgFillable {
    // the color at each boundary in the gradient
    vec4[]@ colors;
    // 0.0 to 1.0, should correspond to how far along the linear gradient they are. first and last MUST be 0.0 and 1.0
    float[]@ positions;

    NvgFillableLinGrad(vec4[]@ colors, float[]@ positions) {
        if (colors.Length != positions.Length) throw("NvgFillableLinGrad: colors and positions must be the same length");
        if (colors.Length < 2) throw("NvgFillableLinGrad: colors and positions must have at least 2 elements");
        @this.colors = colors;
        @this.positions = positions;
        this.isLinearGradient = true;
    }

    void RunFill(vec4 full_rect) override {
        float start, stop;
        vec4 rect;
        for (uint i = 0; i < colors.Length - 1; i++) {
            // between 0 and 1
            start = positions[i];
            stop = positions[i + 1];
            rect = vec4(full_rect.x, Math::Round(full_rect.y + full_rect.w * start), full_rect.z, Math::Round(full_rect.w * (stop - start)));
            nvg::Scissor(rect.x, rect.y, rect.z, rect.w);
            nvg::FillPaint(nvg::LinearGradient(rect.xy, vec2(rect.x, rect.y + rect.w), colors[i], colors[i + 1]));
            nvg::Fill();
            nvg::ResetScissor();
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
