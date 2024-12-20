
const uint FD_FRAMES = 6;
const uint FD_DURATION = 3600;

[Setting hidden]
bool S_EnableFallGangFrogDance = true;

void WaitAndPlayFloorGangFrog() {
    if (!S_EnableFallGangFrogDance) return;
    Dev_Notify("Waiting for fall to reach 16 m");
    while (PS::viewedPlayer !is null && PS::viewedPlayer.HasFallTracker()) {
        if (PS::viewedPlayer.pos.y < 16. && PS::viewedPlayer.GetFallTracker().IsFallOver100m()) {
            EmitStatusAnimation(FrogDance());
            break;
        }
        yield();
    }
}

class FrogDance : ProgressAnim {
    vec2 dims;
    vec2 full_size;

    FrogDance() {
        if (frogdance_tex is null) {
            IO::FileSource sprites("sprites/frogdance_sprites.png");
            auto buf = sprites.Read(sprites.Size());
            @frogdance_tex = nvg::LoadTexture(buf, nvg::TextureFlags::Nearest);
        }
        super("frogdance", nat2(0, FD_DURATION));
        full_size = frogdance_tex.GetSize() * 4. * Minimap::vScale;
        dims = full_size / vec2(FD_FRAMES, 1.);
        fadeIn = 200;
        fadeOut = 200;
        pauseWhenMenuOpen = true;
    }

    float[] horizPos = {0.1, 0.3, 0.7, 0.9}; // 0.3, 0.1};
    uint frame;
    float heightOffset;
    vec2 size;

    vec2 Draw() override {
        nvg::Reset();
        frame = (progressMs / 100) % FD_FRAMES;
        nvg::GlobalAlpha(gAlpha);
        // todo: check
        // heightOffset = 0.5 * (1 - Math::Cos(2 * Math::PI * (progressMs % uint(fdd)) / fdd));
        size = dims * Minimap::vScale;
        heightOffset = size.y * .9;
        for (uint i = 0; i < horizPos.Length; i++) {
            if (i == horizPos.Length / 2) {
                frame = (frame + 3) % FD_FRAMES;
            }
            DrawFrog(horizPos[i]);
        }
        nvg::GlobalAlpha(1.0);
        return size;
    }

    void DrawFrog(float xUV) {
        vec2 tl = vec2(xUV, 1) * g_screen - vec2(size.x/2., heightOffset);
        nvg::BeginPath();
        nvg::Scissor(tl.x, tl.y, size.x, size.y);
        nvg::Rect(tl + vec2(1), size - vec2(2));

        nvg::FillPaint(nvg::TexturePattern(tl - vec2(frame * dims.x, 0), full_size, 0, frogdance_tex, 1.0));
        nvg::Fill();
        nvg::Scale(1.);

        nvg::ResetScissor();
        nvg::ClosePath();
    }
}
