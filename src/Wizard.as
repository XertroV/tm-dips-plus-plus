/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
[Setting hidden]
bool S_WizardFinished = false;

bool g_WizardOpen = false;

namespace Wizard {
    void OnPluginLoad() {
        g_WizardOpen = !S_WizardFinished;
    }

    const int2 windowSize = int2(1100, 700);
    int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoResize | UI::WindowFlags::NoSavedSettings | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoTitleBar;
    float ui_scale = UI::GetScale();

    void DrawWindow() {
        if (!g_WizardOpen) return;
        if (!G_Initialized) return;
        UI::SetNextWindowSize(windowSize.x, windowSize.y, UI::Cond::Always);
        auto pos = (int2(g_screen.x / ui_scale, g_screen.y / ui_scale) - windowSize) / 2;
        UI::SetNextWindowPos(pos.x, pos.y, UI::Cond::Always);
        if (UI::Begin("D++ Wizard", g_WizardOpen, flags)) {
            DrawInner();
        }
        UI::End();
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
        DrawCenteredText("Welcome to the D++ Wizard!", f_DroidBigger, 26.);

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
        DrawCenteredText("Please complete the volume test, now.", f_DroidBig, 20.);

        if (!showVolumeSlider) {
            if (DrawCenteredButton("Begin Volume Test", f_DroidBig, 20.)) {
                Volume::ToggleAudioTest();
                showVolumeSlider = true;
            }
        } else if (Volume::IsAudioTestRunning()) {
            UI::Dummy(vec2(20.));
            UI::Dummy(vec2(avail.x * 0.125, 0));
            UI::SameLine();


            UI::SetNextItemWidth(avail.x * .75);
            UI::PushFont(f_DroidBig);
            Volume::DrawVolumeSlider(false);
            UI::Dummy(vec2(avail.x * .4, 0));
            UI::SameLine();
            S_PauseWhenGameUnfocused = UI::Checkbox("Pause audio when the game is unfocused", S_PauseWhenGameUnfocused);
            UI::PopFont();
            if (DrawCenteredButton("Skip Audio Test", f_DroidBig, 20.)) {
                Volume::ToggleAudioTest();
                wizardStep++;
            }
        } else if (DrawCenteredButton("Proceed", f_DroidBig, 20.)) {
            wizardStep++;
        }
    }

    void DrawStepOne() {
        DrawCenteredText("Do you like options? Would it make you feel better to change some?", f_DroidBig, 20.);
        UI::Dummy(vec2(avail.x * 0.125, 0));
        UI::SameLine();
        if (UI::BeginChild("##wizstep1", vec2(avail.x * .75, 0), false, UI::WindowFlags::AlwaysAutoResize)) {
            S_EnableMainMenuPromoBg = UI::Checkbox("Enable Main Menu Surprise?", S_EnableMainMenuPromoBg);
            if (S_EnableMainMenuPromoBg) {
                S_MenuBgTimeOfDay = ComboTimeOfDay("Main Menu Background Time of Day", S_MenuBgTimeOfDay);
                S_MenuBgSeason = ComboSeason("Main Menu Background Season", S_MenuBgSeason);
            }
            S_ShowDDLoadingScreens = UI::Checkbox("Show DD2 Loading Screens?", S_ShowDDLoadingScreens);
            if (DrawCenteredButton("Proceed", f_DroidBig, 20.)) {
                wizardStep++;
            }
        }
        UI::EndChild();
    }

    void DrawStepTwo() {
        DrawCenteredText("I hope you liked that.", f_DroidBig, 20.);
        if (DrawCenteredButton("Yes, very fun.", f_DroidBig, 20.)) {
            wizardStep++;
        }
    }

    void DrawStepThree() {
        DrawCenteredText("Fantastic.", f_DroidBig, 20.);
        DrawCenteredText("Once you're in the map, you can change settings through the menu", f_DroidBig, 20.);
        DrawCenteredText("Or via the button in the lower right corner.", f_DroidBig, 20.);
        if (DrawCenteredButton("Can I go now?", f_DroidBig, 20.)) {
            wizardStep++;
        }
    }

    void DrawStepFour() {
        DrawCenteredText("... Yes, yes of course. I won't keep you any longer.", f_DroidBig, 20.);
        DrawCenteredText("Have fun!", f_DroidBig, 20.);
        UI::Dummy(vec2(avail.x * 0.45, 0));
        UI::SameLine();
        if (DrawCenteredButton(".....", f_DroidBig, 20.)) {
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
void DrawCenteredText(const string &in msg, UI::Font@ font, float fontSize, bool alignToFramePadding = true) {
    UI::PushFont(font);
    auto bounds = Draw::MeasureString(msg, font, fontSize, 0.0f);
    auto pos = (UI::GetWindowContentRegionMax() - bounds) / 2. / UI::GetScale();
    pos.y = UI::GetCursorPos().y;
    UI::SetCursorPos(pos);
    UI::Text(msg);
    // auto r = UI::GetItemRect();
    // lastCenteredTextBounds.x = r.z;
    // lastCenteredTextBounds.y = r.w;
    UI::PopFont();
}

bool DrawCenteredButton(const string &in msg, UI::Font@ font, float fontSize, bool alignToFramePadding = true) {
    UI::PushFont(font);
    auto bounds = Draw::MeasureString(msg, font, fontSize, 0.0f) + fontSize;
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
