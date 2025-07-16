namespace PlayerSpecInfo {
	int64 _lastUpdated = 0;

	void Handle(Json::Value@ msg) {
		string newWsid, newUid;
		int64 newTotalMapTime = -1, serverNowTs = -1;
		bool gotWsid = JsonX::SafeGetString(msg, "wsid", newWsid);
		bool gotUid = JsonX::SafeGetString(msg, "uid", newUid);
		JsonX::SafeGetInt64(msg, "total_map_time", newTotalMapTime);
		JsonX::SafeGetInt64(msg, "now_ts", serverNowTs);
		if (!gotWsid || !gotUid) {
			warn("PlayerSpecInfo message missing wsid or uid: " + Json::Write(msg));
			return;
		}
		_OnRecvUpdate(newWsid, newUid, newTotalMapTime, serverNowTs);
	}

	void _OnRecvUpdate(const string &in wsid, const string &in uid, int64 totalMapTime, int64 serverNowTs) {
		_lastUpdated = Time::Now;
		if (lastMapUid.GetName() != uid) {
			dev_trace("PlayerSpecInfo::_OnRecvUpdate: unexpected map uid: " + uid + ", expected: " + lastMapUid.GetName());
			return;
		}
		auto login = WSIDToLogin(wsid);
		if (lastPlayerLoginId.GetName() != login) {
			dev_trace("PlayerSpecInfo::_OnRecvUpdate: unexpected player login: " + login + ", expected: " + lastPlayerLoginId.GetName());
			return;
		}
		specTotalMapTime = totalMapTime;
		specServerNowTs = serverNowTs;
	}

	int64 specRaceTime = -1, specTotalMapTime = -1, specServerNowTs = -1;

	const int64 PLAYER_SPEC_INFO_UPDATE = 21 * 1000;
	int64 lastSentUpdate = 0;
	MwId lastMapUid;
	MwId lastPlayerLoginId;

	void Update(PlayerState@ specTarget = null) {
		if (specTarget is null) @specTarget = PS::viewedPlayer;
		if (specTarget is null) return;
#if !DEV
		if (specTarget.isLocal) return;
#endif
		auto mapUidValue = CurrMap::lastMapMwId;
		if (mapUidValue == 0) return;

		specRaceTime = specTarget.raceTime;

		bool resetValues =
			lastPlayerLoginId.Value != specTarget.playerScoreMwId
			|| lastMapUid.Value != mapUidValue;
		// rate limit update requests to PLAYER_SPEC_INFO_UPDATE ms
		bool stale = resetValues || Time::Now - lastSentUpdate > PLAYER_SPEC_INFO_UPDATE;
		if (!stale) return;
		lastPlayerLoginId.Value = specTarget.playerScoreMwId;
		lastMapUid.Value = mapUidValue;
		lastSentUpdate = Time::Now;

		PushMessage(GetPlayersSpecInfoMsg(specTarget.playerWsid, lastMapUid.GetName()));
		if (resetValues) {
			specServerNowTs = specTotalMapTime = -1;
		}
	}

	// [Setting]
	const Meta::RunContext fixChronoCtx = Meta::RunContext::AfterScripts;

	void SetUpFixChrono() {
		Meta::StartWithRunContext(fixChronoCtx, FixChrono);
	}

	void FixChrono() {
		if (specRaceTime < 0) return;
		// get chrono layer
		auto cmap = GetApp().Network.ClientManiaAppPlayground;
		if (cmap is null || cmap.UILayers.Length < 6) return;
		// Chrono at ix 5
		CGameUILayer@ chronoLayer = cmap.UILayers[5];
		if (chronoLayer is null) return;
		if (chronoLayer.LocalPage is null) return;
		auto labelChrono = cast<CGameManialinkLabel>(chronoLayer.LocalPage.GetFirstChild("label-chrono"));
		labelChrono.Value = Time::Format(specRaceTime, true, true, false, true);
		auto chronoCtrl = cast<CControlLabel>(labelChrono.Control);
		chronoCtrl.Label = labelChrono.Value;
	}
}
