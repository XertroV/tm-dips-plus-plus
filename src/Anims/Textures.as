class DTexture {
    string path;
    bool fileExists;
    nvg::Texture@ tex;
    vec2 dims;

    DTexture(const string &in path) {
        this.path = path;
        if (!path.StartsWith(IO::FromStorageFolder(""))) {
            this.path = IO::FromStorageFolder(path);
        }
        startnew(CoroutineFunc(WaitForTexture));
    }

    void WaitForTexture() {
        while (!IO::FileExists(path)) {
            yield();
        }
        dev_trace("Found texture: " + path);
        fileExists = true;
    }

    nvg::Texture@ Get() {
        if (tex !is null) {
            return tex;
        }
        if (!fileExists) {
            return null;
        }
        IO::File f(path, IO::FileMode::Read);

        @tex = nvg::LoadTexture(f.Read(f.Size()), nvg::TextureFlags::None);
        dims = tex.GetSize();
        return tex;
    }

    nvg::Paint GetPaint(vec2 origin, vec2 size, float angle, float alpha = 1.0) {
        auto t = Get();
        if (t is null) return nvg::LinearGradient(vec2(), g_screen, cBlack50, cBlack50);
        return nvg::TexturePattern(origin, size, angle, t, alpha);
    }
}

DTexture@ Vae_Head = DTexture("img/vae_square.png");
DTexture@ Vae_Full = DTexture("img/vae.png");
DTexture@ DD2_Logo = DTexture("img/Deep_dip_2_logo.png");
