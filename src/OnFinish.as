[Setting hidden]
bool F_HasUnlockedEpilogue = false;

void OnLocalPlayerFinished(PlayerState@ p) {
    if (p !is null && p.isLocal) {
        if (MatchDD2::isDD2Proper) Stats::LogDD2Finish();
        else if (MatchDD2::isEasyDD2Map) Stats::LogDD2EasyFinish();
        else Stats::LogFinish();
    }
    startnew(OnFinish::RunFinishSequenceCoro);
    OnFinish::playerFinishedLastAt = Time::Now;
}

namespace OnFinish {
    uint playerFinishedLastAt = 0;

    const string[] EZ_FIN_RAINBOW_LINES = {
        "Amazing!",
        "You're a pro!",
        "That was great!",
        "You did it!",
        "Impressive!",
        "Sick Jump!"
    };

    int lastChosen = -1;
    const string ChooseEzFinLine() {
        int chosen = lastChosen;
        while (chosen == lastChosen) {
            chosen = Math::Rand(0, EZ_FIN_RAINBOW_LINES.Length - 1);
        }
        lastChosen = chosen;
        return EZ_FIN_RAINBOW_LINES[chosen];
    }

    bool isFinishSeqRunning = false;
    void RunFinishSequenceCoro() {
        if (isFinishSeqRunning) {
            return;
        }
        isFinishSeqRunning = true;
        StartCelebrationAnim();
        WaitForRespawn();
        isFinishSeqRunning = false;
    }

    void StartCelebrationAnim() {
        auto app = GetApp();
        if (MatchDD2::isEasyDD2Map) {
            StartEzCelebrationAnim();
        } else if (MatchDD2::isDD2Proper || MatchDD2::VerifyIsDD2(app)) {
            StartDD2CelebrationAnim();
        }
    }

    void StartEzCelebrationAnim() {
        EmitStatusAnimation(RainbowStaticStatusMsg(ChooseEzFinLine()).WithDuration(7000).WithSize(140.).WithScreenUv(vec2(.5, .25)));
        EmitStatusAnimation(RainbowStaticStatusMsg(ChooseEzFinLine()).WithDuration(10000).WithSize(140.).WithScreenUv(vec2(.5, .60)));
    }

    void StartDD2CelebrationAnim() {
        startnew(RunFinishCamera).WithRunContext(Meta::RunContext::AfterScripts);
        startnew(Fanfare::OnFinishHit);
        F_HasUnlockedEpilogue = true;
        Meta::SaveSettings();
    }

    void WaitForRespawn() {
        auto app = GetApp();
        CGamePlayground@ pg;
        CGamePlaygroundUIConfig@ ui;
        uint startedWaiting = Time::Now;
        while (true) {
            yield();
            if ((@pg = app.CurrentPlayground) is null) return;
            if (pg.UIConfigs.Length == 0) return;
            if ((@ui = pg.UIConfigs[0]) is null) return;
            if (ui.UISequence == CGamePlaygroundUIConfig::EUISequence::Finish) continue;
            // if (ui.UISequence != CGamePlaygroundUIConfig::EUISequence::Playing) continue;
            break;
        }
        sleep_fix(100);
        if (MatchDD2::isEasyDD2Map) {
            g_ShowEzFinishEpilogueScreen = true;
        } else if (MatchDD2::isDD2Proper) {
            g_ShowDD2FinishEpilogueScreen = true;
        }
    }

    bool g_ShowEzFinishEpilogueScreen = false;
    bool g_ShowDD2FinishEpilogueScreen = false;

    void Render() {
        if (g_ShowEzFinishEpilogueScreen) {
            RenderEzEpilogue();
        } else if (g_ShowDD2FinishEpilogueScreen) {
            RenderDD2Epilogue();
        }
    }

    int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoResize | UI::WindowFlags::NoSavedSettings | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoTitleBar;
    float ui_scale = UI_SCALE;
    const int2 windowSize = int2(500, 300);

    void RenderEzEpilogue() {
        if (!g_ShowEzFinishEpilogueScreen) return;
        UI::SetNextWindowSize(windowSize.x, windowSize.y, UI::Cond::Always);
        auto pos = (int2(g_screen.x / ui_scale, g_screen.y / ui_scale) - windowSize) / 2;
        UI::SetNextWindowPos(pos.x, pos.y, UI::Cond::Always);
        // timeout or no map
        bool drawSkip = (playerFinishedLastAt > 0 && Time::Now - playerFinishedLastAt > 25000) || GetApp().RootMap is null;
        if (UI::Begin("dpp ez fin epilogue", flags)) {
            UI::Dummy(vec2(0, 85));
            DrawCenteredText("Congratulations!", f_DroidBigger, 26);
            if (DrawCenteredButton("Play Epilogue", f_DroidBigger, 26)) {
                startnew(PlayEzEpilogue);
                EmitStatusAnimation(FinCelebrationAnim());
                g_ShowEzFinishEpilogueScreen = false;
            }
            UI::Dummy(vec2(0, 18));
            if (drawSkip && DrawCenteredButton("Skip Epilogue", f_DroidBig, 20.)) {
                g_ShowEzFinishEpilogueScreen = false;
                isFinishSeqRunning = false;
            }
        }
        UI::End();
    }

