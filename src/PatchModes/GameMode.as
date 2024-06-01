const string CampaignScriptDir = "Scripts/Modes/TrackMania/";
const string CampaignScriptName = "TM_Campaign_Local.Script.txt";
const string PlayMapScriptName = "TM_PlayMap_Local.Script.txt";
// const string CampaignScriptPath = CampaignScriptDir + CampaignScriptName;
const string FakePrefix = "Titles/Trackmania/Scripts/Modes/TrackMania/";

enum PatchModeTarget {
    Campaign,
    PlayMap
}

void UpdateGameModes() {
    UpdateGameMode(PatchModeTarget::Campaign);
    UpdateGameMode(PatchModeTarget::PlayMap);
}

void UpdateGameMode(PatchModeTarget t) {
    auto textNod = GetGameModeTextScriptNod(t);
    if (textNod is null) return;
    trace('text nod okay');
    textNod.ReGenerate();
    string origScript = textNod.Text;
    textNod.Text = RunPatchML(origScript);
    textNod.MwAddRef();
}

CPlugFileTextScript@ GetGameModeTextScriptNod(PatchModeTarget t) {
    auto script = GetCampaignScriptFid(t);
    if (script is null) {
        warn("script FID null!");
        return null;
    }
    trace("script fid byte size: " + script.ByteSize);
    auto textNod = cast<CPlugFileTextScript>(Fids::Preload(script));
    if (textNod is null) {
        warn("Text nod is null");
        return null;
    }
    if (textNod.Text.Length == 0) {
        warn("text nod non null but zero length");
        return null;
    }
    return textNod;
}

CSystemFidFile@ GetCampaignScriptFid(PatchModeTarget t) {
    switch (t) {
        case PatchModeTarget::Campaign: return Fids::GetFake(FakePrefix + CampaignScriptName);
        case PatchModeTarget::PlayMap: return Fids::GetFake(FakePrefix + PlayMapScriptName);
    }
    return null;
}

void RevertGameModeChanges() {
    RevertGameModeChanges(PatchModeTarget::Campaign);
    RevertGameModeChanges(PatchModeTarget::PlayMap);
}

void RevertGameModeChanges(PatchModeTarget t) {
    auto textNod = GetGameModeTextScriptNod(t);
    if (textNod is null) return;
    textNod.ReGenerate();
}
