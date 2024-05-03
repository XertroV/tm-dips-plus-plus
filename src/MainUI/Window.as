[Setting hidden]
bool g_MainUiVisible = false;

namespace MainUI {
    void Render() {
        if (!g_MainUiVisible) return;

        UI::SetNextWindowPos(400, 400, UI::Cond::FirstUseEver);
        UI::SetNextWindowSize(600, 400, UI::Cond::FirstUseEver);
        int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::MenuBar;

        if (UI::Begin("Dips++   \\$aaa by XertroV", g_MainUiVisible, flags)) {
            if (UI::BeginMenuBar()) {
                DrawPluginMenuInner(true);
                UI::EndMenuBar();
            }
            UI::BeginTabBar("MainTabBar");
            if (UI::BeginTabItem("Stats")) {
                DrawStatsTab();
                UI::EndTabItem();
            }

            if (UI::BeginTabItem("Leaderboard")) {
                DrawLeaderboardTab();
                UI::EndTabItem();
            }

            if (UI::BeginTabItem("Collections")) {
                DrawMainCollectionsTab();
                UI::EndTabItem();
            }

            if (UI::BeginTabItem("Voice Lines")) {
                DrawVoiceLinesTab();
                UI::EndTabItem();
            }

            // if (UI::BeginTabItem("Credits")) {
            //     DrawCreditsTab();
            //     UI::EndTabItem();
            // }
            UI::EndTabBar();
        }
        UI::End();
    }

    void DrawStatsTab() {
        DrawCenteredText("Global Stats", f_DroidBigger, 26.);
        UI::Columns(2, "GlobalStatsColumns", true);
        UI::Text("Players");
        UI::Text("Connected Players");
        UI::Text("Total Falls");
        UI::Text("Total Floors Fallen");
        UI::Text("Total Height Fallen");
        UI::Text("Total Jumps");
        UI::Text("Total Map Loads");
        UI::Text("Total Resets");
        UI::Text("Total Sessions");
        UI::NextColumn();
        UI::Text(tostring(Global::players));
        UI::Text(tostring(Global::nb_players_live));
        UI::Text(tostring(Global::falls));
        UI::Text(tostring(Global::floors_fallen));
        UI::Text(tostring(Global::height_fallen));
        UI::Text(tostring(Global::jumps));
        UI::Text(tostring(Global::map_loads));
        UI::Text(tostring(Global::resets));
        UI::Text(tostring(Global::sessions));
        UI::Columns(1);
        UI::Separator();
        Stats::DrawStatsUI();
    }

    void DrawMainCollectionsTab() {
        DrawCenteredText("Collections", f_DroidBigger, 26.);
        GLOBAL_TITLE_COLLECTION.DrawStats();
        UI::Separator();
        GLOBAL_GG_TITLE_COLLECTION.DrawStats();
        UI::Separator();
        UI::AlignTextToFramePadding();
        UI::TextWrapped("Details and things coming soon!");
    }

    void DrawLeaderboardTab() {
        DrawCenteredText("Leaderboard", f_DroidBigger, 26.);
        DrawCenteredText("Top 3", f_DroidBigger, 26.);
        auto @top3 = Global::top3;
        for (uint i = 0; i < top3.Length; i++) {
            auto @player = top3[i];
            if (player.name == "") {
                DrawCenteredText(tostring(i + 1) + ". ???", f_DroidBig, 20.);
            } else {
                DrawCenteredText(tostring(i + 1) + ". " + player.name + Text::Format(" - %.1f m", player.height), f_DroidBig, 20.);
            }
        }
        UI::Text("");
        DrawCenteredText("-- More LB Features Soon --", f_DroidBig, 20.);
    }

    void DrawVoiceLinesTab() {
        DrawCenteredText("Voice Lines", f_DroidBigger, 26.);
        UI::Separator();
        UI::BeginDisabled(!g_Active || IsVoiceLinePlaying());
        for (uint i = 0; i < 18; i++) {
            if (Stats::HasPlayedVoiceLine(i)) {
                UI::AlignTextToFramePadding();
                UI::Text("Floor " + tostring(i) + " unlocked!");
                UI::SameLine();
                if (UI::Button("Replay Voice Line##floor"+i)) {
                    voiceLineToPlay = i;
                    startnew(CoroutineFunc(MainUI::PlayVoiceLine));
                }
            } else {
                UI::AlignTextToFramePadding();
                UI::Text("Floor " + tostring(i) + " locked");
            }
        }
        UI::EndDisabled();
    }

    uint voiceLineToPlay;
    void PlayVoiceLine() {
        PlayVoiceLine(voiceLineToPlay);
    }

    void PlayVoiceLine(uint floor) {
        if (floor >= 17) return;
        if (voiceLineTriggers.Length < 17) return;
        if (IsVoiceLinePlaying()) return;
        if (!Stats::HasPlayedVoiceLine(floor)) return;
        auto @vlTrigger = cast<FloorVLTrigger>(voiceLineTriggers[floor]);
        if (vlTrigger is null) return;
        startnew(CoroutineFunc(vlTrigger.PlayItem));
        AddSubtitleAnimation(vlTrigger.subtitles);
    }
}
