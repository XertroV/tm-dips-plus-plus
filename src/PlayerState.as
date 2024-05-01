// Player state
class PlayerState {
    CSmPlayer@ player;
    CSceneVehicleVis@ vehicle;
    // mwid of the players login (also on player.User)
    uint playerScoreMwId;
    string playerName;
    string playerLogin;
    bool hasLeftGame = false;
    uint discontinuityCount = 0;
    bool stateFrozen = false;
    uint lastVehicleId = 0x0FF00000;
    vec4 color;
    bool isLocal = false;
    bool isViewed = false;
    FallTracker@ fallTracker;
    FallTracker@ lastFall;
    uint lastRespawn;
    int raceTime;

    // changed flags, type: union of UpdatedFlags
    int updatedThisFrame = UpdatedFlags::None;

    Minimap::PlayerMinimapLabel@ minimapLabel;


    PlayerState() {}
    PlayerState(CSmPlayer@ player) {
        @this.player = player;
        // bots have no score. players sometimes too on init
        if (player.User is null) return;
        playerScoreMwId = player.User.Id.Value;
        playerName = player.User.Name;
        playerLogin = player.User.Login;
        color = vec4(player.LinearHueSrgb, 1.0);
        @minimapLabel = Minimap::PlayerMinimapLabel(this);
        isLocal = playerScoreMwId == g_LocalPlayerMwId;
        startnew(CoroutineFunc(CheckUpdateIsLocal));
        lastRespawn = Time::Now;
    }

    void CheckUpdateIsLocal() {
        isLocal = playerScoreMwId == g_LocalPlayerMwId;
    }

    // run this first to clear references
    void Reset() {
        @player = null;
        @vehicle = null;
        updatedThisFrame = UpdatedFlags::None;
        // this will be set to false if we get an update (isIdle = pos.LenSq == 0)
        // isIdle = true;
    }

    void ResetUpdateFlags() {
        updatedThisFrame = UpdatedFlags::None;
    }

    void Update(CSmPlayer@ player) {
        @this.player = player;
        if (cast<CSmScriptPlayer>(player.ScriptAPI) !is null) {
            raceTime = GetRaceTimeFromStartTime(cast<CSmScriptPlayer>(player.ScriptAPI).StartTime);
        }
        this.isViewed = PS::guiPlayerMwId == playerScoreMwId;
        auto entId = player.GetCurrentEntityID();
        if (entId != lastVehicleId) {
            PS::UpdateVehicleId(this, entId);
            lastVehicleId = entId;
            updatedThisFrame |= UpdatedFlags::VehicleId;
            // trace('Updated vehicle id for ' + playerName + ": " + Text::Format("0x%08x", entId));
        }
    }

    uint lastVehicleFromPlayerTime = 0;
    float vfpTimeDelta = 0;
    uint lastVFPIx = 0;
    vec3 priorPos, priorVel;