    void RenderDD2Epilogue() {
        if (!g_ShowDD2FinishEpilogueScreen) return;
        UI::SetNextWindowSize(windowSize.x, windowSize.y, UI::Cond::Always);
        auto pos = (int2(g_screen.x / ui_scale, g_screen.y / ui_scale) - windowSize) / 2;
        UI::SetNextWindowPos(pos.x, pos.y, UI::Cond::Always);
        // timeout or no map
        bool drawSkip = (playerFinishedLastAt > 0 && Time::Now - playerFinishedLastAt > 25000) || GetApp().RootMap is null;
        if (UI::Begin("dpp ez fin epilogue", flags)) {
            UI::Dummy(vec2(0, 85));
            DrawCenteredText("Congratulations!", f_DroidBigger, 26);
            if (DrawCenteredButton("Play Epilogue", f_DroidBigger, 26)) {
                startnew(PlayDD2Epilogue);
                // EmitStatusAnimation(DD2FinCelebrationAnim());
                g_ShowDD2FinishEpilogueScreen = false;
            }
            UI::Dummy(vec2(0, 24));
#if DEV
            if (drawSkip && DrawCenteredButton("Skip Epilogue", f_DroidBig, 20.)) {
                g_ShowDD2FinishEpilogueScreen = false;
                isFinishSeqRunning = false;
            }
#endif
        }
        UI::End();
    }

    void PlayDD2Epilogue() {
        t_DD2MapFinishVL.StartTrigger();
    }

    void PlayEzEpilogue() {
        t_EasyMapFinishVL.StartTrigger();
    }

    // for ez map
    class FinCelebrationAnim : ProgressAnim {
        // uint startMoveAt = 6500;
        // uint endMoveAt = 17000;
        uint startMoveAt = 3000;
        uint endMoveAt = 25000;
        vec2 startAE = vec2(5.467, 1.959);
        vec2 midAE = vec2(4.645, 2.370);
        vec2 midAE2 = vec2(4.041, 2.697);
        vec2 endAE = vec2(3.566, 3.113);
        iso4 origIso4;
        FinCelebrationAnim() {
            super("fin celebration", nat2(0, 155000));
            fadeIn = 500;
            fadeOut = 500;
            pauseWhenMenuOpen = false;
            origIso4 = SetTimeOfDay::GetSunIso4();
        }

        ~FinCelebrationAnim() {
            if (origIso4.yy < 1.0 || origIso4.xx < 1.0 || origIso4.zz < 1.0) {
                SetTimeOfDay::SetSunIso4(origIso4);
            }
        }

        vec2 Draw() override {
            if (progressMs > startMoveAt) {
                float t = Math::Clamp(float(progressMs - startMoveAt) / float(endMoveAt - startMoveAt), 0.0, 1.5);
                if (t < 1.5) {
                    SetTimeOfDay::SetSunAngle(GetAzEl(t));
                }
            }
            return vec2();
        }

        vec2 GetAzEl(float t) {
            if (t < 0.43668) {
                return Math::Lerp(startAE, midAE, t / 0.43668);
            } else {
                return Math::Lerp(midAE, midAE2, (t - 0.43668) / (0.763046 - 0.43668));
            }
            // } else if (t < 0.763046) {
            //     return Math::Lerp(midAE, midAE2, (t - 0.43668) / (0.763046 - 0.43668));
            // } else {
            //     return Math::Lerp(midAE2, endAE, (t - 0.763046) / (1.0 - 0.763046));
            // }
            return endAE;
        }
    }

    // main map only
    void RunFinishCamera() {
        auto app = GetApp();
        // only on DD2
        if (!MatchDD2::VerifyIsDD2(app)) return;
        dev_trace('starting to run finish camera');
        OnCameraUpdateHook_Other.Apply();
        sleep_fix(1000);
        try {
            while (true) {
                if (app.Network.PlaygroundClientScriptAPI is null) break;
                if (app.Network.PlaygroundClientScriptAPI.UI is null) break;
                if (app.Network.PlaygroundClientScriptAPI.UI.UISequence != CGamePlaygroundUIConfig::EUISequence::Finish) {
                   break;
                }
                yield();
            }
        } catch {
            NotifyWarning("Exception in finish sequence. Disabling camera.");
            warn(getExceptionInfo());
        }
        OnCameraUpdateHook_Other.Unapply();
        dev_trace('done running finish camera');
    }
}
