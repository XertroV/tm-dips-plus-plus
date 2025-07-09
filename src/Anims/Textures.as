const string OPENPLANET_DATA_FOLDER = IO::FromDataFolder("");

// path should be relative to the storage folder, or absolute somewhere in the user OpenplanetNext folder.
class DTexture {
    string path;
    bool fileExists;
    protected nvg::Texture@ tex;
    vec2 dims;

    DTexture(const string &in path) {
        if (path.Length == 0) {
            Dev_NotifyWarning("DTexture: path cannot be empty");
            return;
        }

        this.path = path;
        if (!path.StartsWith(OPENPLANET_DATA_FOLDER)) {
            this.path = IO::FromStorageFolder(path);
        }
        startnew(CoroutineFunc(WaitForTexture));
    }

    void WaitForTextureSilent() {
        while (!IO::FileExists(path)) {
            yield();
        }
        yield();
    }
    void WaitForTexture() {
        dev_trace("waiting for texture: " + path);
        WaitForTextureSilent();
        dev_trace("Found texture: " + path);
        fileExists = true;
    }

    vec2 GetSize() {
        if (tex !is null) {
            return dims;
        }
        return vec2(60.);
    }

    nvg::Texture@ Get() {
        if (tex !is null) {
            return tex;
        }
        if (!fileExists) {
            return null;
        }
        IO::File f(path, IO::FileMode::Read);
        dev_trace(">>> Loading texture: " + path);
        @tex = nvg::LoadTexture(f.Read(f.Size()), nvg::TextureFlags::None);
        dev_trace("<<< Loaded texture: " + path);
        dims = tex.GetSize();
        return tex;
    }

    nvg::Paint GetPaint(vec2 origin, vec2 size, float angle, float alpha = 1.0) {
        auto t = Get();
        if (t is null) return nvg::LinearGradient(vec2(), g_screen, cBlack50, cBlack50);
        return nvg::TexturePattern(origin, size, angle, t, alpha);
    }

    DTextureSprite@ GetSprite(nat2 topLeft, nat2 size) {
        return DTextureSprite(this, topLeft, size);
    }
}

class DTextureSprite : DTexture {
    vec2 topLeft;
    vec2 spriteSize;
    DTexture@ parent;

    DTextureSprite(DTexture@ tex, nat2 topLeft, nat2 size) {
        super("?nonexistant;*");
        this.topLeft.x = topLeft.x;
        this.topLeft.y = topLeft.y;
        this.spriteSize.x = size.x;
        this.spriteSize.y = size.y;
        @this.parent = tex;
    }

    void WaitForTexture() override {
        parent.WaitForTextureSilent();
    }

    vec2 GetSize() override {
        return spriteSize;
    }

    nvg::Texture@ Get() override {
        return parent.Get();
    }

    nvg::Paint GetPaint(vec2 origin, vec2 size, float angle, float alpha = 1.0) override {
        vec2 scale = size / spriteSize;
        auto t = parent.Get();
        if (t is null) return nvg::LinearGradient(vec2(), g_screen, cBlack50, cBlack50);
        return nvg::TexturePattern(origin - topLeft * scale, t.GetSize(), angle, t, alpha);
    }
}

DTexture@ Vae_Head = DTexture("img/vae_square.png");
// DTexture@ Vae_Full;
DTexture@ DD2_Logo = DTexture("img/Deep_dip_2_logo.png");
