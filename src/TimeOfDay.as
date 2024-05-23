// notes:
// CANNOT change map to night time (it's just like a cloudy day)
// Does affect some shadows, but not substantially
// Mostly just moves the sun.
// The lightmap/mood still plays the dominant role in lighting.
// resets when leaving map
namespace SetTimeOfDay {
    uint16 O_CHMSLIGHT_LOCATION2 = 0;
    void SetSunAngle(vec2 AzumithElevation) {
        SetSunAngle(AzumithElevation.x, AzumithElevation.y);
    }
    void SetSunAngle(float azumith, float elevation) {
        // from tau to pi (left to right on screen); start 3.485, to 6.2
        // elevation: PI/2 is noon, 3PI/2 is midnight (well sun under map); PI = horizon behind tower
        mat4 lightingMat4 = mat4::Rotate(azumith, vec3(0, 1, 0)) * mat4::Rotate(elevation, vec3(0, 0, 1));
        SetSunIso4(iso4(lightingMat4));
    }

    iso4 GetSunIso4() {
        auto chl = GetSunLight();
        if (chl is null) return iso4(mat4::Identity());
        if (O_CHMSLIGHT_LOCATION2 == 0) {
            O_CHMSLIGHT_LOCATION2 = GetOffset(chl, "Location") + 0x30;
        }
        if (O_CHMSLIGHT_LOCATION2 < 0x100) {
            return Dev::GetOffsetIso4(chl, O_CHMSLIGHT_LOCATION2);
        }
        return iso4(mat4::Identity());
    }

    void SetSunIso4(const iso4 &in v) {
        auto sunLight = GetSunLight();
        if (sunLight is null) return;
        if (O_CHMSLIGHT_LOCATION2 == 0) {
            O_CHMSLIGHT_LOCATION2 = GetOffset(sunLight, "Location") + 0x30;
        }
        if (O_CHMSLIGHT_LOCATION2 < 0x100) {
            Dev::SetOffset(sunLight, O_CHMSLIGHT_LOCATION2, v);
        }
    }

    CHmsLight@ GetSunLight() {
        auto gs = GetApp().GameScene;
        if (gs is null) return null;
        CScene@ hs;
        if ((@hs = gs.HackScene) is null) return null;
        if (hs.Lights.Length == 0) return null;
        // only 3 observed on server
        if (hs.Lights.Length > 10) return null;

        CHmsLight@ chl;
        CSceneLight@ csl;
        for (int i = 0; i < gs.HackScene.Lights.Length; i++) {
            if ((@csl = hs.Lights[i]) is null) continue;
            if ((@chl = cast<CHmsLight>(csl.HmsPoc)) is null) continue;
            // static = 0; dynamic = 1
            if (int(chl.UpdateType) > 0) continue;
            // found sun
            return chl;
        }
        return null;
    }
}