    void UpdateVehicleFromCSmPlayer() {
        // don't do this if we already had a vehicle
        if (updatedThisFrame & UpdatedFlags::Position > 0) return;
        if (this.player is null) return;

        auto nextIx = Dev::GetOffsetUint32(player, O_CSmPlayer_NetPacketsBuf_NextIx);
        auto currIx = (nextIx + 200) % LEN_CSmPlayer_NetPacketsBuf;
        auto prevIx = (currIx + 200) % LEN_CSmPlayer_NetPacketsBuf;
        auto offset = O_CSmPlayer_NetPacketsBuf + currIx * SZ_CSmPlayer_NetPacketsBufStruct;
        auto prevOffset = O_CSmPlayer_NetPacketsBuf + prevIx * SZ_CSmPlayer_NetPacketsBufStruct;


        vfpTimeDelta = 0.0;
        auto timeSinceLast = Time::Now - lastVehicleFromPlayerTime;
        if (timeSinceLast < 200) {
            vfpTimeDelta = float(timeSinceLast) * 0.001;
        } else {
            vfpTimeDelta = 0.0;
        }
        if (lastVFPIx != currIx) {
            lastVFPIx = currIx;
            lastVehicleFromPlayerTime = Time::Now;
        }
        priorPos = pos;
        priorVel = vel;

        // auto lastUpdateTime = Dev::GetOffsetUint32(player, O_CSmPlayer_NetPacketsUpdatedBuf + prevIx * SZ_CSmPlayer_NetPacketsUpdatedBufEl);
        // auto currUpdateTime = Dev::GetOffsetUint32(player, O_CSmPlayer_NetPacketsUpdatedBuf + currIx * SZ_CSmPlayer_NetPacketsUpdatedBufEl);
        // auto timeDiff = currUpdateTime - lastUpdateTime;

        // auto wheelOffset = offset + 0x68;
        // Values documented in DrawDebugTree_Player
        bool anyWheelFlying =
            Dev::GetOffsetUint8(player, offset + O_PlayerNetStruct_WheelOnGround + SZ_PlayerNetStruct_Wheel * 0) == 0
            || Dev::GetOffsetUint8(player, offset + O_PlayerNetStruct_WheelOnGround + SZ_PlayerNetStruct_Wheel * 1) == 0
            || Dev::GetOffsetUint8(player, offset + O_PlayerNetStruct_WheelOnGround + SZ_PlayerNetStruct_Wheel * 2) == 0
            || Dev::GetOffsetUint8(player, offset + O_PlayerNetStruct_WheelOnGround + SZ_PlayerNetStruct_Wheel * 3) == 0;
        bool allWheelsFlying =
            Dev::GetOffsetUint8(player, offset + O_PlayerNetStruct_WheelOnGround + SZ_PlayerNetStruct_Wheel * 0) == 0
            && Dev::GetOffsetUint8(player, offset + O_PlayerNetStruct_WheelOnGround + SZ_PlayerNetStruct_Wheel * 1) == 0
            && Dev::GetOffsetUint8(player, offset + O_PlayerNetStruct_WheelOnGround + SZ_PlayerNetStruct_Wheel * 2) == 0
            && Dev::GetOffsetUint8(player, offset + O_PlayerNetStruct_WheelOnGround + SZ_PlayerNetStruct_Wheel * 3) == 0;

        auto newDiscontCount = Dev::GetOffsetUint8(player, offset + O_PlayerNetStruct_DiscontinuityCount);
        auto flags = Dev::GetOffsetUint32(player, offset + O_PlayerNetStruct_Flags);
        auto newFrozen = flags & (PlayerNetStructFlags::Respawning | PlayerNetStructFlags::Spawning | PlayerNetStructFlags::Unspawned) > 0;
        vel = Dev::GetOffsetVec3(player, offset + O_PlayerNetStruct_Vel);
        pos = Dev::GetOffsetVec3(player, offset + O_PlayerNetStruct_Pos);
        rot = Dev_GetOffsetQuat(player, offset + O_PlayerNetStruct_Quat);
        float lerpT = 0.1;
        UpdatePlayerFromRawValues(
            Math::Lerp(priorVel, vel, lerpT),
            Math::Lerp(priorPos, pos, lerpT),
            //pos,
            rot,
            anyWheelFlying,
            allWheelsFlying,
            newDiscontCount,
            newFrozen
        );
    }

    void UpdateVehicleState(CSceneVehicleVis@ vis) {
        @vehicle = vis;
        // updatedThisFrame |= UpdatedFlags::Flying | UpdatedFlags::Falling | UpdatedFlags::Position;
        auto @state = vis.AsyncState;

        groundDist = state.GroundDist;

        bool anyWheelFlying = state.FLGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null
                || state.FRGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null
                || state.RLGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null
                || state.RRGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null;
        bool allWheelsFlying = state.FLGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null
                && state.FRGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null
                && state.RLGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null
                && state.RRGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null;

        // state.DiscontinuityCount does not work for some reason
        auto newDiscontCount = Dev::GetOffsetUint8(state, 0xA);
        auto newFrozen = Dev::GetOffsetUint8(state, O_VehicleState_Frozen) > 0;
        priorPos = state.Position;
        priorVel = state.WorldVel;
        UpdatePlayerFromRawValues(
            state.WorldVel,
            state.Position,
            quat(DirUpLeftToMat(state.Dir, state.Up, state.Left)),
            anyWheelFlying,
            allWheelsFlying,
            newDiscontCount,
            newFrozen
        );
    }

