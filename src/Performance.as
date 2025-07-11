// disable RefreshLeaderboard (0.3ms)
// disable green timer (0.15ms)
// experimental score fix

namespace MoreFrames {
    void RenderUI() {
        UI::SeparatorText("Settings");
        UI::TextWrapped("See Minimap menu for most performance-related Dips++ settings.");
        UI::TextWrapped("In general, reduce the amount of stuff drawn on screen to minimize frame time impact.");
        UI::SeparatorText("Plugins");
        DrawPluginToggle("RefreshLeaderboard", 0.3);
        DrawPluginToggle("green-timer", 0.15);
        // ---
        DrawExperimentalScoreFix();
    }

    void DrawPluginToggle(const string &in pluginId, float saveMs) {
        auto plugin = Meta::GetPluginFromID(pluginId);
        if (plugin is null) {
            UI::Text("\\$aaaNot Installed: " + pluginId);
            return;
        }

        bool toggle = false;
        if (plugin.Enabled) {
            toggle = UI::Button(Icons::ToggleOn + "##t"+pluginId);
            UI::SameLine();
            UI::Text("\\$ff0Enabled: " + pluginId);
            UI::SameLine();
            UI::Text(Text::Format("\\$bbb\\$iSave %.2f ms by disabling.", saveMs));
        } else {
            toggle = UI::Button(Icons::ToggleOff + "##t"+pluginId);
            UI::SameLine();
            UI::Text("\\$aaaDisabled: " + pluginId);
        }

        if (toggle) {
            plugin.Enabled = !plugin.Enabled;
        }
    }

    uint nbDisconnectedPlayers = 0;
    uint nbDisconnectedPlayersUpdated = 0;

    uint nbScores;
    uint nbPlayers;

    void RefreshNbDisconnectedPlayers() {
        auto app = GetApp();
        auto pg = cast<CSmArenaClient>(app.CurrentPlayground);
        if (pg is null || pg.Arena is null || pg.Arena.Rules is null) return;
        auto rules = pg.Arena.Rules;
        nbScores = rules.Scores.Length;
        nbPlayers = pg.Players.Length;
        nbDisconnectedPlayers = nbScores - nbPlayers;
        nbDisconnectedPlayersUpdated = Time::Now;
    }

    const Reflection::MwClassInfo@ _ArenaRulesTy = Reflection::GetType("CSmArenaRules");
    const Reflection::MwMemberInfo@ _ArenaRulesScores = _ArenaRulesTy.GetMember("Scores");

    // returns true if it ran, false if it didn't.
    bool RunFixDisconnectedPlayers() {
        auto app = GetApp();
        auto pg = cast<CSmArenaClient>(app.CurrentPlayground);
        if (pg is null || pg.Arena is null || pg.Arena.Rules is null) return false;
        auto rules = pg.Arena.Rules;
        uint[] goodIxs;
        uint[] badIxs;
        for (uint i = 0; i < rules.Scores.Length; i++) {
            auto user = cast<CTrackManiaPlayerInfo>(rules.Scores[i].User);
            if (IsUserConnected(user)) {
#if DEV
                if (user.PlaygroundRoundNum == 0) {
                    Dev_NotifyWarning("User " + user.Name + " has PlaygroundRoundNum 0, which is unexpected.");
                }
#endif
                goodIxs.InsertLast(i);
            } else {
                badIxs.InsertLast(i);
            }
        }

        trace("Found " + badIxs.Length + " bad players, " + goodIxs.Length + " good players.");

        // sort the scores
        int badPIx = 0;
        // sorting buf2 and trimming: crash
        // sorting buf1 and buf3 and trimming: works for a bit but eventually crash
        // ✅ sorting buf1 and buf3 and trimming only 1: works for 12+ hours tested
        // sorting buf1 only? (I think this created issues; tested first)
        auto scoresBufFakeNod = Dev::GetOffsetNod(rules, _ArenaRulesScores.Offset);
        // auto scores2Buf = Dev::GetOffsetNod(rules, _ArenaRulesScores.Offset + 0x20);
        auto scores3Buf = Dev::GetOffsetNod(rules, _ArenaRulesScores.Offset + 0x30);

        if (scoresBufFakeNod is null || scores3Buf is null) {
            Dev_NotifyWarning("Failed to get scores buffers, cannot run fix.");
            return false;
        }

        for (int i = int(goodIxs.Length) - 1; i >= 0; i--) {
            auto goodIx = goodIxs[i];
            auto otherIx = badIxs[badPIx];
            if (goodIx < otherIx) {
                // if the worst goodIx is less than the best otherIx, we can't sort any further
                break;
            }
            // swap the goodIx with the otherIx
            trace("Swapping good player " + goodIx + " with bad player " + otherIx + ' / goodPlayer: ' + rules.Scores[goodIx].User.Login);
            SwapPtrElementsInBuf(scoresBufFakeNod, goodIx, otherIx);
            SwapPtrElementsInBuf(scores3Buf, goodIx, otherIx);
            // // SwapPtrElementsInBuf(scores2Buf, goodIx, otherIx);
            // // FixIndexesInScoreStruct(scores2Buf, goodIx, otherIx);

            trace("Swapped good player " + goodIx + " with bad player " + otherIx + ' / goodPlayer: ' + rules.Scores[otherIx].User.Login);
            // increment the bad player index
            badPIx++;
            // if we run out of bad players, we're done
            if (badPIx >= int(badIxs.Length)) {
                trace("No more bad players to swap with good players.");
                break;
            }
        }

        trace("Scores sorted.");

        // now we need to trim the list
        uint newLen = Math::Min(goodIxs.Length + 2, rules.Scores.Length); // leave up to 2 extra players
        if (newLen > rules.Scores.Length) {
            Dev_NotifyWarning("New length " + newLen + " is greater than current length " + rules.Scores.Length + ", not trimming.");
            return true;
        }
        if (newLen == rules.Scores.Length) {
            // nothing to trim
            return true;
        }

        // trim buffer 1
        Dev::SetOffset(rules, _ArenaRulesScores.Offset + 0x8, newLen);
        // don't trim buffers 2 and 3
        // // Dev::SetOffset(rules, _ArenaRulesScores.Offset + 0x8 + 0x20, newLen);
        // // Dev::SetOffset(rules, _ArenaRulesScores.Offset + 0x8 + 0x30, newLen);
        trace('Trimmed scores!');
        return true;
    }

