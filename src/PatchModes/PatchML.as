// Places where we'll add code

const string P_ON_END_RACE = """
			if (Event.IsEndRace) {
				Race::StopSkipScoresTable(Event.Player);""";

// Things we'll inject

// Sets a 60 second finish timeout
const string Patch_OnEndRace = """
				if (Map.MapInfo.MapUid == "%%MAPUID%%") {
					Race::Stop(Event.Player, 60000, -1);
				}""";

// The Logic

string RunPatchML(const string &in script) {
    auto patch = Patch_OnEndRace.Replace("%%MAPUID%%",
#if DEV
    """DeepDip2__The_Storm_Is_Here" || Map.MapInfo.MapUid == "dh2ewtzDJcWByHcAmI7j6rnqjga"""
#else
    """DeepDip2__The_Storm_Is_Here" || Map.MapInfo.MapUid == "DD2_Many_CPs_tOg3hwrWxPOR7l" || Map.MapInfo.MapUid == "DD2_CP_per_Floor_OAtP2rAwJ0"""
#endif
    );
	return script.Replace(P_ON_END_RACE, P_ON_END_RACE + "\n" + patch);
}
