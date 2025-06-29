class TextTrigger : GameTrigger {
    string message;

    TextTrigger(vec3 &in min, vec3 &in max, const string &in name, const string &in message) {
        throw("use SpecialTextTrigger instead");
        super(min, max, name);
        this.message = message;
        this.debug_strokeColor = vec4(1, 0, 0, 1);
    }

    void OnEnteredTrigger(DipsOT::OctTreeRegion@ prevTrigger) override {
        // TODO: UI: Display the text message on screen, possibly as a temporary notification or a dedicated UI element.
        NotifyWarning("Text Trigger Activated: " + name + " - Message: " + message);
    }
}
