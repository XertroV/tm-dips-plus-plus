[Setting hidden]
bool g_MainUiVisible = false;

namespace MainUI {
    void Render() {
        if (!g_MainUiVisible) return;

        UI::SetNextWindowPos(400, 400, UI::Cond::FirstUseEver);
        UI::SetNextWindowSize(600, 400, UI::Cond::FirstUseEver);
        int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::MenuBar;

        if (UI::Begin("Dips++   \\$aaa by XertroV", g_MainUiVisible, flags)) {
            if (g_api !is null && g_api.authError.Length > 0) {
                UI::TextWrapped("\\$f80Auth Error: \\$z" + g_api.authError);
            }


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

            if (UI::BeginTabItem("Donations")) {
                DrawDonationsTab();
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
        UI::Text("Currently Climbing");
        UI::Text("Total Falls");
        UI::Text("Total Floors Fallen");
        UI::Text("Total Height Fallen");
        UI::Text("Total Jumps");
        // UI::Text("Total Map Loads");
        UI::Text("Total Resets");
        UI::Text("Total Sessions");
        UI::NextColumn();
        UI::Text(tostring(Global::players));
        UI::Text(tostring(Global::nb_players_live));
        UI::Text(tostring(Global::nb_players_climbing));
        UI::Text(tostring(Global::falls));
        UI::Text(tostring(Global::floors_fallen));
        UI::Text(Text::Format("%.1f km", Global::height_fallen / 1000.));
        UI::Text(tostring(Global::jumps));
        // UI::Text(tostring(Global::map_loads));
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

    bool donationsShowingDonors = true;
    void DrawDonationsTab() {
        Global::CheckUpdateDonations();
        DrawCenteredText("Total Prize Pool: $" + Text::Format("%.2f", Global::totalDonations), f_DroidBigger, 26.);
        if (DrawCenteredButton("Contribute to the Prize Pool", f_DroidBigger, 26.)) {
            OpenBrowserURL("https://matcherino.com/tournaments/111501");
        }
        DrawCenteredText("Donations", f_DroidBigger, 26.);
        UI::Separator();
        if (UI::RadioButton("Donations", !donationsShowingDonors)) donationsShowingDonors = false;
        UI::SameLine();
        if (UI::RadioButton("Donors", donationsShowingDonors)) donationsShowingDonors = true;
        UI::Separator();
        if (donationsShowingDonors) {
            DrawDonations_Donors();
        } else {
            DrawDonations_Donations();
        }
    }

    void DrawDonations_Donations() {
        if (UI::BeginTable("donations", 3, UI::TableFlags::SizingStretchProp)) {
            UI::TableSetupColumn("Amount", UI::TableColumnFlags::WidthFixed, 100.);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed, 180.);
            UI::TableSetupColumn("Message");
            UI::ListClipper clip(Global::donations.Length);
            while (clip.Step()) {
                for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                    auto item = Global::donations[i];
                    UI::PushID('' + i);
                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text(Text::Format("$%.2f", item.amount));
                    UI::TableNextColumn();
                    UI::Text(item.name);
                    UI::TableNextColumn();
                    UI::Text(item.comment);
                    UI::PopID();
                }
            }
            UI::EndTable();
        }
    }

    void DrawDonations_Donors() {
        if (UI::BeginTable("donors", 3, UI::TableFlags::SizingStretchProp)) {
            UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 80.);
            UI::TableSetupColumn("Amount", UI::TableColumnFlags::WidthFixed, 100.);
            UI::TableSetupColumn("Donor");
            UI::ListClipper clip(Global::donors.Length);
            while (clip.Step()) {
                for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                    auto item = Global::donors[i];
                    UI::PushID('' + i);
                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text(tostring(i + 1));
                    UI::TableNextColumn();
                    UI::Text(Text::Format("$%.2f", item.amount));
                    UI::TableNextColumn();
                    UI::Text(item.name);
                    UI::PopID();
                }
            }
            UI::EndTable();
        }
    }

    uint lastLbUpdate = 0;
    // update at most once per minute
    void CheckUpdateLeaderboard() {
        if (lastLbUpdate + 60000 < Time::Now) {
            lastLbUpdate = Time::Now;
            PushMessage(GetMyRankMsg());
            PushMessage(GetGlobalLBMsg(1, 501));
        }
    }

    void DrawLeaderboardTab() {
        CheckUpdateLeaderboard();
        DrawCenteredText("Leaderboard", f_DroidBigger, 26.);
        DrawCenteredText("Top " + S_NbTopTimes, f_DroidBigger, 26.);
        auto @top3 = Global::top3;
        for (uint i = 0; i < Math::Min(S_NbTopTimes, top3.Length); i++) {
            auto @player = top3[i];
            if (player.name == "") {
                DrawCenteredText(tostring(i + 1) + ". ???", f_DroidBig, 20.);
            } else {
                DrawCenteredText(tostring(i + 1) + ". " + player.name + Text::Format(" - %.1f m", player.height), f_DroidBig, 20.);
            }
        }
        UI::Separator();
        DrawCenteredText("My Rank", f_DroidBigger, 26.);
        DrawCenteredText(Text::Format("%d. ", Global::myRank.rank) + Text::Format("%.1f m", Global::myRank.height), f_DroidBig, 20.);
        UI::Separator();
        DrawCenteredText("Global Leaderboard", f_DroidBigger, 26.);
        if (UI::BeginChild("GlobalLeaderboard", vec2(0, 0), false, UI::WindowFlags::AlwaysVerticalScrollbar)) {
            if (UI::BeginTable('lbtabel', 3, UI::TableFlags::SizingStretchSame)) {
                UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 80.);
                UI::TableSetupColumn("Height (m)", UI::TableColumnFlags::WidthFixed, 100.);
                UI::TableSetupColumn("Player");
                UI::ListClipper clip(Global::globalLB.Length);
                while (clip.Step()) {
                    for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                        UI::PushID(i);
                        UI::TableNextRow();
                        auto item = Global::globalLB[i];
                        UI::TableNextColumn();
                        UI::Text(Text::Format("%d.", item.rank));
                        UI::TableNextColumn();
                        UI::Text(Text::Format("%.1f m", item.height));
                        UI::TableNextColumn();
                        UI::Text(item.name);
                        UI::PopID();
                    }
                }
                UI::EndTable();
            }
        }
        UI::EndChild();
        // UI::Text("");
        // DrawCenteredText("-- More LB Features Soon --", f_DroidBig, 20.);
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
