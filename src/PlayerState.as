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

    // changed flags, type: union of UpdatedFlags
    int updatedThisFrame = UpdatedFlags::None;


    PlayerState() {}
    PlayerState(CSmPlayer@ player) {
        @this.player = player;
        playerScoreMwId = player.Score.Id.Value;
        playerName = player.User.Name;
        playerLogin = player.User.Login;
    }


    // run this first to clear references
    void Reset() {
        @player = null;
        @vehicle = null;
        updatedThisFrame = UpdatedFlags::None;
        // this will be set to false if we get an update (isIdle = pos.LenSq == 0)
        isIdle = true;
    }

    void ResetUpdateFlags() {
        updatedThisFrame = UpdatedFlags::None;
    }

    void Update(CSmPlayer@ player) {
        @this.player = player;
        auto entId = player.GetCurrentEntityID();
        if (entId != lastVehicleId) {
            PS::UpdateVehicleId(this, entId);
            lastVehicleId = entId;
            updatedThisFrame |= UpdatedFlags::VehicleId;
            trace('Updated vehicle id for ' + playerName + ": " + Text::Format("0x%08x", entId));
        }
    }

    void UpdateVehicleState(CSceneVehicleVis@ vis) {
        @vehicle = vis;
        // updatedThisFrame |= UpdatedFlags::Flying | UpdatedFlags::Falling | UpdatedFlags::Position;
        auto @state = vis.AsyncState;

        groundDist = state.GroundDist;
        if (pos.LengthSquared() == 0) {
            pos = state.Position;
        } else {
            // state.WorldVel is before collisions
            // vel = state.Position - pos;
            vel = state.WorldVel;
            if (vel.LengthSquared() < 0.0000001) {
                vel = vec3();
            }
        }
        pos = state.Position;
        dir = state.Dir;
        up = state.Up;
        left = state.Left;
        updatedThisFrame |= UpdatedFlags::Position;

        // other ppls vehicles just get buggy after y=-1000
        bool isIdle = pos.y < -950 || pos.LengthSquared() == 0;
        if (isIdle != this.isIdle) {
            this.isIdle = isIdle;
            updatedThisFrame |= UpdatedFlags::Idle;
        }
        // state.DiscontinuityCount does not work for some reason
        auto newDiscontCount = Dev::GetOffsetUint8(state, 0xA);
        if (discontinuityCount != newDiscontCount) {
            discontinuityCount = newDiscontCount;
            updatedThisFrame |= UpdatedFlags::DiscontinuityCount;
        }
        auto newFrozen = Dev::GetOffsetUint8(state, 0x1BC) > 0;
        if (newFrozen != stateFrozen) {
            updatedThisFrame |= UpdatedFlags::FrozenVehicleState;
            stateFrozen = newFrozen;
        }

        bool newFlying;
        if (this.isFlying && !isIdle && !stateFrozen) {
            newFlying = state.FLGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null
                || state.FRGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null
                || state.RLGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null
                || state.RRGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null;
        } else {
            newFlying = !isIdle && !stateFrozen
                && state.FLGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null
                && state.FRGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null
                && state.RLGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null
                && state.RRGroundContactMaterial == EPlugSurfaceMaterialId::XXX_Null;
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
                EmitStatusAnimation(this.GenerateFlyingAnim());
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
    }

    vec3 vel;
    vec3 pos;
    vec3 dir;
    vec3 up;
    vec3 left;
    float groundDist;
    bool isFlying;
    bool isFalling;
    vec3 flyStart;
    uint flyStartTs;
    vec3 fallStart;
    uint fallStartTs;
    // if the player model is at 0,0,0 or no vehicle state is present
    bool isIdle;

    float FallYDistance() {
        if (!isFalling) return 0.;
        return fallStart.y - pos.y;
        // return flyStart.y - pos.y;
    }


    Animation@ GenerateFlyingAnim() {
        return PlayerFlyingAnim(this);
    }

    void DrawDebugTree_Player(uint i) {
        UI::PushFont(f_MonoSpace);
        UI::PushID(i);
        if (UI::TreeNode("Raw Player "+Text::Format("0x%x", i)+": " + this.playerName + "##debug")) {
            if (player is null) UI::Text("Null Player!?");
            auto capacity = 201;
            auto nextIx = Dev::GetOffsetUint32(player, 0xBE1C);
            auto currIx = (nextIx + 200) % capacity;
            auto offset = 0x1160 + currIx * 0xD8;
            UI::Text("NextIx: " + Text::Format("0x%x", nextIx) + ", CurrIx: " + Text::Format("0x%x", currIx));
            UI::Text("Offset: " + Text::Format("0x%04x", offset));
            for (uint j = 0; j < 0xD8; j += 8) {
                auto asInts = Dev::GetOffsetNat2(player, offset + j);
                UI::Text(Text::Format("+0x%02x: ", j) + Dev::GetOffsetVec2(player, offset + j).ToString() + " | " + Dev::GetOffsetNat2(player, offset + j).ToString() + " | " + Text::Format("0x%04x", asInts.x) + ", " + Text::Format("0x%04x", asInts.y));

                // 0x0: 1
                // 0x4: quat?
                // 0x14: pos
                // 0x20: ?
                // 0x38: flags -- 0x400 normally; 0x500 = braking; 0x100 = braking
                //       -- 0x2000: reactor?, 0x1: snowcar
                // 0x3A: gear (uint16)
                // 0x3c: RPM
                // 0x40: steering and gas (vec2; [-1,1], [0,1])
                // 0x48: wheel rot?? (float [])
                // 0x58: resapwn time (uint), some flag (0xe while respawning) uint16
                // 0x60: discontinuetyCount (respanw) uint16
                // whell structs, c0 - a4; 0x1c bytes; so starts at 0x68 till end
                //    - 0x0: flags?
                //    - 0x4: wheel rot (float)
                //    - 0x10: wheel icing (float)
                //    - 0x18: wheel on ground (last in struct, bool)

            }
            UI::TreePop();
        }
        UI::PopID();
        UI::PopFont();
    }

    void DrawDebugTree(uint i) {
        UI::PushID(i);
        if (UI::TreeNode("Player "+Text::Format("0x%x", i)+": " + this.playerName + "##debug")) {
            CopiableLabeledValue("Vehicle ID", Text::Format("0x%08x", this.lastVehicleId));
            CopiableLabeledValue("Login", this.playerLogin);
            CopiableLabeledValue("Score.Id.Value", tostring(this.playerScoreMwId));
            CopiableLabeledValue("pos", this.pos.ToString());
            CopiableLabeledValue("up", this.up.ToString());
            CopiableLabeledValue("dir", this.dir.ToString());
            CopiableLabeledValue("left", this.left.ToString());
            CopiableLabeledValue("vel", Text::Format("%.2f", this.vel.Length()) + ", " + this.vel.ToString());
            CopiableLabeledValue("groundDist", tostring(this.groundDist));
            CopiableLabeledValue("isFlying", tostring(this.isFlying));
            CopiableLabeledValue("isFalling", tostring(this.isFalling));
            CopiableLabeledValue("FallYDistance", '' + this.FallYDistance());
            CopiableLabeledValue("isIdle", '' + this.isIdle);
            CopiableLabeledValue("respawnCount", '' + this.discontinuityCount);
            CopiableLabeledValue("stateFrozen", '' + this.stateFrozen);
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
        info = info | EventInfo::VehicleState;
        // todo
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
        if (lastScale.x * 20.0 < 1.0) {
            return vec2();
        }
        nvg::Scale(lastScale);
        auto size = DrawTextWithStroke(vec2(), MsgText(), vec4(1), 0.0);
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
        if (now - start >= FLYING_END_ANIM_DURATION) {
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
        auto size = DrawTextWithStroke(vec2(), MsgText(), color);
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
