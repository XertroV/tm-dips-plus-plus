
namespace PS {
    PlayerState@[] players;
    // offset by 0x04000000 (so 0x400000a is index 0xa)
    PlayerState@[] vehicleIdToPlayers;
    PlayerState@ localPlayer;
    PlayerState@ viewedPlayer;
    uint guiPlayerMwId;

    PlayerState@ GetPlayerFromVehicleId(uint id) {
        id = id & 0x000fffff;
        if (id >= vehicleIdToPlayers.Length) return null;
        return vehicleIdToPlayers[id];
    }

    void ClearPlayers() {
        players.RemoveRange(0, players.Length);
        vehicleIdToPlayers.RemoveRange(0, vehicleIdToPlayers.Length);
        @localPlayer = null;
        @viewedPlayer = null;
        guiPlayerMwId = 0;
    }

    bool wasInvalidRulesTime = false;
    uint lastUpdateNonce = 0;

    /// current playground must not be null
    void UpdatePlayers() {
        lastUpdateNonce = Math::Max(Time::Now, lastUpdateNonce + 1);
        auto cp = cast<CSmArenaClient>(GetApp().CurrentPlayground);

        // todo: refactor this to use NSmPlayer_Mgr

        // avoid reading positions when the rules are invalid, or the frame after
        bool rulesTimeInvalid = InvalidRulesTime(cp);
        bool exitEarly = rulesTimeInvalid || wasInvalidRulesTime;
        wasInvalidRulesTime = rulesTimeInvalid;
        if (exitEarly) {
            return;
        }

        guiPlayerMwId = GetViewedPlayerMwId(cp);
        if (MagicSpectate::IsActive()) {
            guiPlayerMwId = MagicSpectate::GetTarget().playerScoreMwId;
        }
        SortPlayersAndUpdateVehicleIds(cp);
        UpdateVehicleStates();
        // when opponents are off
        if (nbPlayerVisStates <= 1 && cp.Players.Length > 1) {
            TellArenaIfaceToGetPositionData();
            UpdatePlayersAsNeededFromCSmPlayer();
        }

        if (MatchDD2::lastMapMatchesAnyDD2Uid) TriggerCheck_Update();
        else if (g_CustomMap !is null) g_CustomMap.TriggerCheck_Update();
    }

    void SortPlayersAndUpdateVehicleIds(CSmArenaClient@ cp) {
        auto nbPlayers = cp.Players.Length;
        bool playersChanged = nbPlayers != players.Length;
        if (playersChanged) players.Reserve(nbPlayers);
        uint playerMwId;
        CSmPlayer@ gamePlayer;
        PlayerState@ player;
        PlayerState@ p2;
        uint j;

        for (uint i = 0; i < nbPlayers; i++) {
            @gamePlayer = cast<CSmPlayer>(cp.Players[i]);
            if (gamePlayer is null) {
                continue;
            }
            if (i >= players.Length) {
                // must be a new player
                @player = PlayerState(gamePlayer);
                players.InsertLast(player);
                EmitGlobal_NewPlayer(player);
            } else {
                @player = players[i];
            }

            if (player is null) {
                // ~~end of the known list of players,~~
                throw("null player");
            }

            playerMwId = gamePlayer.User.Id.Value;
            if (player.playerScoreMwId != playerMwId) {
                // need to reorder
                bool fixedReorder = false;
                for (j = i + 1; j < players.Length; j++) {
                    @p2 = players[j];
                    if (p2.playerScoreMwId == playerMwId) {
                        // found the player that should be here, swap with player
                        @players[j] = player;
                        @players[i] = p2;
                        @player = p2;
                        fixedReorder = true;
                        break;
                    }
                }
                if (!fixedReorder) {
                    // player is new
                    @player = PlayerState(gamePlayer);
                    if (i == players.Length) {
                        players.InsertLast(player);
                    } else {
                        players.InsertAt(i, player);
                    }
                    EmitGlobal_NewPlayer(player);
                }
            }

            // player and gamePlayer match
            if (player.playerScoreMwId != playerMwId) {
                throw("Player id mismatch: " + player.playerScoreMwId + " -> " + playerMwId);
            }

            player.Reset();
            player.Update(gamePlayer);
            if (localPlayer is null && player.isLocal) {
                @localPlayer = player;
            }
            if (player.isViewed) {
                @viewedPlayer = player;
            }

            // if
            // auto ps = GetPlayerState(player);
            //     if (ps is null) {
            //         @ps = PlayerState(player);
            //         PS::players.InsertLast(ps);
            //     }
            //     ps.UpdateVehicleId();
            // }
        }

        // find players that left
        if (players.Length > nbPlayers) {
            for (uint i = nbPlayers; i < players.Length; i++) {
                @player = players[i];
                if (player is null) throw("null player");
                player.Reset();
                auto ix = player.lastVehicleId & 0xFFFFFF;
                if (ix < vehicleIdToPlayers.Length && vehicleIdToPlayers[ix] !is null) {
                    if (vehicleIdToPlayers[ix].playerScoreMwId == player.playerScoreMwId) {
                        @vehicleIdToPlayers[ix] = null;
                    }
                }
                EmitGlobal_PlayerLeft(player);
            }
            players.RemoveRange(nbPlayers, players.Length - nbPlayers);
        }
    }

