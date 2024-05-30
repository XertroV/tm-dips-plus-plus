namespace UserProfiles {
    class Profile {
        string wsid;
        string name;
        int _no_spec_above;
        int _no_spec_below;

        Profile(Json::Value@ obj) {
            LoadFromJson(obj);
        }

        void LoadFromJson(Json::Value@ obj) {
            if (obj.GetType() != Json::Type::Object) {
                warn("UserProfiles::Profile::LoadFromJson: expected object, got " + obj.GetType());
                return;
            }
            if (!obj.HasKey("wsid") || !obj.HasKey("name")) {
                warn("UserProfiles::Profile::LoadFromJson: missing required fields (wsid, name). Obj: " + Json::Write(obj));
                return;
            }
            wsid = obj.Get("wsid", "");
            name = obj.Get("name", "");
            _no_spec_above = obj.Get("no_spec_above", 999);
            _no_spec_below = obj.Get("no_spec_below", -1);
            dev_trace("Loaded profile for " + name + " / " + wsid);
        }

        int get_no_spec_above() { return _no_spec_above; }
        void set_no_spec_above(int value) {
            if (value != _no_spec_above) startnew(CoroutineFunc(UpdateProfileSoon));
            _no_spec_above = value;
        }

        int get_no_spec_below() { return _no_spec_below; }
        void set_no_spec_below(int value) {
            if (value != _no_spec_below) startnew(CoroutineFunc(UpdateProfileSoon));
            _no_spec_below = value;
        }


        bool updateProfileWaiting = false;
        uint updateProfileWaitingStart = 0;
        void UpdateProfileSoon() {
            if (wsid != LocalPlayersWSID()) {
                warn("UserProfiles::Profile::UpdateProfileSoon: not my profile!");
                return;
            }
            updateProfileWaitingStart = Time::Now;
            if (updateProfileWaiting) return;
            updateProfileWaiting = true;
            while (Time::Now - updateProfileWaitingStart < 500) {
                yield();
            }
            PushMessage(SetMyProfileMsg(this.ToJson()));
            updateProfileWaiting = false;
        }

        Json::Value@ ToJson() {
            Json::Value@ obj = Json::Object();
            obj["wsid"] = wsid;
            obj["name"] = name;
            obj["no_spec_above"] = _no_spec_above;
            obj["no_spec_below"] = _no_spec_below;
            return obj;
        }
    }

    Profile@ myProfile;

    dictionary profiles;
    Profile@ GetProfile(const string &in wsid) {
        if (profiles.Exists(wsid)) {
            return cast<Profile@>(profiles[wsid]);
        }
        return null;
    }

    void HandleMsg(Json::Value@ msg) {
        if (msg.GetType() != Json::Type::Object) {
            warn("UserProfiles::HandleMsg: expected object, got " + msg.GetType());
            return;
        }
        if (!msg.HasKey('profile')) {
            warn("UserProfiles::HandleMsg: missing required field 'profile'");
            return;
        }
        Json::Value@ jp = msg['profile'];
        string wsid = jp.Get("wsid", "");
        auto profile = GetProfile(wsid);
        if (profile is null) {
            @profile = Profile(jp);
            @profiles[wsid] = profile;
        } else {
            profile.LoadFromJson(jp);
        }
        if (wsid == LocalPlayersWSID()) {
            @myProfile = profile;
        }
    }


    bool requestedProfileOnce = false;

    void DrawEditProfile() {
        if (!requestedProfileOnce && g_api !is null && g_api.HasContext) {
            requestedProfileOnce = true;
            PushMessage(GetMyProfileMsg());
        }
#if DEV
#else
        // disable till it's done
        return;
#endif
        if (myProfile is null) {
            UI::Text("Loading...");
            return;
        }
#if DEV
        UI::Text("Profile for " + myProfile.name + " / " + myProfile.wsid);
#endif
        UI::Separator();
        UI::AlignTextToFramePadding();
        UI::TextWrapped("Request no spectators above or below certain floors.\n\\$iOnly works if all parties use the plugin for normal or magic spectate.\nA message will show for them: '\\$<\\$fb2NAME requests you do not spectate above/below floor X.\\$>'");
        myProfile.no_spec_above = UI::InputInt("Disable spectators above", myProfile.no_spec_above);
        myProfile.no_spec_below = UI::InputInt("Disable spectators below", myProfile.no_spec_below);
        // UI::Separator();
    }
}
