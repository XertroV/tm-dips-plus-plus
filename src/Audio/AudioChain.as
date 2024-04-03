class AudioChain {
    Audio::Sample@[] samples;
    uint nextIx = 0;
    Audio::Voice@ voice;
    Audio::Voice@[] queued;
    float totalDuration;

    AudioChain(string[]@ samplePaths) {
        for (uint i = 0; i < samplePaths.Length; i++) {
            auto sample = Audio::LoadSampleFromAbsolutePath(Audio_GetPath(samplePaths[i]));
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

    void Play() {
        startnew(CoroutineFunc(this.PlayLoop));
    }

    void PlayLoop() {
        bool done = false;
        while (true) {
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
            if (voice is null) break;
            done = voice.GetPosition() >= voice.GetLength();
            if (!done) {
                yield();
                continue;
            }
            @voice = null;
        }
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
                voice.SetGain(S_VolumeGain * Math::Sqrt(Math::Max(0.0, 1.0 - t / (float(VoiceFadeOutDurationMs) / 1000.0))));
            }
            yield();
        }
    }
}

const uint VoiceFadeOutDurationMs = 500;
