// The called function updates cam matrix at 0x578
HookHelper@ OnCameraUpdateHook_Other = HookHelper(
    // v function that updates camera matrix
    // "E8 ?? ?? ?? ?? 8B F0 85 C0 74 ?? 8B 43 08",
    // The above is unique (G++ uses it too), but we'll add some bytes on the front to hook a little earlier.
    // v mov        v mov    v E8 call      v mov v test v je v mov
    "48 89 74 24 30 49 8B C8 ?? ?? ?? ?? ?? 8B F0 85 C0 74 ?? 8B 43 08",
    0, 0, "CameraUpdateHook::AfterUpdateOther"
);

/*
    - 2025-04-22
    Trackmania.exe+DC9E47 - 48 89 74 24 30        - mov [rsp+30],rsi
    Trackmania.exe+DC9E4C - 49 8B C8              - mov rcx,r8
    Trackmania.exe+DC9E4F - E8 6C90F6FF           - call Trackmania.exe.text+D31EC0 { updates camsys + 0x578 }
    Trackmania.exe+DC9E54 - 8B F0                 - mov esi,eax
    Trackmania.exe+DC9E56 - 85 C0                 - test eax,eax

*/

/**
 (Note: offsets are old; 0x560 -> 0x578)
 * Matrix at 0x1C0 is used during intro and finish, not used during forced MT cams (of any kind it seems)
 * Another Cam Matrix at 0x260 -- overwriting at either hook doesn't seem to do anything
 * Matrix at 0x560 is used during normal play (overwrites cam1/2/3 position, not MT).
 */

namespace CameraUpdateHook {
    // r14 is camera system
    void AfterUpdateOther(uint64 r14) {
        // todo: abort early if not in finish condition
        if (!MatchDD2::isDD2Any) return;
        // if (IsFinishedUISequence)
        vec3 vehiclePos = Dev::ReadVec3(r14 + 0x11C);
        auto p = (mat4::Rotate(TimeToAngle(Time::Now % 100000), UP) * vec3(-3, 6, -3)).xyz;
        auto newMat = mat4::Translate(vehiclePos + p) * mat4::LookAt(vec3(), p, UP);
        auto newIso = iso4(newMat);
        Dev::Write(r14 + 0x1c0, newIso);
        // Dev::Write(r14 + 0x260, newIso);
        // Dev::Write(r14 + 0x560, newIso);
    }

    // // rcx = cam sys
    // // ! warning: 2025-04-22, changed hook so rcx is not longer valid
    // void AfterUpdate(uint64 rcx) {
    //     // todo: abort early if not in finish condition
    //     // auto camIso = Dev::ReadIso4(r14 + 0x560);
    //     // auto vehicleIso = Dev::ReadIso4(r14 + 0xF8);
    //     auto vehiclePos = Dev::ReadVec3(rcx + 0x11C);
    //     auto p = (mat4::Rotate(TimeToAngle(Time::Now % 100000), UP) * vec3(-3, 6, -3)).xyz;
    //     auto newMat = mat4::Translate(vehiclePos + p) * mat4::LookAt(vec3(), p, UP);
    //     auto newIso = iso4(newMat);
    //     Dev::Write(rcx + 0x1c0, newIso);
    //     // Dev::Write(rcx + 0x260, newIso);
    //     // Dev::Write(rcx + 0x560, newIso);
    //     // auto cam = Camera::GetCurrent();
    //     // cam.NextLocation = newIso;
    // }

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
