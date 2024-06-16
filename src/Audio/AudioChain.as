/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
class AudioChain {
    Audio::Sample@[] samples;
    uint nextIx = 0;
    Audio::Voice@ voice;
    Audio::Voice@[] queued;
    float totalDuration;
    string[]@ samplePaths;
    string samplesStr;
    bool onlyInMap = true;
    int channel = 0;
    bool samplesLoaded = false;
    bool firstPlayed = false;

    AudioChain(string[]@ samplePaths) {
        @this.samplePaths = samplePaths;
        samplesStr = Json::Write(samplePaths.ToJson());
        startnew(CoroutineFunc(this.LoadSamples));
    }

    AudioChain@ WithPlayAnywhere() {
        onlyInMap = false;
        return this;
    }

    AudioChain@ WithChannel(int channel) {
        this.channel = channel;
        return this;
    }

    void LoadSamples() {
        for (uint i = 0; i < samplePaths.Length; i++) {
            auto sample = Audio_LoadFromCache_Async(samplePaths[i]);
            samples.InsertLast(sample);
            auto v = Audio::Start(sample);
            v.SetGain(S_VolumeGain);
            totalDuration += v.GetLength();
            queued.InsertLast(v);
        }
        samplesLoaded = true;
    }

    void Reset() {
        _PlayOutQueuedSamples();
        for (uint i = 0; i < samples.Length; i++) {
            auto v = Audio::Start(samples[i]);
            v.SetGain(S_VolumeGain);
            totalDuration += v.GetLength();
            queued.InsertLast(v);
        }
    }

    AudioChain@ WithAwaitLoaded() {
        while (!samplesLoaded) yield();
        return this;
    }

    ~AudioChain() {
        for (uint i = 0; i < samples.Length; i++) {
            @samples[i] = null;
        }
        _PlayOutQueuedSamples();
        samples.RemoveRange(0, samples.Length);
        if (voice !is null) {
            voice.SetGain(0);
            if (voice.IsPaused()) voice.Play();
            @voice = null;
        }
        RemoveSelfFromChannel();
    }

    void _PlayOutQueuedSamples() {
        Audio::Voice@ v;
        for (uint i = 0; i < queued.Length; i++) {
            // ensure it finishes playing to clear from memory
            @v = queued[i];
            v.SetGain(0.0);
            v.Play();
        }
        queued.RemoveRange(0, queued.Length);
        isPlaying = false;
    }

    void RemoveSelfFromChannel() {
        if (lastPlayingChs[channel] is this) @lastPlayingChs[channel] = null;
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
        if (firstPlayed) {
            Reset();
        }
        firstPlayed = true;
        isPlaying = true;
        startnew(CoroutineFunc(this.PlayLoop));
    }

    bool get_IsLoading() {
        return samplePaths.Length != samples.Length;
    }

    void PlayLoop() {
        TryClearingAudioChannel(this.channel);
        @lastPlayingChs[channel] = this;
        trace("Awaiting audio " + this.samplesStr);
        while (IsLoading) yield();
        trace("Starting audio " + this.samplesStr);
        bool done = false;
        while (true) {
            if (IsPauseMenuOpen(S_PauseWhenGameUnfocused) && voice !is null) {
                voice.Pause();
                while (IsPauseMenuOpen(S_PauseWhenGameUnfocused)) yield();
                if (voice !is null) voice.Play();
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
            } else if (voice !is null) {
                // while we're playing, keep the volume up-to-date with settings
                voice.SetGain(S_VolumeGain);
            }

            // If we exit the map, stop playing sounds
            if (onlyInMap) {
                if (GetApp().RootMap is null || !PlaygroundExists()) {
                    StartFadeOutLoop();
                    break;
                }
            }

            if (voice is null) break;
            done = voice.GetPosition() >= voice.GetLength();
            if (done) {
                @voice = null;
            }
            yield();
        }
        dev_trace("Audio done " + this.samplesStr);
        isPlaying = false;
        if (lastPlayingChs[channel] is this) @lastPlayingChs[channel] = null;
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
                    voice.Play();
                    @voice = null;
                    break;
                }
                t = Math::Max(0.0, 1.0 - t / (float(VoiceFadeOutDurationMs) / 1000.0));
                voice.SetGain(S_VolumeGain * t); // Math::Sqrt(t))
            }
            yield();
        }
        RemoveSelfFromChannel();
    }
}

AudioChain@[] lastPlayingChs = {null, null};

void TryClearingAudioChannel(int channel = 0) {
    if (lastPlayingChs[channel] !is null) {
        warn("Clearing existing audio chain on channel " + channel + " / " + lastPlayingChs[channel].samplesStr);
        lastPlayingChs[channel].StartFadeOutLoop();
        @lastPlayingChs[channel] = null;
    }
}

bool IsAudioChannelPlaying(int channel = 0) {
    return lastPlayingChs[channel] !is null
        && lastPlayingChs[channel].isPlaying;
}

const uint VoiceFadeOutDurationMs = 1000;
