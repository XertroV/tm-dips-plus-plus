dictionary yieldReasons;
void yield_why(const string &in why) {
    if (!yieldReasons.Exists(why)) {
        yieldReasons[why] = 1;
    } else {
        yieldReasons[why] = 1 + int(yieldReasons[why]);
    }
    yield();
}