    void SwapPtrElementsInBuf(CMwNod@ buf, uint ix1, uint ix2) {
        if (buf is null) return;
        uint64 ptr1 = Dev::GetOffsetUint64(buf, ix1 * 0x8);
        uint64 ptr2 = Dev::GetOffsetUint64(buf, ix2 * 0x8);
        Dev::SetOffset(buf, ix1 * 0x8, ptr2);
        Dev::SetOffset(buf, ix2 * 0x8, ptr1);
    }

    bool IsUserConnected(CTrackManiaPlayerInfo@ user) {
        bool isDc = user is null || user.IsFakeUser || user.State == 0;
        return !isDc;
    }

    bool ranFix = false;

    void DrawExperimentalScoreFix() {
        if (Time::Now - nbDisconnectedPlayersUpdated > 500) {
            RefreshNbDisconnectedPlayers();
        }
        UI::SeparatorText("\\$fd0Experimental Server Lag Fix  " + Icons::ExclamationTriangle + " " + Icons::QuestionCircle);
        UI::TextWrapped("This removes disconnected players from the scoreboard. Can help a LOT on servers that have been on for a while.");
        UI::Text("Estimated\\$<\\$i time per frame\\$> to save: \\$4f4" + Text::Format("%.2f ms", float(nbDisconnectedPlayers) / 80.0) + "  \\$aaa("+nbDisconnectedPlayers+" DC'd players)");
        if (UI::Button("Run Fix")) {
            bool ran = RunFixDisconnectedPlayers();
            if (ran) {
                ranFix = true;
                RefreshNbDisconnectedPlayers();
                Notify("Done!", 5000);
            } else {
                NotifyWarning("Failed ton run fix :(.");
            }
        }
        if (!ranFix) return;

        UI::TextWrapped("\\$aaa\\$s  Note: there is a **small** risk that this fix will break the camera and pause menu. If that happens, hold down \\$<\\$8f8LEFT SHIFT\\$> to enable this button which will get you back to the menu. (This behavior was observed in testing for slightly\\$<\\$i different\\$> methods. It is not expected to happen, but better safe than sorry.)");
        bool disableExit = !UI::IsKeyDown(UI::Key::LeftShift);

        UI::BeginDisabled(disableExit);
        if (UI::ButtonColored("Force Exit Map (Emergency)", 0.05, 0.5, 0.5)) {
            auto app = cast<CTrackMania>(GetApp());
            app.BackToMainMenu();
            Notify("Forced exit from map.", 5000);
        }
        UI::EndDisabled();
    }
}
