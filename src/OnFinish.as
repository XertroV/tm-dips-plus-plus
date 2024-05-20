void OnLocalPlayerFinished(PlayerState@ p) {
    startnew(OnFinish::RunFinishSequenceCoro);
}

namespace OnFinish {
    const string[] EZ_FIN_RAINBOW_LINES = {
        "Amazing!",
        "You're a pro!",
        "That was great!",
        "You did it!",
        "Impressive!"
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
    }

    void StartCelebrationAnim() {
        EmitStatusAnimation(FinCelebrationAnim());
        EmitStatusAnimation(RainbowStaticStatusMsg(ChooseEzFinLine()).WithDuration(7000).WithSize(140.).WithScreenUv(vec2(.5, .25)));
        EmitStatusAnimation(RainbowStaticStatusMsg(ChooseEzFinLine()).WithDuration(10000).WithSize(140.).WithScreenUv(vec2(.5, .60)));
    }

    void WaitForRespawn() {
        auto app = GetApp();
        CGamePlayground@ pg;
        CGamePlaygroundUIConfig@ ui;
        while (true) {
            yield();
            if ((@pg = app.CurrentPlayground) is null) return;
            if (pg.UIConfigs.Length == 0) return;
            if ((@ui = pg.UIConfigs[0]) is null) return;
            if (ui.UISequence == CGamePlaygroundUIConfig::EUISequence::Finish) continue;
            if (ui.UISequence != CGamePlaygroundUIConfig::EUISequence::Playing) continue;
            break;
        }
        sleep(100);
        g_ShowEzFinishEpilogueScreen = true;
    }

    bool g_ShowEzFinishEpilogueScreen = false;

    int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoResize | UI::WindowFlags::NoSavedSettings | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoTitleBar;
    float ui_scale = UI::GetScale();
    const int2 windowSize = int2(500, 300);

    void RenderEzEpilogue() {
        if (!g_ShowEzFinishEpilogueScreen) return;
        UI::SetNextWindowSize(windowSize.x, windowSize.y, UI::Cond::Always);
        auto pos = (int2(g_screen.x / ui_scale, g_screen.y / ui_scale) - windowSize) / 2;
        UI::SetNextWindowPos(pos.x, pos.y, UI::Cond::Always);
        if (UI::Begin("dpp ez fin epilogue", flags)) {
            UI::Dummy(vec2(0, 75));
            DrawCenteredText("Congratulations!", f_DroidBigger, 26);
            if (DrawCenteredButton("Play Epilogue", f_DroidBigger, 26)) {
                startnew(PlayEzEpilogue);
                g_ShowEzFinishEpilogueScreen = false;
            }
        }
        UI::End();
    }

    void PlayEzEpilogue() {
        t_EasyMapFinishVL.StartTrigger();
    }

    class FinCelebrationAnim : ProgressAnim {
        FinCelebrationAnim() {
            super("fin celebration", nat2(0, 10000));
            fadeIn = 1000;
            fadeOut = 500;
            pauseWhenMenuOpen = false;
        }

        vec2 Draw() override {

            return vec2();
        }
    }
}
