[Setting hidden]
bool F_PlayedSecretAudio = false;

namespace SecretAssets {
    Json::Value@ saPayload;

    void OnPluginStart() {
        AddSecretAssets();
    }

    void AddSecretAssets() {
        @saPayload = Json::Parse('{"filenames_and_urls":[{"name": "head", "filename": "img/s1head.jpg", "url": "https://assets.xk.io/d++/secret/s1head-3948765.jpg"}, {"name": "s-flight-vae", "filename": "subs/flight-vae.txt", "url": "https://assets.xk.io/d++/secret/subs-vae-3948765.txt"}, {"name": "s-flight", "filename": "subs/flight.txt", "url": "https://assets.xk.io/d++/secret/subs-3948765.txt"}, {"name": "flight-vae", "filename": "vl/flight-vae.mp3", "url": "https://assets.xk.io/d++/secret/flight-vae-3948765.mp3"}, {"name": "flight", "filename": "vl/flight.mp3", "url": "https://assets.xk.io/d++/secret/flight-3948765.mp3"}, {"name": "fanfare", "filename": "img/fanfare-self.png", "url": "https://assets.xk.io/d++/secret/generic.png"}]}');
        startnew(LoadSAJson);
    }

    void LoadSAJson() {
        auto j = saPayload['filenames_and_urls'];
        SecretAsset@[] saList;
        Meta::PluginCoroutine@[] coros;
        for (uint i = 0; i < j.Length; i++) {
            saList.InsertLast(SecretAsset(j[i]));
            coros.InsertLast(saList[saList.Length - 1].dlCoro);
        }
        await(coros);
        dev_trace("\\$F80 Loaded no-so-secret-anymore assets");
        AreSAsLoaded = true;
    }

    bool AreSAsLoaded = false;
    DTexture@ head;
    DTexture@ fanfarePfp;
    string s_flight_vae;
    string s_flight;
    AudioChain@ flight_vae;
    AudioChain@ flight;

    void LoadSAFromFile(const string &in name, const string &in filename) {
        if (name == "head") {
            @head = DTexture(filename);
            while (head.Get() is null) yield();
        } else if (name == "fanfare") {
            @fanfarePfp = DTexture(filename);
            for (uint i = 0; i < 3; i++) {
                Fanfare::AddFireworkParticle(fanfarePfp);
            }
            while (fanfarePfp.Get() is null) yield();
        } else if (name == "s-flight-vae") {
            s_flight_vae = ReadTextFileFromStorage(filename);
        } else if (name == "s-flight") {
            s_flight = ReadTextFileFromStorage(filename);
        } else if (name == "flight-vae") {
            @flight_vae = AudioChain({IO::FromStorageFolder(filename)}).WithPlayAnywhere().WithAwaitLoaded();
        } else if (name == "flight") {
            @flight = AudioChain({IO::FromStorageFolder(filename)}).WithPlayAnywhere().WithAwaitLoaded();
        } else {
            warn("Unknown secret asset: " + name + " : " + filename);
        }
    }

    bool startedSA = false;
    void OnTriggerHit() {
        // if (!AreSAsLoaded) TriggerCheck_Reset();
        if (!AreSAsLoaded || startedSA) return;
        startedSA = true;
#if DEV
        startnew(PlaySecretAudio);
#else
        if (!F_PlayedSecretAudio) {
            F_PlayedSecretAudio = true;
            startnew(PlaySecretAudio);
        }
#endif
    }

    void PlaySecretAudio() {
        while (IsVoiceLinePlaying()) yield();
        trace('starting sec audio 1');
        S_VolumeGain = Math::Max(S_VolumeGain, 0.15);
        @Volume::vtSubtitlesAnim = GenFlightVaeSubs();
        AddSubtitleAnimation(Volume::vtSubtitlesAnim);
        if (flight_vae !is null) {
            flight_vae.Reset();
            flight_vae.Play();
        } else {
            NotifyWarning("Vae flight audio not loaded");
        }
        startnew(Dev_CheckIn15S);
        yield(5);
        while (IsVoiceLinePlaying()) yield();
        trace('starting sec audio 2');
        @Volume::vtSubtitlesAnim = GenFlightSubs();
        AddSubtitleAnimation(Volume::vtSubtitlesAnim);
        if (flight !is null) {
            flight.Reset();
            flight.Play();
        } else {
            NotifyWarning("Flight audio not loaded");
        }
        while (IsVoiceLinePlaying()) yield();
        @Volume::vtSubtitlesAnim = null;
        trace('done sec audio');
        Meta::SaveSettings();
    }

    void Dev_CheckIn15S() {
        sleep(15000);
        trace('subs len: ' + subtitleAnims.Length);
        trace('active voice: ' + IsAudioChannelPlaying(0));
    }

    SubtitlesAnim@ GenFlightVaeSubs() {
        return SubtitlesAnim("", true, s_flight_vae);
    }
    SubtitlesAnim@ GenFlightSubs() {
        return SubtitlesAnim("", true, s_flight, head);
    }

    class SecretAsset {
        string name;
        string url;
        string filename;
        Meta::PluginCoroutine@ dlCoro;

        SecretAsset(Json::Value@ j) {
            name = j['name'];
            filename = j['filename'];
            filename = "sec/" + filename;
            url = j['url'];
            @dlCoro = startnew(CoroutineFunc(GetAndLoadSA));
        }

        protected void GetAndLoadSA() {
            DownloadSA();
            yield();
            LoadSA();
        }

        protected void LoadSA() {
            LoadSAFromFile(name, filename);
        }

        protected void DownloadSA() {
            if (IO::FileExists(IO::FromStorageFolder(filename))) {
                return;
            }
            Net::HttpRequest@ req = Net::HttpGet(url);
            yield();
            CheckMakeDir();
            yield();
            while (!req.Finished()) {
                yield();
            }
            auto respCode = req.ResponseCode();
            dev_trace("sa response code: " + respCode);
            if (respCode >= 200 && respCode < 299) {
                auto data = req.Buffer();
                IO::File f(IO::FromStorageFolder(filename), IO::FileMode::Write);
                f.Write(data);
                f.Close();
                dev_trace("sa success: " + filename);
                return;
            }
            warn("sa download failed: " + filename + " " + respCode + " ");
        }

        protected void CheckMakeDir() {
            auto parts = filename.Split("/");
            parts.RemoveLast();
            auto dir = IO::FromStorageFolder(string::Join(parts, "/"));
            if (!IO::FolderExists(dir)) {
                IO::CreateFolder(dir);
            }
        }
    }
}

class SATrigger : GameTrigger {
    SATrigger(vec3 &in min, vec3 &in max) {
        super(min, max, "Secret");
        this.debug_strokeColor = vec4(1, 0.84, 0, 1);
    }

    void OnEnteredTrigger(OctTreeRegion@ prevTrigger) override {
        SecretAssets::OnTriggerHit();
    }
}


// From storage
string ReadTextFileFromStorage(const string &in filename) {
    IO::File f(IO::FromStorageFolder(filename), IO::FileMode::Read);
    return f.ReadToEnd();
}