    void UpdatePlayerFromRawValues(const vec3 &in vel, const vec3 &in pos, const quat &in rot, bool anyWheelFlying, bool allWheelsFlying, uint newDiscontCount, bool newFrozen) {
        if (Math::IsNaN(pos.y) || Math::IsInf(pos.y) || Math::Abs(pos.y) > 3000.0 || Math::Abs(pos.x) < 1. || Math::Abs(pos.z) < 1.) {
            dev_trace("Player " + playerName + " has NaN/Inf/oob pos: " + pos.ToString());
            return;
        }
        this.vel = vel;
        // simplify low velocities
        if (vel.LengthSquared() < 0.0000001) {
            this.vel = vec3();
        }
        this.pos = pos;
        this.rot = rot;
        updatedThisFrame |= UpdatedFlags::Position;

        // other ppls vehicles just get buggy after y=-1000
        float posL2 = pos.LengthSquared();
        bool newIsIdle = pos.y < -950 || posL2 == 0 || Math::IsNaN(posL2);
        if (newIsIdle != this.isIdle) {
            // print("Player " + playerName + " new is idle: " + newIsIdle + " (was: " + this.isIdle + ")");
            this.isIdle = newIsIdle;
            updatedThisFrame |= UpdatedFlags::Idle;
        }

        if (discontinuityCount != newDiscontCount) {
            discontinuityCount = newDiscontCount;
            priorPos = pos;
            priorVel = vel;
            updatedThisFrame |= UpdatedFlags::DiscontinuityCount;
        }
        if (newFrozen != stateFrozen) {
            updatedThisFrame |= UpdatedFlags::FrozenVehicleState;
            stateFrozen = newFrozen;
        }

        bool newFlying;
        if (this.isFlying && !isIdle && !stateFrozen) {
            newFlying = anyWheelFlying;
        } else {
            newFlying = !isIdle && !stateFrozen && allWheelsFlying;
        }

        // once we start falling, we want to keep falling
        bool isFalling = newFlying && (this.isFalling || vel.y < -0.05);
        // update flying/falling values
        if (newFlying != this.isFlying) {
            this.isFlying = newFlying;
            updatedThisFrame |= UpdatedFlags::Flying;
            if (newFlying) {
                flyStart = pos;
                flyStartTs = Time::Now;
                // EmitStatusAnimation(this.GenerateFlyingAnim());
            } else {
                flyStart = vec3();
            }
        }

        if (isFalling != this.isFalling) {
            this.isFalling = isFalling;
            updatedThisFrame |= UpdatedFlags::Falling;
            if (isFalling) {
                fallStart = pos;
                fallStartTs = Time::Now;
            } else {
                fallStart = vec3();
            }
        }

        AfterUpdate();
    }

    void AfterUpdate() {
        if (updatedThisFrame & UpdatedFlags::DiscontinuityCount > 0) {
            EmitOnPlayerRespawn(this);
            if (HasFallTracker()) {
                GetFallTracker().OnPlayerRespawn(this);
            }
            @fallTracker = null;
            @lastFall = null;
            lastRespawn = Time::Now;
        }
        if (isFalling && fallTracker !is null) {
            fallTracker.Update(pos.y);
        }
        if (!isFalling && lastFall !is null && lastFall.HasExpired()) {
            @lastFall = null;
        }
        if (updatedThisFrame & UpdatedFlags::Falling > 0) {
            AfterUpdate_FallTracker();
        }
        if (isLocal) {
            if (!TitleGag::IsReady() && this.pos.y >= 106.0) {
                TitleGag::OnReachFloorOne();
            }
            if (updatedThisFrame & UpdatedFlags::Position > 0) {
                Stats::OnLocalPlayerPosUpdate(this);
            }
        }
    }

