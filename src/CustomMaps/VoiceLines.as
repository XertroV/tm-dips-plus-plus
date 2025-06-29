namespace CustomVL {
    void StartTestVoiceLine_Async(IVoiceLineParams@ params) {
        string filePath;
        DTexture@ imageTexture;
        if (params.isUrl) {
            Notify("Downloading VL and image. It will start automatically.");
            auto fileName = Path::GetFileName(params.pathOrUrl);
            if (fileName.Length == 0) throw("cannot get file name from URL: " + params.pathOrUrl);
            filePath = TempFiles::GetTempFilesLoc(fileName);
            auto dlFile = Downloader(params.pathOrUrl, filePath);
            if (params.imagePathOrUrl.Length > 0) {
                auto imageFileName = Path::GetFileName(params.imagePathOrUrl);
                if (imageFileName.Length == 0) throw("cannot get file name from URL: " + params.imagePathOrUrl);
                auto imageFilePath = TempFiles::GetTempFilesLoc(imageFileName);
                auto dlImage = Downloader(params.imagePathOrUrl, imageFilePath);
                await(dlImage.dlCoro);
                @imageTexture = DTexture(imageFilePath);
            }
            await(dlFile.dlCoro);
        }
        AddSubtitleAnimation_PlayAnywhere(SubtitlesAnim("", imageTexture !is null, params.subtitles.Trim(), imageTexture));
        AudioChain({filePath}).WithPlayAnywhere().WithAwaitLoaded().Play();
    }

    awaitable@ StartTestVoiceLine(IVoiceLineParams@ params) {
        return startnew(CoroutineFuncUserdata(_StartTestVoiceLine_Async), params);
    }

    void _StartTestVoiceLine_Async(ref@ params) {
        StartTestVoiceLine_Async(cast<IVoiceLineParams>(params));
    }

    class Downloader {
        string url;
        string filePath;
        awaitable@ dlCoro;

        Downloader(const string &in url, const string &in filePath) {
            this.url = url;
            this.filePath = filePath;
            @dlCoro = startnew(CoroutineFunc(Download));
        }

        protected void Download() {
            if (IO::FileExists(filePath)) {
                return;
            }
            Net::HttpRequest@ req = Net::HttpGet(url);
            while (!req.Finished()) {
                yield();
            }
            auto respCode = req.ResponseCode();
            dev_trace("response code: " + respCode);
            if (respCode >= 200 && respCode < 299) {
                auto data = req.Buffer();
                IO::File f(filePath, IO::FileMode::Write);
                f.Write(data);
                f.Close();
                dev_trace("Downloader success: " + filePath);
                return;
            }
            warn("Downloader failed: " + filePath + " " + respCode + " ");
        }
    }





    void Test() {
        // print("VLs test");
        // auto vls = VoiceLinesSpec();
        // print("VLs test - insert");
        // vls.InsertLine(VoiceLineSpec(), 0);
        // print("VLs test - j = tojson");
        // auto j = vls.ToJson();
        // print("VLs test - vls2 = VoiceLinesSpec(j)");
        // auto vls2 = VoiceLinesSpec(j);
        // print("VLs test - vls2 = VoiceLinesSpec(j) - done");
        // auto j2 = vls2.ToJson();
        // print("j1: " + Json::Write(j));
        // print("j2: " + Json::Write(j2));
    }

    enum AudioMode {
        ThruGame = 0, ThruPlugin = 1
    }

    class VoiceLinesSpec {
        AudioMode mode = AudioMode::ThruGame;
        VoiceLineSpec@[]@ lines = {};

        VoiceLinesSpec() {}

        VoiceLinesSpec(const string &in jsonStr) {
            InitFromJson(Json::Parse(jsonStr));
        }

        VoiceLinesSpec(Json::Value@ j) {
            InitFromJson(j);
        }

        void InitFromJson(Json::Value@ j) {
            if (j is null) return;
            if (j.GetType() != Json::Type::Object) return;

            int _mode = j.Get("mode", int(mode));
            mode = AudioMode(_mode);

            if (j.HasKey("lines") && j["lines"].GetType() == Json::Type::Array) {
                auto lines = j["lines"];
                for (uint i = 0; i < lines.Length; i++) {
                    this.lines.InsertLast(VoiceLineSpec(lines[i]));
                }
            }
        }

        Json::Value@ ToJson() const {
            auto j = Json::Object();
            j["mode"] = mode;
            auto lines = Json::Array();
            for (uint i = 0; i < this.lines.Length; i++) {
                lines.Add(this.lines[i].ToJson());
            }
            j["lines"] = lines;
            return j;
        }

        void InsertLine(VoiceLineSpec@ line, int ix = -1) {
            if (line is null) return;
            int nbLines = lines.Length;
            if (ix < 0 && nbLines > 0) ix = (ix % nbLines) + 1;
            if (ix < 0 || ix >= nbLines) {
                lines.InsertLast(line);
            } else {
                lines.InsertAt(ix, line);
            }
        }
    }

    class VoiceLineSpec {
        bool x = false;

        VoiceLineSpec() {}

        VoiceLineSpec(const string &in jsonStr) {
            InitFromJson(Json::Parse(jsonStr));
        }

        VoiceLineSpec(Json::Value@ j) {
            InitFromJson(j);
        }

        void InitFromJson(Json::Value@ j) {
            // TODO
        }

        Json::Value@ ToJson() const {
            auto j = Json::Object();
            // TODO
            return j;
        }
    }
}
