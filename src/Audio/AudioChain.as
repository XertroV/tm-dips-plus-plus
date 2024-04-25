class AudioChain {
    Audio::Sample@[] samples;
    uint nextIx = 0;
    Audio::Voice@ voice;
    Audio::Voice@[] queued;
    float totalDuration;
    string[]@ samplePaths;
    string samplesStr;

    AudioChain(string[]@ samplePaths) {
        @this.samplePaths = samplePaths;
        samplesStr = Json::Write(samplePaths.ToJson());
        startnew(CoroutineFunc(this.LoadSamples));
    }

    void LoadSamples() {
        for (uint i = 0; i < samplePaths.Length; i++) {
            auto sample = Audio_LoadFromCache_Async(samplePaths[i]);
            // MemoryBuffer@ buf = ReadToBuf(Audio_GetPath(samplePaths[i]));
            // Audio::Sample@ sample = Audio::LoadSample(buf, false);
            samples.InsertLast(sample);
            auto v = Audio::Start(sample);
            v.SetGain(S_VolumeGain);
            totalDuration += v.GetLength();
            queued.InsertLast(v);
        }
    }

    ~AudioChain() {
        for (uint i = 0; i < samples.Length; i++) {
            @samples[i] = null;
        }
        Audio::Voice@ v;
        for (uint i = 0; i < queued.Length; i++) {
            // ensure it finishes playing to clear from memory
            @v = queued[i];
            v.SetGain(0.0);
            v.Play();
        }
        samples.RemoveRange(0, samples.Length);
        queued.RemoveRange(0, queued.Length);
        if (voice !is null) {
            voice.SetGain(0);
            if (voice.IsPaused()) voice.Play();
            @voice = null;
        }
    }

    void AppendSample(Audio::Sample@ sample) {
        samples.InsertLast(sample);
    }

    uint optPlayDelay = 0;
    void PlayDelayed(uint delayMs) {
        optPlayDelay = delayMs;
        startnew(CoroutineFunc(this.StartDelayedPlayCoro));
    }

    protected void StartDelayedPlayCoro() {
        sleep(optPlayDelay);
        Play();
    }

    bool isPlaying = false;

    void Play() {
        if (isPlaying) return;
        isPlaying = true;
        startnew(CoroutineFunc(this.PlayLoop));
    }

    bool get_IsLoading() {
        return samplePaths.Length != samples.Length;
    }

    void PlayLoop() {
        trace("Awaiting audio " + this.samplesStr);
        while (IsLoading) yield();
        trace("Starting audio " + this.samplesStr);
        bool done = false;
        while (true) {
            if (IsPauseMenuOpen() && voice !is null) {
                voice.Pause();
                while (IsPauseMenuOpen()) yield();
                voice.Play();
            }
            if (voice is null && startFadeOut == 0) {
                if (queued.Length > 0) {
                    @voice = queued[0];
                    voice.Play();
                    queued.RemoveAt(0);
                } else {
                    @voice = null;
                    break;
                }
            }
#if DEVx
#else
            // If we exit the map, stop playing sounds
            if (GetApp().RootMap is null || !PlaygroundExists()) {
                StartFadeOutLoop();
                break;
            }
#endif
            if (voice is null) break;
            done = voice.GetPosition() >= voice.GetLength();
            if (!done) {
                yield();
                continue;
            }
            @voice = null;
            yield();
        }
        isPlaying = false;
    }

    uint startFadeOut = 0;
    void StartFadeOutLoop() {
        if (startFadeOut > 0) return;
        startFadeOut = Time::Now;
        startnew(CoroutineFunc(this.FadeOutCoro));
    }

    protected void FadeOutCoro() {
        while (true) {
            if (voice !is null) {
                float t = (Time::Now - startFadeOut);
                if (t >= VoiceFadeOutDurationMs) {
                    voice.SetGain(0.0);
                    @voice = null;
                    break;
                }
                t = Math::Max(0.0, 1.0 - t / (float(VoiceFadeOutDurationMs) / 1000.0));
                voice.SetGain(S_VolumeGain * t); // Math::Sqrt(t))
            }
            yield();
        }
    }
}

const uint VoiceFadeOutDurationMs = 500;