    void AfterUpdate_FallTracker() {
        if (lastRespawn + 200 > Time::Now) {
            // don't count the slight fall at respawn.
            return;
        }
        if (isFalling) {
            if (lastFall !is null && lastFall.endTime + AFTER_FALL_STABLE_AFTER > Time::Now) {
                @fallTracker = lastFall;
                @lastFall = null;
                fallTracker.OnContinueFall(this);
            } else {
                @fallTracker = FallTracker(pos.y, flyStart.y, this);
                @lastFall = null;
            }
        } else {
            @lastFall = fallTracker;
            if (fallTracker !is null) {
                fallTracker.OnEndFall(this);
                @fallTracker = null;
                if (lastFall.ShouldIgnoreFall()) {
                    @lastFall = null;
                }
            }
        }
    }

    FallTracker@ GetFallTracker() {
        if (fallTracker !is null) return fallTracker;
        return lastFall;
    }

    bool HasFallTracker() {
        return fallTracker !is null || lastFall !is null;
    }

    vec2 lastMinimapPos;

    vec3 vel;
    vec3 pos;
    quat rot;
    // not updated when getting details from player
    float groundDist;
    bool isFlying;
    bool isFalling;
    vec3 flyStart;
    uint flyStartTs;
    vec3 fallStart;
    uint fallStartTs;
    // if the player model is at 0,0,0 or no vehicle state is present
    bool isIdle = true;

    float FallYDistance() {
        if (!isFalling) return 0.;
        if (fallTracker !is null) return fallTracker.HeightFallen();
        return fallStart.y - pos.y;
        // return flyStart.y - pos.y;
    }


    Animation@ GenerateFlyingAnim() {
        return PlayerFlyingAnim(this);
    }

    string DebugString() {
        return playerName + ": \n  pos: " + pos.ToString() + "\n  vel: " + vel.ToString() + "\n  rot: " + rot.ToString() + "\n  flying: " + isFlying + "\n  falling: " + isFalling + "\n  groundDist: " + groundDist + "\n  idle: " + isIdle + "\n  frozen: " + stateFrozen + "\n  lastMinimapPos: " + lastMinimapPos.ToString() + "\n  updatedThisFrame: " + updatedThisFrame + "\n  discontinuityCount: " + discontinuityCount + "\n  lastVehicleId: " + Text::Format("0x%08x", lastVehicleId)
            + "\n  vfpTimeDelta: " + Text::Format("%.3f", vfpTimeDelta);
    }

    bool IsIdleOrNotUpdated() {
        return isIdle || updatedThisFrame == UpdatedFlags::None
            || updatedThisFrame & UpdatedFlags::Position == 0;
    }

