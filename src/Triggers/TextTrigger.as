class TextTrigger : GameTrigger {
    string[]@ options;
    uint duration = 6000; // default duration in ms

    TextTrigger(vec3 &in min, vec3 &in max, const string &in name, string[]@ options = null, uint duration = 6000) {
        super(min, max, name);
        @this.options = options;
        if (this.options is null || options.Length == 0) @this.options = {name};
        this.duration = duration;
        this.debug_strokeColor = StrHashToCol(name);
    }

    void OnEnteredTrigger(DipsOT::OctTreeRegion@ prevTrigger) override {
        auto msg = options.Length > 0 ? options[Math::Rand(0, options.Length)] : "<null>";
        // NotifyWarning("Text Trigger Activated:\n-- " + name + " --\n- msg: " + msg);
        EmitStatusAnimation(RainbowStaticStatusMsg(msg).WithDuration(duration));
    }
}

vec4 StrHashToCol(const string &in str) {
    // Convert the string to a hash and then to a color
    string hash = Crypto::MD5(str);
    return Text::ParseHexColor(hash.SubStr(0, 6));
    // vec4 c = Text::ParseHexColor(hash.SubStr(0, 6));
    // return c.xyz * 0.5 + vec3(0.5, 0.5, 0.5);
}
