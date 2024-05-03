/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
dictionary yieldReasons;
void yield_why(const string &in why) {
    if (!yieldReasons.Exists(why)) {
        yieldReasons[why] = 1;
    } else {
        yieldReasons[why] = 1 + int(yieldReasons[why]);
    }
    yield();
}
