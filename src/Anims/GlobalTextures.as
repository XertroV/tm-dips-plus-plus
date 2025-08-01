
nvg::Texture@ frogdance_tex;
nvg::Texture@ dips_pp_logo_sm;
UI::Texture@ ui_dips_pp_logo_sm;
UI::Texture@ dips_pp_logo_horiz_vsm;
vec2 dips_pp_logo_horiz_vsm_dims;
vec2 dips_pp_logo_sm_dims;

bool _haveLoadedGlobalTextures = false;

void LoadGlobalTextures() {
    if (_haveLoadedGlobalTextures) return;
    _haveLoadedGlobalTextures = true;
    IO::FileSource sprites("sprites/frogdance_sprites.png");
    auto buf = sprites.Read(sprites.Size());
    @frogdance_tex = nvg::LoadTexture(buf, nvg::TextureFlags::Nearest);

    IO::FileSource dpp("sprites/dips-pp-sm.png");
    @buf = dpp.Read(dpp.Size());
    @dips_pp_logo_sm = nvg::LoadTexture(buf, nvg::TextureFlags::None);
    DipsPPSettings::texDims = dips_pp_logo_sm.GetSize();
    dips_pp_logo_sm_dims = DipsPPSettings::texDims;
    buf.Seek(0);
    @ui_dips_pp_logo_sm = UI::LoadTexture(buf);

    IO::FileSource dpp_horiz("sprites/dpp-horiz-vsm.png");
    // @dips_pp_logo_horiz_vsm = nvg::LoadTexture(dpp_horiz.Read(dpp_horiz.Size()), nvg::TextureFlags::None);
    @dips_pp_logo_horiz_vsm = UI::LoadTexture(dpp_horiz.Read(dpp_horiz.Size()));
    dips_pp_logo_horiz_vsm_dims = dips_pp_logo_horiz_vsm.GetSize();
    yield();
    @Fanfare::FanfareSpritesheet = DTexture("img/fanfare-spritesheet.png");
    yield();
    Fanfare::LoadDefaultFanfareTextures();
}
