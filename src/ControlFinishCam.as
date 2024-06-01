// The called function updates cam matrix at 0x560
FunctionHookHelper@ OnCameraUpdateHook_Other = FunctionHookHelper(
    // v function that updates camera matrix
    "E8 ?? ?? ?? ?? 8B F8 85 C0 0F 84 ?? 00 00 00 45 85 E4 0F 84 ?? 00 00 00 45 8B 86 ?? 00 00 00",
    0, 0, "CameraUpdateHook::AfterUpdateOther"
);

// The called function updates cam matrix at 0x1c0
// FunctionHookHelper@ OnCameraUpdateHook = FunctionHookHelper(
//     // v function that updates camera matrix
//     "E8 ?? ?? ?? ?? 49 8D 96 ?? ?? 00 00 48 8B CE E8 ?? ?? ?? ?? 48 8B 8B ?? 00 00 00 48 85 C9 74 ?? E8 ?? ?? ?? ?? 85 C0 74",
//     0, 0, "CameraUpdateHook::AfterUpdate"
// );

/**
 * Matrix at 0x1C0 is used during intro and finish, not used during forced MT cams (of any kind it seems)
 * Another Cam Matrix at 0x260 -- overwriting at either hook doesn't seem to do anything
 * Matrix at 0x560 is used during normal play (overwrites cam1/2/3 position, not MT).
 */

namespace CameraUpdateHook {
    // r14 is camera system
    void AfterUpdateOther(uint64 r14) {
        // todo: abort early if not in finish condition
        if (!MatchDD2::isDD2Proper) return;
        // if (IsFinishedUISequence)
        vec3 vehiclePos = Dev::ReadVec3(r14 + 0x11C);
        auto p = (mat4::Rotate(TimeToAngle(Time::Now % 100000), UP) * vec3(-3, 6, -3)).xyz;
        auto newMat = mat4::Translate(vehiclePos + p) * mat4::LookAt(vec3(), p, UP);
        auto newIso = iso4(newMat);
        Dev::Write(r14 + 0x1c0, newIso);
        // Dev::Write(r14 + 0x260, newIso);
        // Dev::Write(r14 + 0x560, newIso);
    }

    // rcx = cam sys
    void AfterUpdate(uint64 rcx) {
        // todo: abort early if not in finish condition
        // auto camIso = Dev::ReadIso4(r14 + 0x560);
        // auto vehicleIso = Dev::ReadIso4(r14 + 0xF8);
        auto vehiclePos = Dev::ReadVec3(rcx + 0x11C);
        auto p = (mat4::Rotate(TimeToAngle(Time::Now % 100000), UP) * vec3(-3, 6, -3)).xyz;
        auto newMat = mat4::Translate(vehiclePos + p) * mat4::LookAt(vec3(), p, UP);
        auto newIso = iso4(newMat);
        Dev::Write(rcx + 0x1c0, newIso);
        // Dev::Write(rcx + 0x260, newIso);
        // Dev::Write(rcx + 0x560, newIso);
        // auto cam = Camera::GetCurrent();
        // cam.NextLocation = newIso;
    }

    // time is miliseconds and mod 100k
    float TimeToAngle(float time) {
        return time / 12500.0 * TAU;
    }


    void Run15Test() {
        OnCameraUpdateHook_Other.Apply();
        sleep(15000);
        OnCameraUpdateHook_Other.Unapply();
    }
}

const vec3 UP = vec3(0, 1, 0);
