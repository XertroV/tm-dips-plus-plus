namespace CustomVL {
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
            auto nbLines = lines.Length;
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