    void DrawDebugTree_Player(uint i) {
        UI::PushFont(f_MonoSpace);
        UI::PushID(i);
        // +Text::Format("0x%x", i)
        if (UI::TreeNode("Raw Player "+": " + this.playerName + "##debug")) {
            if (player is null) UI::Text("Null Player!?");
            auto capacity = LEN_CSmPlayer_NetPacketsBuf;
            auto nextIx = Dev::GetOffsetUint32(player, O_CSmPlayer_NetPacketsBuf_NextIx);
            auto currIx = (nextIx + 200) % capacity;
            auto prevIx = (currIx + 200) % capacity;
            auto offset = O_CSmPlayer_NetPacketsBuf + currIx * SZ_CSmPlayer_NetPacketsBufStruct;
            UI::Text("NextIx: " + Text::Format("0x%x", nextIx) + ", CurrIx: " + Text::Format("0x%x", currIx));
            UI::Text("Offset: " + Text::Format("0x%04x", offset));
            auto lastUpdateTime = Dev::GetOffsetUint32(player, O_CSmPlayer_NetPacketsUpdatedBuf + prevIx * SZ_CSmPlayer_NetPacketsUpdatedBufEl);
            auto currUpdateTime = Dev::GetOffsetUint32(player, O_CSmPlayer_NetPacketsUpdatedBuf + currIx * SZ_CSmPlayer_NetPacketsUpdatedBufEl);
            UI::Text("LastUpdateTime: " + Text::Format("%d", lastUpdateTime) + ", CurrUpdateTime: " + Text::Format("%d", currUpdateTime));
            UI::Text("TimeDiff: " + Text::Format("%d", currUpdateTime - lastUpdateTime));
            CopiableLabeledValue("lastMinimapPos", this.lastMinimapPos.ToString());

            // for (uint j = 0; j < 0xD8; j += 8) {
            //     auto asInts = Dev::GetOffsetNat2(player, offset + j);
            //     UI::Text(Text::Format("+0x%02x: ", j) + Dev::GetOffsetVec2(player, offset + j).ToString() + " | " + Dev::GetOffsetNat2(player, offset + j).ToString() + " | " + Text::Format("0x%04x", asInts.x) + ", " + Text::Format("0x%04x", asInts.y));
            // }

            // 0x0: 1
            // 0x4: quat?
            // 0x14: pos
            // 0x20: velocity
            // 0x38: flags -- 0x400 normally; 0x100 = braking; 0x800 = sliding?
            //       -- 0x2000: reactor?, 0x1: snowcar, 0x40000 = nosteer
            //       -- 0x800000: spawning, 0x1000000: unspawned, 0x8000000: respawning
            // 0x3A: gear (uint4)
            // 0x3c: RPM
            // 0x40: steering and gas (vec2; [-1,1], [0,1])
            // 0x48: wheel rot float
            // 0x4C: unk uint32
            // 0x58: resapwn time (uint),
            // 0x5C: respawning at CP uint16
            // 0x60: discontinuetyCount (respanw) uint16
            // whell structs, c0 - a4; 0x1c bytes; so starts at 0x68 till end
            //    - 0x0: flags?
            //    - 0x4: wheel rot (float)
            //    - 0x10: wheel icing (float)
            //    - 0x18: wheel on ground (last in struct, bool)
            CopiableLabeledValue("0x1", Text::Format("0x%04x", Dev::GetOffsetUint32(player, offset + 0x0)));
            CopiableLabeledValue("Quat", Dev_GetOffsetQuat(player, offset + 0x4).ToString());
            CopiableLabeledValue("Pos", Dev::GetOffsetVec3(player, offset + 0x14).ToString());
            CopiableLabeledValue("Vel", Dev::GetOffsetVec3(player, offset + 0x20).ToString());
            CopiableLabeledValue("Forces", Dev::GetOffsetVec3(player, offset + 0x2C).ToString());
            // CopiableLabeledValue("0x2C", Text::Format("0x%08x", Dev::GetOffsetUint32(player, offset + 0x2C)) + Text::Format(" / %.2f", Dev::GetOffsetFloat(player, offset + 0x2C)));
            // CopiableLabeledValue("0x30", Text::Format("0x%08x", Dev::GetOffsetUint32(player, offset + 0x30)) + Text::Format(" / %.2f", Dev::GetOffsetFloat(player, offset + 0x30)));
            // CopiableLabeledValue("0x34", Text::Format("0x%08x", Dev::GetOffsetUint32(player, offset + 0x34)) + Text::Format(" / %.2f", Dev::GetOffsetFloat(player, offset + 0x34)));
            auto flags = Dev::GetOffsetUint32(player, offset + 0x38);
            CopiableLabeledValue("Flags", Text::Format("0x%08x", flags));

            UI::SameLine();
            string flagsStr = "";
            if (flags & 0x400 != 0) flagsStr += "Normal?, ";
            if (flags & 0x100 != 0) flagsStr += "Braking, ";
            if (flags & 0x800 != 0) flagsStr += "Sliding, ";
            if (flags & 0x2000 != 0) flagsStr += "Reactor?, ";
            if (flags & 0x1 != 0) flagsStr += "Snowcar, ";
            if (flags & 0x40000 != 0) flagsStr += "NoSteer, ";
            if (flags & 0x800000 != 0) flagsStr += "Spawning, ";
            if (flags & 0x1000000 != 0) flagsStr += "Unspawned, ";
            if (flags & 0x8000000 != 0) flagsStr += "Respawning, ";
            UI::Text(flagsStr);

            auto gear = Dev::GetOffsetUint8(player, offset + 0x3B) >> 4;
            CopiableLabeledValue("Gear", Text::Format("0x%01x", gear));
            CopiableLabeledValue("RPM", Text::Format("%.0f", Dev::GetOffsetFloat(player, offset + 0x3C)));
            CopiableLabeledValue("Steering", Text::Format("%.2f", Dev::GetOffsetFloat(player, offset + 0x40)));
            CopiableLabeledValue("Gas", Text::Format("%.2f", Dev::GetOffsetFloat(player, offset + 0x44)));
            CopiableLabeledValue("WheelYaw", Text::Format("%.2f", Dev::GetOffsetFloat(player, offset + 0x48)));
            CopiableLabeledValue("0x4C", Text::Format("0x%08x", Dev::GetOffsetUint32(player, offset + 0x4C)));
            CopiableLabeledValue("RespawnTime", Text::Format("0x%08x", Dev::GetOffsetUint32(player, offset + 0x58)));
            CopiableLabeledValue("RespawnCP", Text::Format("0x%08x", Dev::GetOffsetUint16(player, offset + 0x5C)));
            CopiableLabeledValue("DiscontinuityCount", Text::Format("0x%08x", Dev::GetOffsetUint16(player, offset + 0x60)));
            for (uint w = 0; w < 4; w++) {
                // order: FL, FR, RR, RL
                UI::Text("Wheel " + tostring(WheelOrder(w)) + ":");
                UI::Indent();
                auto wheelOffset = offset + 0x68 + w * 0x1C;
                CopiableLabeledValue("WheelFlags", Text::Format("0x%08x", Dev::GetOffsetUint32(player, wheelOffset + 0x0)));
                CopiableLabeledValue("WheelRot", Text::Format("%.2f", Dev::GetOffsetFloat(player, wheelOffset + 0x4)));
                CopiableLabeledValue("0x8", Text::Format("0x%08x", Dev::GetOffsetUint32(player, wheelOffset + 0x8)));
                CopiableLabeledValue("WheelIcing", Text::Format("%.2f", Dev::GetOffsetFloat(player, wheelOffset + 0x10)));
                CopiableLabeledValue("0x14", Text::Format("0x%08x", Dev::GetOffsetUint32(player, wheelOffset + 0x14)));
                CopiableLabeledValue("WheelOnGround", tostring(0 != Dev::GetOffsetUint8(player, wheelOffset + 0x18)));
                UI::Unindent();
            }
            UI::TreePop();
        }
        UI::PopID();
        UI::PopFont();
    }

