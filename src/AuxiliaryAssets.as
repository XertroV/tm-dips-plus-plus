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

    void Load(Json::Value@ auxSpec, const string &in specUrl) {
        if (auxSpec is null) return;

        _specUrlHash = Crypto::MD5(specUrl).SubStr(0, 16);

        string urlPrefix = "";
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
        // TODO: UI: Display a popup asking the user if they want to download the assets.
        // The popup should show the number of audio and image files.
        // If the user confirms, set downloadConfirmed to true and proceed with downloads.
        // If the user cancels, set downloadConfirmed to false and notify them.

        // For now, automatically download (replace with UI logic later)
        NotifyWarning("Downloading " + assetsToDownload.Length + " auxiliary assets...");
        for (uint i = 0; i < assetsToDownload.Length; i++) {
            AuxAssetInfo@ asset = assetsToDownload[i];
            AssetDownload@ download = AssetDownload(asset.url, IO::FromStorageFolder(asset.localPath));
            g_ActiveDownloads.InsertLast(download);
            download.Start();
        }
    }

    string GetLocalPath(const string &in filename) {
        return "aux_assets/" + _specUrlHash + "/" + filename;
    }
}
