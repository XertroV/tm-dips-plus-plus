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
    return nvg::TextBounds(text) + strokeWidth;
}
