enum DownloadConsentStage {
    None,
    Prompting,
    Accepted,
    Declined
}

const int AUX_PROMPT_WIN_FLAGS = UI::WindowFlags::NoResize | UI::WindowFlags::NoCollapse | UI::WindowFlags::NoMove | UI::WindowFlags::NoSavedSettings;




namespace AuxiliaryAssets {
    class AuxAssetInfo {
        string url;
        string localPath;
        string type;

        AuxAssetInfo(const string &in url, const string &in localPath, const string &in type) {
            this.url = url;
            this.localPath = localPath;
            this.type = type;
        }
    }

    // todo: we should save the URL to a file in aux asset directories because otherwise there's no way to tell where they came from.
    // todo: maybe we should keep an sqlite DB of all the downloaded files, maps they're used on, base url, filename, etc.

    AuxAssetInfo@[] assetsToDownload;
    string _specUrlHash = "";
    string urlPrefix;

    // Manage user download opt-in
    string currentAuxSourceName = "<Unk\\$f88nown>";
    DownloadConsentStage userDownloadConsentStage = DownloadConsentStage::None;

    bool DidUserDecline() { return userDownloadConsentStage == DownloadConsentStage::Declined; }
    bool DidUserAccept() { return userDownloadConsentStage == DownloadConsentStage::Accepted; }
    bool IsPrompting() { return userDownloadConsentStage == DownloadConsentStage::Prompting; }
    void ForceShowPrompt() { userDownloadConsentStage = DownloadConsentStage::Prompting; }

    // Called when we are about to load auxiliary assets.
    void Begin(const string &in sourceName) {
        currentAuxSourceName = sourceName;
        userDownloadConsentStage = DownloadConsentStage::Prompting;
    }

