const string AudioBaseDir = IO::FromStorageFolder("Audio/");
// const string AudioS3SourceUrl = "https://xert.s3.us-east-1.wasabisys.com/d++/audio/";
const string AudioS3SourceUrl = "https://assets.xk.io/d++/audio/";

string Audio_GetPath(const string &in name) {
    if (name.Contains(AudioBaseDir)) return name;
    return AudioBaseDir + name;
}


void RefreshAssets() {
    if (!IO::FolderExists(AudioBaseDir)) {
        IO::CreateFolder(AudioBaseDir);
    }
    auto @files = IO::IndexFolder(AudioBaseDir, true);
    files.SortAsc();
    // if (/* dev: force redownload */ true) {
    //     @files = {};
    // }
    auto @repoFiles = GetAudioAssetsRepositoryFiles();
    string[] newAssets;
    string[] remAssets;
    // print("Local files: " + Json::Write(files.ToJson()));
    // print("Repo files: " + Json::Write(repoFiles.ToJson()));

    // compare each index in files and repoFiles to figure out which we need to download or delete
    // they are ordered the same
    uint fix = 0, rix = 0;
    string file, repoFile;
    while (fix < files.Length && rix < repoFiles.Length) {
        file = files[fix].Replace(AudioBaseDir, "");
        repoFile = repoFiles[rix];
        // trace('comparing ' + file + ' to ' + repoFile);
        if (file < repoFile) {
            remAssets.InsertLast(file);
            fix++;
        } else if (file > repoFile) {
            newAssets.InsertLast(repoFile);
            rix++;
        } else {
            fix++;
            rix++;
        }
    }
    if (fix == files.Length) {
        for (uint i = rix; i < repoFiles.Length; i++) {
            newAssets.InsertLast(repoFiles[i]);
        }
    }
    if (rix == repoFiles.Length) {
        for (uint i = fix; i < files.Length; i++) {
            remAssets.InsertLast(files[i]);
        }
    }

    // print("New assets: " + Json::Write(newAssets.ToJson()));
    // print("Rem assets: " + Json::Write(remAssets.ToJson()));

    PushAssetDownloads(newAssets);
    DeleteAssets(remAssets);
}

string[] GetAudioAssetsRepositoryFiles() {
    Net::HttpRequest@ req = Net::HttpGet(AudioS3SourceUrl + "index.txt");
    while (!req.Finished()) {
        yield();
    }
    if (req.ResponseCode() == 200) {
        auto body = req.String();
        auto files = body.Split("\n");
        string[] ret = {};
        for (uint i = 0; i < files.Length; i++) {
            if (files[i].Length == 0) continue;
            ret.InsertLast(files[i].Trim());
        }
        return ret;
    } else {
        NotifyWarning("Failed to get audio assets index");
        NotifyWarning("Response code: " + req.ResponseCode());
        auto body = req.String();
        NotifyWarning("Response body: " + body);
        throw("Failed to get audio assets index");
    }
    return {};
}


class AssetDownload {
    string url;
    string path;
    AssetDownload(const string &in url, const string &in path) {
        this.url = url;
        this.path = path;
        DownloadProgress::Add(1);
    }

    ~AssetDownload() {
        this.DoneCallback();
    }

    bool started;
    bool finished;

    void Start() {
        if (started) return;
        started = true;
        startnew(CoroutineFunc(this.RunDownload));
        trace("Downloading " + this.url + " to " + this.path);
        CheckDestinationDir();
    }

    void CheckDestinationDir() {
        auto parts = this.path.Split("/");
        auto fileName = parts[parts.Length - 1];
        parts.RemoveLast();
        auto dir = string::Join(parts, "/");
        trace("Checking destination dir: " + dir);
        if (!IO::FileExists(dir) && !IO::FolderExists(dir)) {
            // create all directories up to the file, then a directory with the name of the file
            IO::CreateFolder(dir, true);
            trace("Created folder: " + dir);
            // // then remove the folder with the same name as the file (but not parent folders)
            // IO::DeleteFolder(path);
            // trace("Removed folder: " + path);
        }
    }

    void RunDownload() {
        Net::HttpRequest@ req = Net::HttpGet(this.url);
        while (!req.Finished()) {
            yield();
        }
        this.finished = true;
        if (req.ResponseCode() == 200) {
            req.SaveToFile(this.path);
            DownloadProgress::Done();
            trace("Downloaded " + this.url + " to " + this.path);
        } else {
            NotifyWarning("Failed to download " + this.url);
            NotifyWarning("Response code: " + req.ResponseCode());
            auto body = req.String();
            NotifyWarning("Response body: " + body);
            DownloadProgress::Error("Failed to download " + this.url);
        }
    }

    // for overriding
    void DoneCallback() {
        // trace("Download done (CB): " + this.url);
    }
}

AssetDownload@[] g_ActiveDownloads;

void PushAssetDownloads(const string[] &in urls) {
    for (uint i = 0; i < urls.Length; i++) {
        auto url = AudioS3SourceUrl + urls[i];
        auto path = Audio_GetPath(urls[i]);
        auto download = AssetDownload(url, path);
        g_ActiveDownloads.InsertLast(download);
    }
}

void DeleteAssets(const string[] &in paths) {
    for (uint i = 0; i < paths.Length; i++) {
        auto path = Audio_GetPath(paths[i]);
        if (IO::FileExists(path)) {
            print("[WOULD BE] Deleting file: " + path);
            // IO::Delete(path);
        }
    }
}

const int MAX_DLS = 30;

void UpdateDownloads() {
    if (g_ActiveDownloads.Length == 0) return;
    AssetDownload@ dl;
    for (int i = Math::Min(MAX_DLS, g_ActiveDownloads.Length) - 1; i >= 0; i--) {
        @dl = g_ActiveDownloads[i];
        if (dl is null || dl.finished) {
            g_ActiveDownloads.RemoveAt(i);
        }
        if (!dl.started) {
            dl.Start();
        }
    }
}
