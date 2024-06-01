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
            if (UI::BeginTabItem("DD2 Stats")) {
                DrawStatsTab();
                UI::EndTabItem();
            }

            if (UI::BeginTabItem("Leaderboard")) {
                DrawLeaderboardTab();
                UI::EndTabItem();
            }

            if (UI::BeginTabItem("Prize Pool")) {
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

            if (UI::BeginTabItem("Profile")) {
                DrawProfileTab();
                UI::EndTabItem();
            }

            if (g_Active) {
                if (UI::BeginTabItem("Spectate")) {
                    DrawSpectateTab();
                    UI::EndTabItem();
                }

                if (!MatchDD2::isDD2Proper && UI::BeginTabItem("Map Stats")) {
                    if (g_CustomMap is null) {
                        UI::TextWrapped("Unknown error: g_CustomMap is null. (Bug)");
                    } else {
                        g_CustomMap.DrawMapTabs();
                    }
                    UI::EndTabItem();
                }
            }

            // if (UI::BeginTabItem("Credits")) {
            //     DrawCreditsTab();
            //     UI::EndTabItem();
            // }
            UI::EndTabBar();
        }
        UI::End();
    }

    string m_TwitchID;
    void DrawProfileTab() {
        UI::PushItemWidth(UI::GetContentRegionAvail().x * 0.5);
        bool changed;
        m_TwitchID = UI::InputText("Twitch username", m_TwitchID, changed);
        if (changed) {
            TwitchNames::UpdateMyTwitchName(m_TwitchID);
        }
        UserProfiles::DrawEditProfile();
        UI::PopItemWidth();
    }



    PlayerState@[] specSorted;
    uint sortCounter = 0;
    uint sortCounterModulo = 300;

    void DrawSpectateTab() {
        auto specId = PS::viewedPlayer is null ? 0 : PS::viewedPlayer.playerScoreMwId;
        auto len = PS::players.Length;
        bool disableSpectate = !MAGIC_SPEC_ENABLED && !Spectate::IsSpectator;

        UI::AlignTextToFramePadding();
        UI::Indent();
        if (!MAGIC_SPEC_ENABLED) {
            UI::TextWrapped("Spectating buttons disabled outside of spectator mode.\n\\<$\\$f80Magic Spectating Disabled!\\$> Spectating while driving (without killing your run) requires MLHook -- install it from plugin manager.");
        } else {
            UI::TextWrapped("\\$4f4Magic Spectating Enabled!\\$z Spectating while driving will not kill your run. Press ESC to exit. Camera changes work. Movement auto-disables.");
            UI::BeginDisabled(!MagicSpectate::IsActive());
            if (UI::Button("Exit Magic Spectator")) {
                MagicSpectate::Reset();
            }
            UI::EndDisabled();
            UI::SameLine();
        }
        if (UI::Button("Sort List Now")) {
            sortCounter = 0;
        }
        UI::Unindent();
        float refreshProg = 1. - float(sortCounter) / float(sortCounterModulo);
        UI::PushStyleColor(UI::Col::PlotHistogram, Math::Lerp(cRed, cLimeGreen, refreshProg));
        UI::ProgressBar(refreshProg, vec2(-1, 2));
        UI::PopStyleColor();

        if (specSorted.Length != len) {
            sortCounter = 0;
        }

        // only sort every so often to avoid unstable ordering for neighboring ppl
        if (sortCounter == 0) {
            specSorted.Resize(0);
            specSorted.Reserve(len * 2);
            for (uint i = 0; i < len; i++) {
                _InsertPlayerSortedByHeight(specSorted, PS::players[i]);
            }
        }

        if (len > 1) sortCounter = (sortCounter + 1) % sortCounterModulo;

        UI::PushStyleColor(UI::Col::TableRowBgAlt, cGray35);
        if (UI::BeginTable("specplayers", 4, UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY | UI::TableFlags::RowBg)) {
            UI::TableSetupColumn("Spec", UI::TableColumnFlags::WidthFixed, 40. * UI_SCALE);
            UI::TableSetupColumn("Height", UI::TableColumnFlags::WidthFixed, 80. * UI_SCALE);
            UI::TableSetupColumn("From PB", UI::TableColumnFlags::WidthFixed, 100. * UI_SCALE);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableHeadersRow();

            PlayerState@ p;
            bool isSpeccing;
            UI::ListClipper clip(specSorted.Length);
            while (clip.Step()) {
                for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                    @p = specSorted[i];
                    isSpeccing = specId == p.playerScoreMwId;
                    UI::PushID('spec'+i);

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::BeginDisabled(disableSpectate || p.isSpectator || p.isLocal);
                    if (UI::Button((isSpeccing) ? Icons::EyeSlash : Icons::Eye)) {
                        if (isSpeccing) {
                            Spectate::StopSpectating();
                        } else {
                            Spectate::SpectatePlayer(p);
                        }
                    }
                    UI::EndDisabled();

                    UI::TableNextColumn();
                    UI::AlignTextToFramePadding();
                    UI::Text(Text::Format("%.1f m", p.pos.y));

                    UI::TableNextColumn();
                    UI::AlignTextToFramePadding();
                    UI::Text(Text::Format("(%.1f m)", (p.pos.y - Global::GetPlayersPBHeight(p))));

                    UI::TableNextColumn();
                    UI::Text((p.clubTag.Length > 0 ? "[\\$<"+p.clubTagColored+"\\$>] " : "") + p.playerName);

                    UI::PopID();
                }
            }

            UI::EndTable();
        }
        UI::PopStyleColor();
    }


    void DrawStatsTab() {
        DrawCenteredText("Global Stats (DD2)", f_DroidBigger, 26.);
        UI::Columns(2, "GlobalStatsColumns", true);
        UI::Text("Players");
        UI::Text("Connected Players");
        UI::Text("Currently Climbing");
        UI::Text("\\$i\\$aaaClimbing Shallow Dip");
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
        UI::Text("\\$i\\$aaa" + tostring(Global::nb_climbing_shallow_dip));
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

        CheckReRequestOverview();
    }

    uint lastOverviewReq = 0;
    void CheckReRequestOverview() {
        if (lastOverviewReq == 0) lastOverviewReq = Time::Now;
        if (lastOverviewReq + 60000 < Time::Now && g_api !is null && g_api.HasContext) {
            lastOverviewReq = Time::Now;
            PushMessage(GetGlobalOverviewMsg());
        }
    }

    void DrawMainCollectionsTab() {
        DrawCenteredText("Collections", f_DroidBigger, 26.);
        UI::Separator();
        S_PickRandomTitleGag = UI::Checkbox("[Workaround] Always Pick Random Title Gag", S_PickRandomTitleGag);
        AddSimpleTooltip("This is a workaround in case you get the bug where you get one title gag over and over. You probably don't need to enable this.");
        UI::Separator();
        GLOBAL_TITLE_COLLECTION.DrawStats();
        DrawCollectionElements(GLOBAL_TITLE_COLLECTION);
        UI::Separator();
        GLOBAL_GG_TITLE_COLLECTION.DrawStats();
        DrawCollectionElements(GLOBAL_GG_TITLE_COLLECTION);
        // UI::Separator();
        // UI::AlignTextToFramePadding();
        // UI::TextWrapped("Details and things coming soon!");
    }


    void DrawCollectionElements(Collection@ collection) {
        auto tc = cast<TitleCollection>(collection);
        if (tc is null) return;
        bool isMainTc = tc is GLOBAL_TITLE_COLLECTION;
        if (UI::BeginChild("clctn" + tc.FileName, vec2(-1, 300))) {
            auto nbItems = tc.items.Length;
            auto nbPerCol = (nbItems + 2) / 3;

            if (UI::BeginTable("clctnTable", 3, UI::TableFlags::SizingStretchSame)) {
                int ix;
                UI::ListClipper clip(nbPerCol);
                while (clip.Step()) {
                    for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                        UI::TableNextRow();
                        UI::TableNextColumn();
                        DrawCollectionItem(tc.items[i]);
                        UI::TableNextColumn();
                        DrawCollectionItem(tc.items[i + nbPerCol]);
                        UI::TableNextColumn();
                        if ((ix = i + nbPerCol * 2) < nbItems) {
                            DrawCollectionItem(tc.items[ix]);
                        }
                    }
                }

                UI::EndTable();
            }
        }
        UI::EndChild();
    }

    void DrawCollectionItem(CollectionItem@ ci) {
        bool isSpecial = cast<TitleCollectionItem_Special>(ci) !is null;
        UI::PushID(ci.name);
        UI::AlignTextToFramePadding();
        if (ci.collected) {
            g_TitleCollectionOutsideMapCount++;
            if (UI::Button("Play")) {
                ci.PlayItem(false);
            }
            UI::SameLine();
            if (isSpecial) {
                UI::Text("\\$fd4" + ci.name);
            } else {
                UI::Text(ci.name);
            }
        } else {
            UI::Text(ci.BlankedName);
        }
        UI::PopID();
    }


    bool donationsShowingDonors = true;
    void DrawDonationsTab() {
        Global::CheckUpdateDonations();
        DrawCenteredText("Total Prize Pool: $" + Text::Format("%.2f", Global::totalDonations), f_DroidBigger, 26.);
        DrawCenteredText(Text::Format("1st: $%.2f", Global::totalDonations * 0.5)
            + Text::Format(" | 2nd: $%.2f", Global::totalDonations * 0.3)
            + Text::Format(" | 3rd: $%.2f", Global::totalDonations * 0.2)
            , f_DroidBig, 20.);
        if (DrawCenteredButton("Contribute to the Prize Pool", f_DroidBigger, 26.)) {
            OpenBrowserURL("https://matcherino.com/tournaments/111501");
        }
        UI::Separator();
        DrawCenteredText("Donation Cheers", f_DroidBig, 20.);
        DrawCenteredText("Mention a streamer in your donation msg to cheer them on!", f_Droid, 16.);
        Donations::DrawDonoCheers();
        UI::Separator();
        DrawCenteredText("Donations", f_DroidBigger, 26.);
        if (UI::RadioButton("Donations", !donationsShowingDonors)) donationsShowingDonors = false;
        UI::SameLine();
        if (UI::RadioButton("Donors", donationsShowingDonors)) donationsShowingDonors = true;
        UI::Separator();
        if (UI::BeginChild("donobody", vec2(), false, UI::WindowFlags::AlwaysVerticalScrollbar)) {
            if (donationsShowingDonors) {
                DrawDonations_Donors();
            } else {
                DrawDonations_Donations();
            }
        }
        UI::EndChild();
    }

    void DrawDonations_Donations() {
        if (UI::BeginTable("donations", 3, UI::TableFlags::SizingStretchProp)) {
            UI::TableSetupColumn("Amount", UI::TableColumnFlags::WidthFixed, 100. * UI_SCALE);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed, 180. * UI_SCALE);
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
            UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 80. * UI_SCALE);
            UI::TableSetupColumn("Amount", UI::TableColumnFlags::WidthFixed, 100. * UI_SCALE);
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
            PushMessage(GetGlobalLBMsg(1, 205));
            PushMessage(GetGlobalLBMsg(201, 405));
            PushMessage(GetGlobalLBMsg(401, 605));
            PushMessage(GetGlobalLBMsg(601, 805));
            PushMessage(GetGlobalLBMsg(801, 1005));
            PushMessage(GetGlobalLBMsg(1001, 1205));
            PushMessage(GetGlobalLBMsg(1201, 1405));
            PushMessage(GetGlobalLBMsg(1401, 1605));
        }
    }

    void DrawLeaderboardTab() {
        CheckUpdateLeaderboard();
        DrawCenteredText("Leaderboard", f_DroidBigger, 26.);
        auto @top3 = Global::top3;
        auto len = int(top3.Length);
        DrawCenteredText("Top " + len, f_DroidBigger, 26.);
        auto nbCols = len > 5 ? 2 : 1;
        auto startNewAt = nbCols == 1 ? len : (len + 1) / nbCols;
        UI::Columns(nbCols);
        auto cSize = vec2(-1, (UI::GetStyleVarVec2(UI::StyleVar::FramePadding).y + 20.) * startNewAt * UI_SCALE * 1.1);
        UI::BeginChild("lbc1", cSize);
        for (uint i = 0; i < len; i++) {
            if (i == startNewAt) {
                UI::EndChild();
                UI::NextColumn();
                UI::BeginChild("lbc2", cSize);
            }
            auto @player = top3[i];
            if (player.name == "") {
                DrawCenteredText(tostring(i + 1) + ". ???", f_DroidBig, 20.);
            } else {
                DrawCenteredText(tostring(i + 1) + ". " + player.name + Text::Format(" - %.1f m", player.height), f_DroidBig, 20.);
            }
        }
        UI::EndChild();
        UI::Columns(1);
        UI::Separator();
        DrawCenteredText("My Rank", f_DroidBigger, 26.);
        DrawCenteredText(Text::Format("%d. ", Global::myRank.rank) + Text::Format("%.1f m", Global::myRank.height), f_DroidBig, 20.);
        UI::Separator();
        DrawCenteredText("Global Leaderboard", f_DroidBigger, 26.);
        if (UI::BeginChild("GlobalLeaderboard", vec2(0, 0), false, UI::WindowFlags::AlwaysVerticalScrollbar)) {
            if (UI::BeginTable('lbtabel', 3, UI::TableFlags::SizingStretchSame)) {
                UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 80. * UI_SCALE);
                UI::TableSetupColumn("Height (m)", UI::TableColumnFlags::WidthFixed, 100. * UI_SCALE);
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
                        UI::Text(Text::Format("%.04f m", item.height));
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
        for (uint i = 0; i < 18; i++) {
            // instead of drawing f17, draw the secret VL. Then draw epilogue (f17) later.
            if (i == 17) {
                // secret VL
                if (F_PlayedSecretAudio) {
                    UI::Text("End VL unlocked!");
                    UI::SameLine();
                    if (UI::Button("Replay End Voice Line")) {
                        startnew(CoroutineFunc(SecretAssets::PlaySecretAudio));
                    }
                } else {
                    // just hide it
                    // UI::Text("??? locked");
                }
            } else if (Stats::HasPlayedVoiceLine(i)) {
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
        if (F_HasUnlockedEpilogue) {
            UI::Text("Epilogue unlocked!");
            UI::SameLine();
            if (UI::Button("Replay Epilogue")) {
                voiceLineToPlay = 17;
                startnew(CoroutineFunc(MainUI::PlayVoiceLine));
            }
        } else {
            UI::Text("Epilogue locked");
        }
    }

    uint voiceLineToPlay;
    void PlayVoiceLine() {
        PlayVoiceLine(voiceLineToPlay);
    }

    void PlayVoiceLine(uint floor) {
        if (voiceLineTriggers.Length < 17) return;
        if (!Stats::HasPlayedVoiceLine(floor)) return;
        auto @vlTrigger = floor < 17 ? cast<FloorVLTrigger>(voiceLineTriggers[floor])
            : floor == 17 ? t_DD2MapFinishVL : null;
        if (vlTrigger is null) return;
        vlTrigger.PlayNextAnywhere();
        ClearSubtitleAnimations();
        startnew(CoroutineFunc(vlTrigger.PlayItem));
        vlTrigger.subtitles.Reset();
        AddSubtitleAnimation(vlTrigger.subtitles);
        dev_trace('subtitle play is vae? ' + vlTrigger.subtitles.hasHead);
        g_SubtitlesOutsideMapCount++;
    }
}



void _InsertPlayerSortedByHeight(PlayerState@[]@ arr, PlayerState@ p) {
    int upper = int(arr.Length) - 1;
    if (upper < 0) {
        arr.InsertLast(p);
        return;
    }
    if (upper == 0) {
        if (arr[0].pos.y >= p.pos.y) {
            arr.InsertLast(p);
        } else {
            arr.InsertAt(0, p);
        }
        return;
    }
    int lower = 0;
    int mid;
    while (lower < upper) {
        mid = (lower + upper) / 2;
        // trace('l: ' + lower + ', m: ' + mid + ', u: ' + upper);
        if (arr[mid].pos.y < p.pos.y) {
            upper = mid;
        } else {
            lower = mid + 1;
        }
    }
    arr.InsertAt(lower, p);
}