    void DrawPrompt() {
        if (userDownloadConsentStage != DownloadConsentStage::Prompting) return;
        float windowPropHeight = 0.6;
        vec2 windowSize = vec2(Math::Clamp(g_screen.x * 0.4, 400, 1000), g_screen.y * windowPropHeight);
        vec2 windowPos = g_screen / 2. + vec2(-windowSize.x/2, -g_screen.y * windowPropHeight / 2);

        UI::SetNextWindowPos(int(windowPos.x), int(windowPos.y), UI::Cond::Always);
        UI::SetNextWindowSize(int(windowSize.x), int(windowSize.y), UI::Cond::Always);

        UI::PushFont(UI::Font::Default20);
        if (UI::Begin("Dips++ | Map Assets Download", AUX_PROMPT_WIN_FLAGS)) {
            auto avail = UI::GetContentRegionAvail();
            auto itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing);
            auto framePadding = UI::GetStyleVarVec2(UI::StyleVar::FramePadding);

            UI::AlignTextToFramePadding();
            UI::TextWrapped("\\$<" + currentAuxSourceName + "\\$> has assets! Install them to experience the map fully.");

            DrawAssetDownloadSummary();

            avail = UI::GetContentRegionAvail();
            auto buttonHeight = UI::GetTextLineHeight() * 1.5;
            auto childHeight = avail.y - buttonHeight * 2 - itemSpacing.y;
            if (UI::BeginChild("asset-prev", vec2(-1, childHeight))) {
                DrawAssetDownloadPreview();
            }
            UI::EndChild();

            UI::SeparatorText("Download?");
            if (UI::ButtonColored("No, skip", 0.1, 0.5, 0.4)) {
                userDownloadConsentStage = DownloadConsentStage::Declined;
                NotifyWarning("Auxiliary assets download skipped.");
            }
            UI::SameLine();
            avail = UI::GetContentRegionAvail();
            float yesBtnWidth = Draw::MeasureString("Yes, download").x + framePadding.x;
            float gapWidth = Math::Max(avail.x - yesBtnWidth - itemSpacing.x, 0.0);
            UI::SetCursorPos(UI::GetCursorPos() + vec2(gapWidth, 0));
            if (UI::ButtonColored("Yes, download", 0.4, 0.5, 0.4)) {
                userDownloadConsentStage = DownloadConsentStage::Accepted;
            }
        }
        UI::End();
        UI::PopFont();
    }

    void DrawAssetDownloadSummary() {
        UI::Text("# Downloads: \\$afb" + assetsToDownload.Length);
        UI::AlignTextToFramePadding();
        UI::PushFont(UI::Font::DefaultMono);
        ClickableLabel("Base URL", urlPrefix);
        UI::PopFont();

        UI::AlignTextToFramePadding();
        UI::Text("Assets to download from \\$<" + currentAuxSourceName + "\\$>:");
    }

    void DrawAssetDownloadPreview() {
        if (assetsToDownload.Length == 0) {
            UI::AlignTextToFramePadding();
            UI::Text("Asset list is empty.");
            return;
        }

        UI::Indent();

        auto assetNumCursorMod = vec2(Draw::MeasureString("0000").x, 0);

        for (uint i = 0; i < assetsToDownload.Length; i++) {
            AuxAssetInfo@ asset = assetsToDownload[i];
            // UI::Text(asset.type + ": " + asset.localPath);
            auto ty = asset.type == "audio" ? "\\$8cf" + Icons::VolumeUp
                    : asset.type == "image" ? "\\$8fc" + Icons::PictureO
                    : Icons::File;
            auto pos = UI::GetCursorPos();
            UI::Text(Text::Format("%2d.", i + 1));
            UI::SetCursorPos(pos + assetNumCursorMod);
            UI::Text(ty + " - " + asset.url.Replace(urlPrefix, "\\$<\\$aaa<BaseURL>/\\$>"));
            // UI::PushFont(UI::Font::DefaultMono);
            // UI::Text(asset.url.Replace(urlPrefix, "\\$<\\$aaa<BaseURL>/\\$>"));
            // UI::PopFont();
        }

        UI::Unindent();
    }

    void Load(Json::Value@ auxSpec, const string &in specUrl) {
        if (auxSpec is null) return;

        _specUrlHash = Crypto::MD5(specUrl).SubStr(0, 16);
        WriteSpecUrlHashToFile(specUrl);

        urlPrefix = "";
        bool hasPrefix = false;
        if (auxSpec.HasKey("info") && auxSpec["info"].HasKey("urlPrefix")) {
            urlPrefix = string(auxSpec["info"]["urlPrefix"]);
            if (!urlPrefix.EndsWith("/")) {
                // error
                NotifyWarning("AuxiliaryAssets: URL prefix does not end with '/': " + urlPrefix);
                return;
            }
            hasPrefix = true;
        } else {
            NotifyWarning("AuxiliaryAssets: No URL prefix found in aux spec.");
        }

        if (hasPrefix && auxSpec.HasKey("assets")) {
            Json::Value@ assets = auxSpec["assets"];

            if (assets.HasKey("audios")) {
                Json::Value@ audios = assets["audios"];
                for (uint i = 0; i < audios.Length; i++) {
                    Json::Value@ audio = audios[i];
                    if (audio.HasKey("assets")) {
                        Json::Value@ audioFiles = audio["assets"];
                        for (uint j = 0; j < audioFiles.Length; j++) {
                            string filename = string(audioFiles[j]);
                            string url = urlPrefix + filename;
                            string localPath = GetLocalPath("audio/" + filename);
                            assetsToDownload.InsertLast(AuxAssetInfo(url, localPath, "audio"));
                        }
                    }
                }
            }

            if (assets.HasKey("images")) {
                Json::Value@ images = assets["images"];
                for (uint i = 0; i < images.Length; i++) {
                    Json::Value@ image = images[i];
                    if (image.HasKey("assets")) {
                        Json::Value@ imageFiles = image["assets"];
                        for (uint j = 0; j < imageFiles.Length; j++) {
                            string filename = string(imageFiles[j]);
                            string url = urlPrefix + filename;
                            string localPath = GetLocalPath("img/" + filename);
                            assetsToDownload.InsertLast(AuxAssetInfo(url, localPath, "image"));
                        }
                    }
                }
            }
        }

        if (assetsToDownload.Length > 0) {
            startnew(CoroutineFunc(PromptAndDownloadAssets));
        }
    }

    void PromptAndDownloadAssets() {
        // activate prompt
        userDownloadConsentStage = DownloadConsentStage::Prompting;

        while (userDownloadConsentStage == DownloadConsentStage::Prompting) {
            yield(); // wait for user to respond
        }

        if (userDownloadConsentStage == DownloadConsentStage::Declined) {
            NotifyWarning("Auxiliary assets download declined.");
            return;
        }

        if (userDownloadConsentStage != DownloadConsentStage::Accepted) {
            NotifyWarning("Auxiliary assets download not accepted. (Unexpected)");
            return;
        }

        // we went through the prompt and user accepted
        NotifySuccess("Downloading " + assetsToDownload.Length + " auxiliary assets...");
        for (uint i = 0; i < assetsToDownload.Length; i++) {
            AuxAssetInfo@ asset = assetsToDownload[i];
            AssetDownload@ download = AssetDownload(asset.url, IO::FromStorageFolder(asset.localPath));
            g_ActiveDownloads.InsertLast(download);
            download.Start();
            yield();
        }
    }

    string GetLocalPath(const string &in filename) {
        return "aux_assets/" + _specUrlHash + "/" + filename;
    }

    void WriteSpecUrlHashToFile(const string &in specUrl) {
        // Write the spec URL hash to a file in the aux assets directory
        string auxDir = IO::FromStorageFolder("aux_assets/" + _specUrlHash);
        if (!IO::FolderExists(auxDir)) IO::CreateFolder(auxDir, true);
        IO::File file(auxDir + "/spec_url.txt", IO::FileMode::Write);
        file.Write(specUrl);
        file.Close();
    }
}
