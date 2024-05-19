// borrowed from multidash borrowed from Dashboard

enum KeyboardShape
{
	Rectangle,
	Ellipse,
	Compact,
}

[Setting hidden]
bool S_ShowInputsWhenUIHidden = false;

[Setting hidden]
bool S_ShowSteeringPct = true;

[Setting hidden]
float S_InputsHeight = 0.147;

[Setting hidden]
float S_InputsPosX = 0.5;

[Setting hidden]
float S_InputsPosY = 0.03;

[Setting hidden]
KeyboardShape Setting_Keyboard_Shape = KeyboardShape::Rectangle;

[Setting hidden]
vec4 Setting_Keyboard_EmptyFillColor = vec4(0, 0, 0, 0.7f);

[Setting hidden]
float Setting_Keyboard_BorderWidth = 1.0f;

[Setting hidden]
float Setting_Keyboard_BorderRadius = 2.0f;

// [Setting hidden]
// float Setting_Keyboard_Spacing = 10.0f;

[Setting hidden]
float Setting_Keyboard_InactiveAlpha = 0.4f;

void DrawInputsSettingsMenu() {
    S_ShowInputsWhenUIHidden = UI::Checkbox("Show when UI is hidden", S_ShowInputsWhenUIHidden);
    S_ShowSteeringPct = UI::Checkbox("Show steering percentage", S_ShowSteeringPct);
    S_InputsHeight = UI::SliderFloat("Height", S_InputsHeight, 0.01, 0.3);
    auto iPos = UI::SliderFloat2("Position", vec2(S_InputsPosX, S_InputsPosY), 0., 1.);
    S_InputsPosX = iPos.x;
    S_InputsPosY = iPos.y;
    if (UI::BeginCombo("Shape", tostring(Setting_Keyboard_Shape))) {
        if (UI::Selectable("Rectangle", Setting_Keyboard_Shape == KeyboardShape::Rectangle)) Setting_Keyboard_Shape = KeyboardShape::Rectangle;
        if (UI::Selectable("Ellipse", Setting_Keyboard_Shape == KeyboardShape::Ellipse)) Setting_Keyboard_Shape = KeyboardShape::Ellipse;
        if (UI::Selectable("Compact", Setting_Keyboard_Shape == KeyboardShape::Compact)) Setting_Keyboard_Shape = KeyboardShape::Compact;
        UI::EndCombo();
    }
    Setting_Keyboard_EmptyFillColor = UI::InputColor4("Empty Fill Color", Setting_Keyboard_EmptyFillColor);
    Setting_Keyboard_BorderWidth = UI::SliderFloat("Border Width", Setting_Keyboard_BorderWidth, 0., 10.);
    Setting_Keyboard_BorderRadius = UI::SliderFloat("Border Radius", Setting_Keyboard_BorderRadius, 0., 50.);
    Setting_Keyboard_InactiveAlpha = UI::SliderFloat("Inactive Alpha", Setting_Keyboard_InactiveAlpha, 0., 1.);
}


namespace Inputs {
    float padding = -1;

    vec4 keyCol = vec4(1, 0.2f, 0.6f, 1);
    vec4 strokeCol = vec4(1, 1, 1, 1);

    void DrawInputs(CSceneVehicleVisState@ vis, const vec4 &in col, const vec2 &in size) {
        keyCol = col;
        strokeCol = (col + vec4(1, 1, 1, .8)) / 2.;
        if (padding < 0) padding = float(Draw::GetHeight()) * 0.004;
        // float _padding =

        float steerLeft = vis.InputSteer < 0 ? Math::Abs(vis.InputSteer) : 0.0f;
        float steerRight = vis.InputSteer > 0 ? vis.InputSteer : 0.0f;

        vec2 keySize = vec2((size.x - padding * 2) / 3, (size.y - padding) / 2);
        vec2 sideKeySize = keySize;

        vec2 upPos = vec2(keySize.x + padding, 0);
        vec2 downPos = vec2(keySize.x + padding, keySize.y + padding);
        vec2 leftPos = vec2(0, keySize.y + padding);
        vec2 rightPos = vec2(keySize.x * 2 + padding * 2, keySize.y + padding);

        nvg::Translate(size * -1);
        RenderKey(upPos, keySize, Icons::AngleUp, vis.InputGasPedal);
        RenderKey(downPos, keySize, Icons::AngleDown, vis.InputIsBraking ? 1.0f : vis.InputBrakePedal);

        RenderKey(leftPos, sideKeySize, Icons::AngleLeft, steerLeft, -1, S_ShowSteeringPct);
        RenderKey(rightPos, sideKeySize, Icons::AngleRight, steerRight, 1, S_ShowSteeringPct);
    }

    void RenderKey(const vec2 &in pos, const vec2 &in size, const string &in text, float value, int fillDir = 0, bool drawPct = false) {
        // float orientation = Math::ToRad(float(int(ty)) * Math::PI / 2.0);
        vec4 borderColor = strokeCol;
        if (fillDir == 0) {
            borderColor.w *= Math::Abs(value) > 0.1f ? 1.0f : Setting_Keyboard_InactiveAlpha;
        } else {
            borderColor.w *= Math::Lerp(Setting_Keyboard_InactiveAlpha, 1.0f, value);
        }

        nvg::BeginPath();
        nvg::StrokeWidth(Setting_Keyboard_BorderWidth);

        switch (Setting_Keyboard_Shape) {
            case KeyboardShape::Rectangle:
            case KeyboardShape::Compact:
                nvg::RoundedRect(pos.x, pos.y, size.x, size.y, Setting_Keyboard_BorderRadius);
                break;
            case KeyboardShape::Ellipse:
                nvg::Ellipse(pos + size / 2, size.x / 2, size.y / 2);
                break;
        }

        nvg::FillColor(Setting_Keyboard_EmptyFillColor);
        nvg::Fill();

        if (fillDir == 0) {
            if (Math::Abs(value) > 0.1f) {
                nvg::FillColor(keyCol);
                nvg::Fill();
            }
        } else if (value > 0) {
            if (fillDir == -1) {
                float valueWidth = value * size.x;
                nvg::Scissor(size.x - valueWidth, pos.y, valueWidth, size.y);
            } else if (fillDir == 1) {
                float valueWidth = value * size.x;
                nvg::Scissor(pos.x, pos.y, valueWidth, size.y);
            }
            nvg::FillColor(keyCol);
            nvg::Fill();
            nvg::ResetScissor();
        }

        nvg::StrokeColor(borderColor);
        nvg::Stroke();

        drawPct = drawPct && value > 0.005 && value < 0.995;
        auto fontSize = size.x / (drawPct ? 4.0 : 2.0);

        nvg::BeginPath();
        nvg::FontFace(f_Nvg_ExoRegular);
        nvg::FontSize(fontSize);
        nvg::FillColor(borderColor);
        nvg::TextAlign(nvg::Align::Middle | nvg::Align::Center);
        nvg::TextBox(pos.x, pos.y + size.y / 2, size.x, drawPct ? Text::Format("%.0f%%", value * 100.) : text);
    }
}
