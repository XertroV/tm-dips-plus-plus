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

    void Play() {
        startnew(CoroutineFunc(this.PlayLoop));
    }

    void PlayLoop() {
        bool done = false;
        while (true) {
            if (voice is null) {
                if (queued.Length > 0) {
                    @voice = queued[0];
                    voice.Play();
                    queued.RemoveAt(0);
                } else {
                    @voice = null;
                    break;
                }
            }
            done = voice.GetPosition() >= voice.GetLength();
            if (!done && voice !is null) {
                yield();
                continue;
            }
            if (done) {
                @voice = null;
            }
        }
    }
}
