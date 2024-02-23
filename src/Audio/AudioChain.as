class AudioChain {
    Audio::Sample@[] samples;
    uint nextIx = 0;
    Audio::Voice@ voice;
    Audio::Voice@[] queued;
    float totalDuration;

    AudioChain(string[]@ samplePaths) {
        for (uint i = 0; i < samplePaths.Length; i++) {
            MemoryBuffer@ buf = ReadToBuf(samplePaths[i]);
            Audio::Sample@ sample = Audio::LoadSample(buf, true);
            samples.InsertLast(sample);
            auto v = Audio::Start(sample);
            v.SetGain(S_VolumeGain);
            totalDuration += v.GetLength();
            queued.InsertLast(v);
        }
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