    void DrawDebugTree(uint i) {
        UI::PushID(i);
        if (UI::TreeNode("Player "+Text::Format("0x%x", i)+": " + this.playerName + "##debug")) {

            CopiableLabeledValue("Fall Tracker", this.fallTracker is null ? "null" : this.fallTracker.ToString());
            CopiableLabeledValue("Last Fall", this.lastFall is null ? "null" : this.lastFall.ToString());
            CopiableLabeledValue("Vehicle ID", Text::Format("0x%08x", this.lastVehicleId));
            CopiableLabeledValue("Login", this.playerLogin);
            CopiableLabeledValue("Score.Id.Value", tostring(this.playerScoreMwId));
            CopiableLabeledValue("isLocal", tostring(this.isLocal));
            CopiableLabeledValue("vfpTimeDelta", Text::Format("%.3f", this.vfpTimeDelta));
            CopiableLabeledValue("pos", this.pos.ToString());
            CopiableLabeledValue("dir", this.rot.ToString());
            CopiableLabeledValue("vel", Text::Format("%.2f", this.vel.Length()) + ", " + this.vel.ToString());
            CopiableLabeledValue("groundDist", tostring(this.groundDist));
            CopiableLabeledValue("isFlying", tostring(this.isFlying));
            CopiableLabeledValue("isFalling", tostring(this.isFalling));
            CopiableLabeledValue("FallYDistance", '' + this.FallYDistance());
            CopiableLabeledValue("isIdle", '' + this.isIdle);
            CopiableLabeledValue("respawnCount", '' + this.discontinuityCount);
            CopiableLabeledValue("stateFrozen", '' + this.stateFrozen);
            CopiableLabeledValue("lastMinimapPos", this.lastMinimapPos.ToString());
            // draw flags
            string updated = "Updated: ";
            if (this.updatedThisFrame == 0) updated += "None";
            else {
                if (this.updatedThisFrame & UpdatedFlags::Position != 0) updated += "Position, ";
                if (this.updatedThisFrame & UpdatedFlags::Flying != 0) updated += "Flying, ";
                if (this.updatedThisFrame & UpdatedFlags::Falling != 0) updated += "Falling, ";
                if (this.updatedThisFrame & UpdatedFlags::Input != 0) updated += "Input, ";
                if (this.updatedThisFrame & UpdatedFlags::Floor != 0) updated += "Floor, ";
                if (this.updatedThisFrame & UpdatedFlags::VehicleId != 0) updated += "VehicleId, ";
                if (this.updatedThisFrame & UpdatedFlags::Idle != 0) updated += "Idle, ";
                if (this.updatedThisFrame & UpdatedFlags::DiscontinuityCount != 0) updated += "DiscontinuityCount, ";
                if (this.updatedThisFrame & UpdatedFlags::FrozenVehicleState != 0) updated += "FrozenVehicleState, ";
                updated = updated.SubStr(0, updated.Length - 2);
            }
            UI::Text(updated);
            UI::TreePop();
        }
        UI::PopID();

    }


}

