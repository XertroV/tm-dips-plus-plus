
[Setting hidden]
bool S_WizardFinished = false;

bool g_WizardOpen = false;

namespace Wizard {
    void OnPluginLoad() {
        g_WizardOpen = !S_WizardFinished;
    }

    const int2 windowSize = int2(1100, 700);
    int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoResize | UI::WindowFlags::NoSavedSettings | UI::WindowFlags::AlwaysAutoResize;
    float ui_scale = UI_SCALE;

    void DrawWindow() {
        if (!g_WizardOpen) return;
        if (!G_Initialized) return;
        UI::SetNextWindowSize(windowSize.x, windowSize.y, UI::Cond::Always);
        auto pos = (int2(int(g_screen.x / ui_scale), int(g_screen.y / ui_scale)) - windowSize) / 2;
        UI::SetNextWindowPos(pos.x, pos.y, UI::Cond::Always);
        if (UI::Begin("D++ Wizard", g_WizardOpen, flags)) {
            DrawInner();
        }
        UI::End();
        if (!g_WizardOpen) {
            OnWizardClosed();
        }
    }

    void OnWizardClosed() {
        startnew(Volume::StopAudioTest);
    }

    uint wizardStep = 0;

    bool showVolumeSlider = false;
    vec2 avail;
    void DrawInner() {
        avail = UI::GetContentRegionAvail();
        if (ui_dips_pp_logo_sm is null) {
            UI::Dummy(vec2(avail.x / 2 - 40, avail.y * 0.5f - 10));
            UI::SameLine();
            UI::PushFont(f_DroidBigger);
            UI::Text("Loading...");
            UI::PopFont();
            return;
        }
        auto dl = UI::GetWindowDrawList();
        auto pos = (avail - dips_pp_logo_sm_dims) / 2;
        pos.y = 20.;
        dl.AddImage(ui_dips_pp_logo_sm, pos, pos + dips_pp_logo_sm_dims);
        UI::Dummy(vec2(avail.x, 40. + dips_pp_logo_sm_dims.y));
        DrawCenteredText("Welcome to the D++ Wizard!", f_DroidBigger);

        if (wizardStep == 0) {
            DrawStepZero();
        } else if (wizardStep == 1) {
            DrawStepOne();
        } else if (wizardStep == 2) {
            DrawStepTwo();
        } else if (wizardStep == 3) {
            DrawStepThree();
        } else if (wizardStep == 4) {
            DrawStepFour();
        } else {
            OnFinishWiz();
        }
    }


    void DrawStepZero() {
        DrawCenteredText("Please complete the volume test, now.", f_DroidBig);

        if (!showVolumeSlider) {
            if (DrawCenteredButton("Begin Volume Test", f_DroidBig)) {
                Volume::PlayAudioTest();
                showVolumeSlider = true;
            }
        } else if (Volume::IsAudioTestRunning()) {
            UI::Dummy(vec2(20.));
            UI::Dummy(vec2(avail.x * 0.125, 0));
            UI::SameLine();


            UI::SetNextItemWidth(avail.x * .75);
            UI::PushFont(f_DroidBig);
            Volume::DrawVolumeSlider(false);
            UI::Dummy(vec2(avail.x * .33, 0));
            UI::SameLine();
            S_PauseWhenGameUnfocused = UI::Checkbox("Pause audio when the game is unfocused", S_PauseWhenGameUnfocused);
            UI::PopFont();
            if (DrawCenteredButton("Skip Audio Test", f_DroidBig)) {
                Volume::StopAudioTest();
                wizardStep++;
            }
        } else if (DrawCenteredButton("Proceed", f_DroidBig)) {
            wizardStep++;
        }
    }

    void DrawStepOne() {
        DrawCenteredText("Do you like options? Would it make you feel better to change some?", f_DroidBig);
        UI::Dummy(vec2(avail.x * 0.125, 0));
        UI::SameLine();
        if (UI::BeginChild("##wizstep1", vec2(avail.x * .75, 0))) {
            S_EnableMainMenuPromoBg = UI::Checkbox("Enable Main Menu Background?", S_EnableMainMenuPromoBg);
            if (S_EnableMainMenuPromoBg) {
                // S_MenuBgTimeOfDay = ComboTimeOfDay("Main Menu Background Time of Day", S_MenuBgTimeOfDay);
                // S_MenuBgSeason = ComboSeason("Main Menu Background Season", S_MenuBgSeason);
            }
            S_ShowDDLoadingScreens = UI::Checkbox("Show DD2 Loading Screens?", S_ShowDDLoadingScreens);
            if (DrawCenteredButton("Proceed", f_DroidBig)) {
                wizardStep++;
            }
        }
        UI::EndChild();
    }

    void DrawStepTwo() {
        DrawCenteredText("I hope you liked that.", f_DroidBig);
        if (DrawCenteredButton("Yes, very fun.", f_DroidBig)) {
            wizardStep++;
        }
    }

    void DrawStepThree() {
        DrawCenteredText("Fantastic.", f_DroidBig);
        DrawCenteredText("Once you're in the map, you can change settings through the menu", f_DroidBig);
        DrawCenteredText("Or via the button in the lower right corner.", f_DroidBig);
        if (DrawCenteredButton("Can I go now?", f_DroidBig)) {
            wizardStep++;
        }
    }

    void DrawStepFour() {
        DrawCenteredText("... Yes, yes of course. I won't keep you any longer.", f_DroidBig);
        DrawCenteredText("Have fun!", f_DroidBig);
        UI::Dummy(vec2(avail.x * 0.45, 0));
        UI::SameLine();
        if (DrawCenteredButton(".....", f_DroidBig)) {
            OnFinishWiz();
        }
    }

    void OnFinishWiz() {
        S_WizardFinished = true;
        g_WizardOpen = false;
        wizardStep = 0;
        showVolumeSlider = false;
        Meta::SaveSettings();
    }
}



// vec2 lastCenteredTextBounds = vec2(100, 20);
void DrawCenteredText(const string &in msg, UI::Font@ font, bool alignToFramePadding = true) {
    UI::PushFont(font);
    auto bounds = Draw::MeasureString(msg, font, font.FontSize, 0.0f) * UI_SCALE;
    auto pos = (UI::GetWindowContentRegionMax() - bounds) / 2.;
    pos.y = UI::GetCursorPos().y;
    UI::SetCursorPos(pos);
    UI::Text(msg);
    // auto r = UI::GetItemRect();
    // lastCenteredTextBounds.x = r.z;
    // lastCenteredTextBounds.y = r.w;
    UI::PopFont();
}

bool DrawCenteredButton(const string &in msg, UI::Font@ font, bool alignToFramePadding = true) {
    UI::PushFont(font);
    auto bounds = Draw::MeasureString(msg, font, font.FontSize, 0.0f) * UI_SCALE + UI::GetStyleVarVec2(UI::StyleVar::FramePadding).x * 2;
    auto pos = (UI::GetWindowContentRegionMax() - bounds) / 2.;
    pos.y = UI::GetCursorPos().y;
    UI::SetCursorPos(pos);
    auto ret = UI::Button(msg);
    // auto r = UI::GetItemRect();
    // lastCenteredTextBounds.x = r.z;
    // lastCenteredTextBounds.y = r.w;
    UI::PopFont();
    return ret;
}
