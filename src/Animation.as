class Animation {
    int id;
    string name;
    uint start;

    Animation(const string &in name) {
        this.name = name;
        this.start = Time::Now;
        id = Math::Rand(0, 0x7FFFFFFF);
    }

    bool opEquals(const Animation &other) const {
        return id == other.id;
    }

    // override for custom on end behavior
    void OnEndAnim() {
    }

    // Return false when done. `Draw` will be called if this returns true. This method should be overridden
    bool Update() {
        return false;
    }

    // Called when `Update` returns true. Returns size. This method should be overridden
    vec2 Draw() {
        return vec2();
    }

    string ToString(int i = -1) {
        return name;
    }
}

Animation@[] subtitleAnims;
Animation@[] textOverlayAnims;
Animation@[] statusAnimations;
FloorTitleGeneric@[] titleScreenAnimations;


void ClearAnimations() {
    subtitleAnims.Resize(0);
    textOverlayAnims.Resize(0);
    statusAnimations.Resize(0);
    titleScreenAnimations.Resize(0);
}

bool IsVoiceLinePlaying() {
    return subtitleAnims.Length > 0;
}

bool IsTitleGagPlaying() {
    return titleScreenAnimations.Length > 0;
}

void AddTitleScreenAnimation(FloorTitleGeneric@ anim) {
    titleScreenAnimations.InsertLast(anim);
    trace('added to titleScreenAnimations: ' + anim.ToString());
}

void AddSubtitleAnimation(Animation@ anim) {
    subtitleAnims.InsertLast(anim);
}

void EmitStatusAnimation(Animation@ anim) {
    // trace('New animation: ' + anim.name);
    statusAnimations.InsertLast(anim);
}

// use `return ReplaceStatusAnimation(oldAnim, newAnim);` to replace an animation during Update
bool ReplaceStatusAnimation(Animation@ oldAnim, Animation@ newAnim) {
    // trace('Replace animation: ' + oldAnim.name + ' -> ' + newAnim.name);
    auto oldIx = statusAnimations.Find(oldAnim);
    if (oldIx != -1) {
        @statusAnimations[oldIx] = newAnim;
    } else {
        NotifyWarning('Failed to find old animation: ' + oldAnim.name + ' -> ' + newAnim.name);
        statusAnimations.InsertLast(newAnim);
    }
    return true;
}