    void UpdateVehicleId(PlayerState@ player, uint newEntId) {
        auto lastId = player.lastVehicleId;
        bool removeOld = lastId < 0x3000000 && lastId & 0x2000000 > 0;
        bool addNew = newEntId < 0x3000000 && newEntId & 0x2000000 > 0;
        auto lastIx = lastId & 0xFFFFFF;
        auto newIx = newEntId & 0xFFFFFF;
        bool badOld = removeOld && lastIx > 100000;
        bool badNew = addNew && newIx > 100000;
        if (badOld || badNew) {
            NotifyWarning("Invalid vehicle id: " + Text::Format("0x%08x", lastId) + " -> " + Text::Format("0x%08x", newEntId));
            return;
        }
        if (removeOld) {
            if (lastIx >= vehicleIdToPlayers.Length) {
                NotifyWarning("Invalid vehicle id: " + lastId);
                return;
            }
            @vehicleIdToPlayers[lastIx] = null;

        }
        if (addNew) {
            if (newIx >= vehicleIdToPlayers.Length) {
                vehicleIdToPlayers.Resize(newIx + 1);
            }
            @vehicleIdToPlayers[newIx] = player;
        }
    }

    uint debug_NbVisStates;
    uint nbPlayerVisStates = 0;
    array<CSceneVehicleVis@>@ UpdateVehicleStates() {
        array<CSceneVehicleVis@>@ viss = VehicleState::GetAllVis(GetApp().GameScene);
        nbPlayerVisStates = 0;
        debug_NbVisStates = viss.Length;
        if (viss is null) throw("Update Vehicle State: null vis");
        uint nbVehicles = viss.Length;
        CSceneVehicleVis@ vis;
        PlayerState@ player;
        uint entId;
        for (uint i = 0; i < nbVehicles; i++) {
            @vis = viss[i];
            if (vis is null) throw("Update Vehicle State: null vis");
            entId = Dev::GetOffsetUint32(vis, 0);
            if (entId > 0x3000000 || entId & 0x2000000 == 0) continue;
            nbPlayerVisStates++;
            auto ix = entId & 0xFFFFFF;
            if (ix >= vehicleIdToPlayers.Length) {
                trace("Invalid vehicle id: " + Text::Format("0x%08x", entId));
                continue;
            } else {
                @player = vehicleIdToPlayers[ix];
            }
            if (player !is null) player.UpdateVehicleState(vis);
            else {
                trace("Unknown vehicle id: " + Text::Format("0x%08x", entId));
            }
            // this happens on any snowcar map:
            // else trace("Player is null for valid vehicle id: " + Text::Format("0x%08x", entId));
        }
        return viss;
    }

    // we do this when opponents are off
    void UpdatePlayersAsNeededFromCSmPlayer() {
        uint nbPlayers = players.Length;
        for (uint i = 0; i < nbPlayers; i++) {
            players[i].UpdateVehicleFromCSmPlayer();
        }
    }

    bool InvalidRulesTime(CSmArenaClient@ cp) {
        if (cp is null || cp.Arena is null) return true;
        auto rules = cp.Arena.Rules;
        if (rules is null) return true;
        return int(rules.RulesStateStartTime) < 0
            || rules.RulesStateStartTime >= rules.RulesStateEndTime;
    }

    enum UpdateMethod {
        None = 0,
        CSmPlayer = 1,
        CSceneVehicleVis = 2
    }
}




void EmitGlobal_NewPlayer(PlayerState@ player) {
    trace('New player: ' + player.playerName + ' (' + player.playerLogin + ')');
}

void EmitGlobal_PlayerLeft(PlayerState@ player) {
    trace('Player left: ' + player.playerName + ' (' + player.playerLogin + ')');
    player.hasLeftGame = true;
}