enum PlayerNetStructFlags {
    Snowcar     = 0x1,
    Braking     = 0x100,
    Normal      = 0x400,
    // not all sliding, but is when you're braking, maybe it's Smoking?
    Sliding     = 0x800,
    Reactor     = 0x2000,
    NoSteer     = 0x40000,
    Spawning    = 0x800000,
    Unspawned   = 0x1000000,
    Respawning  = 0x8000000,
}

enum UpdatedFlags {
    None = 0,
    Position = 1,
    Flying = 2,
    Falling = 4,
    Input = 8,
    Floor = 16,
    VehicleId = 32,
    Idle = 64,
    DiscontinuityCount = 128,
    FrozenVehicleState = 256,
}


class Event {
    int info = EventInfo::None;
    bool isActive = false;
    ref@ floorInfo = null;


    Event() {}

    Event@ WithVehicleState(CSceneVehicleVisState@ state) {
        info = info | EventInfo::VehicleState;        // todo
        return this;
    }
    Event@ WithActiveState(bool active) {
        isActive = active;
        info = info | EventInfo::Active;
        return this;
    }
    Event@ WithFloorInfo(ref@ floorInfo) {
        @this.floorInfo = floorInfo;
        info = info | EventInfo::FloorInfo;
        return this;
    }
    Event@ WithRaceState() {
        info = info | EventInfo::RaceState;
        return this;
    }
    Event@ WithCameraChange() {
        info = info | EventInfo::CameraChange;
        return this;
    }
    Event@ WithSpectating() {
        info = info | EventInfo::Spectating;
        return this;
    }
}

enum EventInfo {
    None = 0,
    VehicleState = 1,
    FloorInfo = 2,
    RaceState = 4,
    CameraChange = 8,
    Spectating = 16,
    Active = 32,
    // Idle = 64,
}





// for a little status list of events
class PlayerFlyingAnim : Animation {
    PlayerState@ player;
    bool wasFlying;
    vec3 flyingStart;
    vec3 flyingLast;
    float fallDist;
    vec2 lastScale;
    FlyingEndedAnim@ delegate;

    PlayerFlyingAnim(PlayerState@ player) {
        super("Flying: " + player.playerName);
        @this.player = player;
        wasFlying = player.isFlying;
        flyingStart = player.pos;
        flyingLast = player.pos;
    }

