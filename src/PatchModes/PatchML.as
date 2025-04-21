// Places where we'll add code

const string P_ON_END_RACE = """
			if (Event.IsEndRace) {
				Race::StopSkipScoresTable(Event.Player);""";

// Things we'll inject

// Sets a 30 second finish timeout for maps that want that.
const string Patch_OnEndRace = """
				declare Integer[Text] DPP_MapUidToFinishTimeout for This;
				if (DPP_MapUidToFinishTimeout.count == 0) {
%%POPULATE_MAPUIDS%%
				log("Populated DPP_MapUidToFinishTimeout");
				}
				if (DPP_MapUidToFinishTimeout.existskey(Map.MapInfo.MapUid)) {
					declare _Msg = "MapUidToFinishTimeout: " ^ Map.MapInfo.MapUid ^ " -> " ^ DPP_MapUidToFinishTimeout[Map.MapInfo.MapUid];
					log(_Msg);
					Race::Stop(Event.Player, DPP_MapUidToFinishTimeout[Map.MapInfo.MapUid], -1);
				}
				""";

// The Logic

string RunPatchML(const string &in script) {
	string template = """					DPP_MapUidToFinishTimeout["%UID%"] = %TIMEOUT_MS%;""" + "\n";
	string populateDefaultUids;
	populateDefaultUids += template.Replace("%UID%", "DeepDip2__The_Storm_Is_Here").Replace("%TIMEOUT_MS%", "30000");
	populateDefaultUids += template.Replace("%UID%", "DD2_Many_CPs_tOg3hwrWxPOR7l").Replace("%TIMEOUT_MS%", "30000");
	populateDefaultUids += template.Replace("%UID%", "DD2_CP_per_Floor_OAtP2rAwJ0").Replace("%TIMEOUT_MS%", "30000");
	populateDefaultUids += template.Replace("%UID%", "dh2ewtzDJcWByHcAmI7j6rnqjga").Replace("%TIMEOUT_MS%", "30000");
	auto patch = Patch_OnEndRace.Replace("%%POPULATE_MAPUIDS%%", populateDefaultUids);
	// remove trailing \n
	patch = patch.SubStr(0, populateDefaultUids.Length - 1);
    print("Patch: \\n\n" + patch);
	// return script;
	return script.Replace(P_ON_END_RACE, P_ON_END_RACE + "\n" + patch);
}


#if DEV
void Dev_SetupIntercepts() {
	Dev::InterceptProc("CGameManiaTitleControlScriptAPI", "PlayMapList", _PlayMapScript);
}

bool _PlayMapScript_Reentrancy_AllowAll = false;
bool _PlayMapScript(CMwStack &in stack, CMwNod@ nod) {
	if (_PlayMapScript_Reentrancy_AllowAll) {
		return true;
	}
	auto settingsXml = stack.CurrentString(0);
	auto mode = stack.CurrentWString(1);
	auto mapList = stack.CurrentBufferWString(2);
	string mapListStr = "";
	for (int i = 0; i < mapList.Length; i++) {
		if (i > 0) mapListStr += ", ";
		mapListStr += mapList[i];
	}
	print("PlayMapList: \nSettingsXML: " + settingsXml + " \nMode: " + mode + " \nMaps: " + mapListStr);

	// blocking path
	if (settingsXml.Length > 0 && !settingsXml.Contains("S_ScriptEnvironment")) {
		auto insertIx = settingsXml.IndexOfI("<setting");
		if (insertIx == -1) insertIx = 6; // after `<root>`
		auto toInsert = '<setting name="S_ScriptEnvironment" type="text" value="development"/>';
		settingsXml = settingsXml.SubStr(0, insertIx) + toInsert + settingsXml.SubStr(insertIx);
		print("PlayMapList - new SettingsXML: " + settingsXml);
		_PlayMapScript_Reentrancy_AllowAll = true;
		cast<CGameManiaTitleControlScriptAPI>(nod).PlayMapList(mapList, mode, settingsXml);
		_PlayMapScript_Reentrancy_AllowAll = false;
		return false;
	}

	return true;
}
#endif
