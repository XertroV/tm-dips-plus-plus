/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
//
const string StorageBaseDir = IO::FromStorageFolder("");
const string AudioBaseDir = IO::FromStorageFolder("Audio/");
// const string AudioS3SourceUrl = "https://xert.s3.us-east-1.wasabisys.com/d++/audio/";
const string AudioS3SourceUrl = "https://assets.xk.io/d++/audio/";
const string AssetsS3SourceUrl = "https://assets.xk.io/d++/";

string Audio_GetPath(const string &in name) {
    if (name.Contains(StorageBaseDir)) return name;
    return AudioBaseDir + name;
}

dictionary _CachedAudioSamples;

Audio::Sample@ Audio_LoadFromCache_Async(const string &in path) {
    while (!IO::FileExists(Audio_GetPath(path))) {
        yield();
    }
    if (!_CachedAudioSamples.Exists(path)) {
        @_CachedAudioSamples[path] = null;
        @_CachedAudioSamples[path] = Audio::LoadSampleFromAbsolutePath(Audio_GetPath(path));
    }
    while (cast<Audio::Sample>(_CachedAudioSamples[path]) is null) {
        yield();
    }
    // add a yield so we find out where it is called from UI code
    yield();
    return cast<Audio::Sample>(_CachedAudioSamples[path]);
}

bool AudioFilesExist(const string[]@ names, bool warnIfMissing = true) {
    for (uint i = 0; i < names.Length; i++) {
        if (!IO::FileExists(Audio_GetPath(names[i]))) {
            warn("Missing audio file: " + names[i]);
            return false;
        }
    }
    return true;
}

bool StorageFileExists(const string &in name) {
    return IO::FileExists(IO::FromStorageFolder(name));
}

void RefreshAssets() {
    if (!IO::FolderExists(AudioBaseDir)) {
        IO::CreateFolder(AudioBaseDir);
    }

    AddNonAudioAssetDownloads();

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
    // AddArbitraryAssetDownload("img/dd2-ad.png");
    // AddArbitraryAssetDownload("img/dd2-c1.png");

    // AddArbitraryAssetDownload("img/dd2-c3.png");
    // AddArbitraryAssetDownload("img/dd2-c2.png");
}

const string MENU_ITEM_RELPATH = "Skins/Models/CharacterPilot/DeepDip2_MenuItem.zip";
const string MENU_ITEM2_RELPATH = "Skins/Models/CharacterPilot/DD2_SponsorsSign.zip";

void AddNonAudioAssetDownloads() {
    AddArbitraryAssetDownload("img/Deep_dip_2_logo.png");
    AddArbitraryAssetDownload("img/vae_square.png");
    AddArbitraryAssetDownload("img/vae.png");
    AddArbitraryAssetDownload("img/fanfare-spritesheet.png");
    GameFolderAssetDownload(MENU_ITEM_RELPATH);
    GameFolderAssetDownload(MENU_ITEM2_RELPATH);
    AddArbitraryAssetDownload("img/floor0.jpg");
    AddArbitraryAssetDownload("img/floor1.jpg");
    AddArbitraryAssetDownload("img/floor2.jpg");
    AddArbitraryAssetDownload("img/floor3.jpg");
    AddArbitraryAssetDownload("img/floor4.jpg");
    AddArbitraryAssetDownload("img/floor5.jpg");
    AddArbitraryAssetDownload("img/floor6.jpg");
    AddArbitraryAssetDownload("img/floor7.jpg");
    AddArbitraryAssetDownload("img/floor8.jpg");
    AddArbitraryAssetDownload("img/floor9.jpg");
    AddArbitraryAssetDownload("img/floor10.jpg");
    AddArbitraryAssetDownload("img/floor11.jpg");
    AddArbitraryAssetDownload("img/floor12.jpg");
    AddArbitraryAssetDownload("img/floor13.jpg");
    AddArbitraryAssetDownload("img/floor14.jpg");
    AddArbitraryAssetDownload("img/floor15.jpg");
    AddArbitraryAssetDownload("img/floor16.jpg");
    AddArbitraryAssetDownload("img/finish.jpg");
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
        auto body = req.String().SubStr(0, 100);
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
        uint failCount = 0;
        while (failCount < 3) {
            Net::HttpRequest@ req = Net::HttpGet(this.url);
            while (!req.Finished()) {
                yield();
            }
            this.finished = true;
            if (req.ResponseCode() == 200) {
                req.SaveToFile(this.path);
                DownloadProgress::Done();
                trace("Downloaded " + this.url + " to " + this.path);
                return;
            } else {
                NotifyWarning("Failed to download " + this.url);
                NotifyWarning("Response code: " + req.ResponseCode());
                auto body = req.String().SubStr(0, 100);
                NotifyWarning("Response body: " + body);
                failCount++;
                if (failCount >= 3) {
                    DownloadProgress::Error("Failed to download " + this.url);
                }
            }
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

void AddArbitraryAssetDownload(const string &in pathRelativeToStorage, bool force = false) {
    if (!force && StorageFileExists(pathRelativeToStorage)) {
        return;
    }
    auto path = IO::FromStorageFolder(pathRelativeToStorage);
    auto download = AssetDownload(AssetsS3SourceUrl + pathRelativeToStorage, path);
    g_ActiveDownloads.InsertLast(download);
}

void GameFolderAssetDownload(const string &in pathRelativeToStorage) {
    if (IO::FileExists(IO::FromUserGameFolder(pathRelativeToStorage))) {
        return;
    }
    auto path = IO::FromUserGameFolder(pathRelativeToStorage);
    auto download = AssetDownload(AssetsS3SourceUrl + pathRelativeToStorage, path);
    g_ActiveDownloads.InsertLast(download);
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


void PreloadCriticalSounds() {
    Meta::PluginCoroutine@[] coros;
    coros.InsertLast(AudioLoader("vt/volume_test.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Intro_Plugin_2.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_1_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_2_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_3_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_4_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_5_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_6_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_7_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_8_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_9_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_10_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_11_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_12_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_13_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_14_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_15_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Level_16_final.mp3").GetCoro());
    coros.InsertLast(AudioLoader("vl/Lvl_17_Finished.mp3").GetCoro());
    coros.InsertLast(AudioLoader("deep_dip_2.mp3").GetCoro());
    coros.InsertLast(AudioLoader("geep_gip_2.mp3").GetCoro());
    await(coros);
}

class AudioLoader {
    string path;
    Meta::PluginCoroutine@ coro;

    AudioLoader(const string &in path) {
        this.path = path;
        // yield here to ensure we don't make them all on one frame in case the assets already exist.
        yield();
        @coro = startnew(CoroutineFunc(DoLoad));
    }

    Meta::PluginCoroutine@ GetCoro() {
        return coro;
    }

    void DoLoad() {
        Audio_LoadFromCache_Async(path);
    }
}