    bool Update() override {
        if (!g_ShowFalls) return false;
        if (delegate !is null) return delegate.Update();
        if (!wasFlying || player.isIdle || player.hasLeftGame) {
            return false;
        }
        if (!player.isFlying || player.stateFrozen) {
            if (wasFlying) {
                // flying ended
                wasFlying = false;
                if (lastScale.x < 0.001) {
                    return false;
                }
                // so it isn't cleared from the list; returns true
                return ReplaceStatusAnimation(this, FlyingEndedAnim(this));
                // @delegate = FlyingEndedAnim(this);
                // return delegate.Update();
            }
            return false;
        }
        flyingLast = player.pos;
        fallDist = player.FallYDistance();
        return true;
    }

    vec2 Draw() override {
        if (delegate !is null) return delegate.Draw();
        if (fallDist < 0.0) {
            return vec2();
        }
        lastScale = vec2(Math::Clamp(fallDist / 20.0, 0.0001, 1.0));
        if (lastScale.x * 20.0 < 2.0) {
            return vec2();
        }
        nvg::Scale(lastScale);
        auto size = DrawTextWithShadow(vec2(), MsgText());
        // if (Math::IsNaN(size.x) || Math::IsInf(size.x)) {
        //     nvg::Scale(1.0 / (lastScale));
        //     return vec2();
        // }
        size += vec2(0, 8.0);
        size *= lastScale;
        nvg::Scale(1.0 / lastScale);
        return size;
    }

    string MsgText() {
        return player.playerName + ": " + Text::Format("%.1f", this.fallDist);
    }

    string ToString(int i = -1) override {
        if (delegate !is null) return delegate.ToString(i);
        if (i == -1) {
            return name + ": " + MsgText();
        }
        return "[ " + i + " ] " + name + ": " + MsgText();
    }
}

const float FLYING_END_ANIM_DURATION = 5000;
const float INV_FLYING_END_ANIM_DURATION = 1. / 5000.;

class FlyingEndedAnim : Animation {
    PlayerState@ player;
    string playerName;
    float fallDist;
    bool didFall;
    vec2 baseScale;


    FlyingEndedAnim(PlayerFlyingAnim@ flyAnim) {
        @player = flyAnim.player;
        playerName = flyAnim.player.playerName;
        super("Flying ended: " + playerName);
        fallDist = flyAnim.fallDist;
        didFall = fallDist > 0.0;
        baseScale = flyAnim.lastScale;
        // if (Math::IsNaN(baseScale.x)) {
        //     baseScale = vec2(1.0);
        // }
        // if (Math::IsInf(baseScale.x)) {
        //     baseScale = vec2(1.0);
        // }
    }

    bool Update() override {
        // these sometimes give NaN which is very CPU heavy for some reason
        if (baseScale.x * 20.0 < 2.0 || fallDist < 2.0) {
            return false;
        }
        auto now = Time::Now;
        if (float(now - start) >= FLYING_END_ANIM_DURATION) {
            return false;
        }
        return true;
    }

    vec2 Draw() override {
        vec4 color = vec4(1.0, 1.0, 0.5, 1.0);
        color.w = 1.0 - float(Time::Now - start) * INV_FLYING_END_ANIM_DURATION;
        vec2 scale = vec2(Math::Clamp(color.w * 5.0, 0.01, 1.0));
        if (scale.x * 20.0 < 2.0) {
            return vec2();
        }
        auto finalScale = scale * baseScale;
        nvg::Scale(finalScale);
        auto size = DrawTextWithShadow(vec2(), MsgText(), color);
        // if (Math::IsNaN(size.x) || Math::IsInf(size.x)) {
        //     nvg::Scale(1.0 / (finalScale));
        //     return vec2();
        // }
        size += vec2(0, 8.0);
        size *= finalScale;
        nvg::Scale(1.0 / (finalScale));
        return size;
    }

    string MsgText() {
        return playerName + ": " + Text::Format("%.1f", fallDist);
    }

    string ToString(int i = -1) override {
        if (i == -1) {
            return name + ": " + MsgText();
        }
        return "[ " + i + " ] " + name + ": " + MsgText() + " (scale: " + baseScale.ToString() + ")";
    }
}


enum WheelOrder {
    FL = 0,
    FR = 1,
    RR = 2,
    RL = 3,
}
