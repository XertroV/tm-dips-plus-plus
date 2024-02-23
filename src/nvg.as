const double TAU = 6.28318530717958647692;

// this does not seem to be expensive
const float nTextStrokeCopies = 7;

vec2 DrawTextWithStroke(const vec2 &in pos, const string &in text, vec4 textColor = vec4(1), float strokeWidth = 2., vec4 strokeColor = vec4(0, 0, 0, 1)) {
    if (strokeWidth > 0.0) {
        nvg::FillColor(strokeColor);
        for (float i = 1; i < nTextStrokeCopies; i++) {
            float angle = TAU * float(i) / nTextStrokeCopies;
            vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * strokeWidth;
            nvg::Text(pos + offs, text);
            break;
        }
    }
    nvg::FillColor(textColor);
    nvg::Text(pos, text);
    // don't return with +strokeWidth b/c it means we can't turn stroke on/off without causing readjustments in the UI
    return nvg::TextBounds(text);
}

vec2 DrawTextWithShadow(const vec2 &in pos, const string &in text, vec4 textColor = vec4(1), float strokeWidth = 2., vec4 strokeColor = vec4(0, 0, 0, 1)) {
    if (strokeWidth > 0.0) {
        nvg::FillColor(strokeColor);
        float i = 1;
        float angle = TAU * float(i) / nTextStrokeCopies;
        vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * strokeWidth;
        nvg::Text(pos + offs, text);
    }
    nvg::FillColor(textColor);
    nvg::Text(pos, text);
    // don't return with +strokeWidth b/c it means we can't turn stroke on/off without causing readjustments in the UI
    return nvg::TextBounds(text);
}


void nvg_Reset() {
    nvg::Reset();
    if (scissorStack is null) return;
    scissorStack.RemoveRange(0, scissorStack.Length);
}

vec4[]@ scissorStack = {};
void PushScissor(const vec4 &in rect) {
    if (scissorStack is null) return;
    nvg::ResetScissor();
    nvg::Scissor(rect.x, rect.y, rect.z, rect.w);
    scissorStack.InsertLast(rect);
}
void PushScissor(vec2 xy, vec2 wh) {
    PushScissor(vec4(xy, wh));
}
void PopScissor() {
    if (scissorStack is null) return;
    if (scissorStack.IsEmpty()) {
        warn("PopScissor called on empty stack!");
        nvg::ResetScissor();
    } else {
        scissorStack.RemoveAt(scissorStack.Length - 1);
        if (!scissorStack.IsEmpty()) {
            vec4 last = scissorStack[scissorStack.Length - 1];
            nvg::ResetScissor();
            nvg::Scissor(last.x, last.y, last.z, last.w);
        } else {
            nvg::ResetScissor();
        }
    }
}
