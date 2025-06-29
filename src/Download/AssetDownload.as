class AssetDownload {
    string url;
    string path;
    bool started;
    bool finished;
    bool hasError;
    string errorMessage;

    AssetDownload(const string &in url, const string &in path) {
        this.url = url;
        this.path = path;
        DownloadProgress::Add(1);
    }

    ~AssetDownload() {
        // This might be called when the object is destroyed, not necessarily when the download finishes.
        // The DoneCallback should be called explicitly when the download is complete.
    }

    void Start() {
        if (started) return;
        started = true;
        startnew(CoroutineFunc(this.RunDownload));
        CheckDestinationDir();
    }

    void CheckDestinationDir() {
        auto parts = this.path.Split("/");
        parts.RemoveLast();
        auto dir = string::Join(parts, "/");
        if (!IO::FileExists(dir) && !IO::FolderExists(dir)) {
            IO::CreateFolder(dir, true);
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
                return;
            } else {
                this.hasError = true;
                this.errorMessage = "Failed to download " + this.url + ": " + req.ResponseCode();
                warn(this.errorMessage);
                failCount++;
                if (failCount >= 3) {
                    DownloadProgress::Error(this.errorMessage);
                }
            }
        }
    }
}
