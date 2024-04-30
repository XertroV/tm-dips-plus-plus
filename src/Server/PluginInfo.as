string GetPluginInfo() {
    auto p = Meta::ExecutingPlugin();
    string[] infos;
    infos.InsertLast("Name:" + p.Name);
    infos.InsertLast("Version:" + p.Version);
    infos.InsertLast("Type:" + tostring(p.Type));
    infos.InsertLast("Source:" + tostring(p.Source));
    infos.InsertLast("SourceP:" + p.SourcePath.Replace(IO::FromDataFolder(""), ""));
    infos.InsertLast("SigLvl:" + tostring(p.SignatureLevel));
    return string::Join(infos, "\n");
}

string GetGameInfo() {
    auto app = GetApp();
    auto platform = app.SystemPlatform;
    string[] infos;
    infos.InsertLast("ExeVersion:" + platform.ExeVersion);
    infos.InsertLast("Timezone:" + platform.CurrentTimezoneTimeOffset);
    infos.InsertLast("ExtraTool_Info:" + platform.ExtraTool_Info);
    infos.InsertLast("ExtraTool_Data:" + platform.ExtraTool_Data);
    return string::Join(infos, "\n");
}

string GetGameRunningInfo() {
    auto app = GetApp();
    auto platform = app.SystemPlatform;
    string[] infos;
    infos.InsertLast("Now:" + Time::Now);
    infos.InsertLast("SinceInit:" + app.TimeSinceInitMs);
    infos.InsertLast("TS:" + Time::Stamp);
    return string::Join(infos, "\n");
}

// string ServerInfo() {
//     auto net = cast<CTrackManiaNetwork>(GetApp().Network);
//     auto si = cast<CTrackManiaNetworkServerInfo>(net.ServerInfo);
//     si.ServerLogin;
// }
