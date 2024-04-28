enum GameTriggerTy {
    VoiceLine,
    TextOverlay,
    FloorEntry,
}

class GameTrigger : OctTreeRegion {
    mat4 mat;
    bool resetOnLeave = false;

    GameTrigger(vec3 &in min, vec3 &in max, const string &in name) {
        super(min, max);
        this.name = name;
        this.mat = mat4::Translate(min);
    }

    vec4 debug_strokeColor = vec4(1, 0, 0, 1);
    vec3 screenPos;

    void Debug_NvgDrawTrigger() {
        screenPos = Camera::ToScreen(midp);
        // behind check
        if (screenPos.z > 0) return;

        nvgDrawBlockBox(mat, size, debug_strokeColor);
    }

    void Debug_NvgDrawTriggerName() {
        if (screenPos.z > 0) return;

        nvg::FontSize(g_screen.y / 50.);
        nvg::FontFace(f_Nvg_ExoMedium);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);

        DrawTextWithStroke(screenPos.xy, name, debug_strokeColor);
    }

    void OnLeftTrigger(OctTreeRegion@ newTrigger) {
        // implement via overrides
    }

    void OnEnteredTrigger(OctTreeRegion@ prevTrigger) {
        // implement via overrides
    }

    void ClearLastTriggerIfNewNull(OctTreeRegion@ newTrigger) {
        if (newTrigger is null) {
            @lastTriggerHit = null;
            lastTriggerName = "";
        }
    }
}

// triggers when the point is > radius away from center, and height is between min and max heights
class AntiCylinderTrigger : GameTrigger {
    float radius;
    float radiusSq;
    vec2 center;
    vec2 minMaxHeight;

    AntiCylinderTrigger(float radius, vec2 &in center, vec2 &in minMaxHeight, const string &in name) {
        // bounding box will be approx, midp will work
        super(vec3(center.x - radius, minMaxHeight.x, center.y - radius), vec3(center.x + radius, minMaxHeight.y, center.y + radius), name);
        this.radius = radius;
        this.radiusSq = radius * radius;
        this.center = center;
        this.minMaxHeight = minMaxHeight;
    }

    bool PointInside(const vec3&in point) override {
        auto xz = vec2(point.x, point.z);
        if ((xz-center).LengthSquared() < radiusSq) return false;
        return point.y >= minMaxHeight.x && point.y <= minMaxHeight.y;
    }

    bool RegionInside(OctTreeRegion@ region) override {
        throw("unimplemented");
        return false;
    }

    bool Intersects(OctTreeRegion@ region) override {
        throw("unimplemented");
        return false;
    }
}

class GagVoiceLineTrigger : GameTrigger {
    GagVoiceLineTrigger(vec3 &in min, vec3 &in max, const string &in name) {
        super(min, max, name);
        debug_strokeColor = GenRandomColor();
        resetOnLeave = true;
    }
}


class PlaySoundTrigger : GameTrigger {
    string audioFile;
    AudioChain@ audioChain;

    PlaySoundTrigger(vec3 &in min, vec3 &in max, const string &in name, const string &in audioFile) {
        super(min, max, name);
        debug_strokeColor = GenRandomColor();
        resetOnLeave = true;
        this.audioFile = audioFile;
    }

    void OnEnteredTrigger(OctTreeRegion@ prevTrigger) override {
        Dev_Notify(name + " entered.");
        startnew(CoroutineFunc(PlayItem));
        Stats::LogTriggeredSound(name, audioFile);
    }

    void OnLeftTrigger(OctTreeRegion@ newTrigger) override {
        Dev_Notify(name + " left.");
        if (resetOnLeave) {
            ClearLastTriggerIfNewNull(newTrigger);
        }
    }

    void PlayItem() {
        if (audioChain !is null) {
            audioChain.StartFadeOutLoop();
            @audioChain = null;
        }
        if (!AudioFilesExist({audioFile})) {
            warn("Audio file not found, waiting for it to exist: " + audioFile);
        }
        while (!AudioFilesExist({audioFile})) {
            yield();
        }
        if (!AudioFilesExist({audioFile}, false)) {
            warn("Audio file not found: " + audioFile);
            return;
        }
        @audioChain = AudioChain({audioFile});
        audioChain.Play();
    }
}


class FloorVLTrigger : PlaySoundTrigger {
    int floor;
    string voiceLineFile;
    string subtitlesFile;
    SubtitlesAnim@ subtitles;

    FloorVLTrigger(vec3 &in min, vec3 &in max, const string &in name, int floor) {
        voiceLineFile = "vl/Level_" + floor + "_final.mp3";
        if (floor == 0) {
            voiceLineFile = "vl/Intro_Plugin_2.mp3";
        } else if (floor == 17) {
            voiceLineFile = "vl/Lvl_17_Finished.mp3";
        }
        subtitlesFile = "subtitles/" + voiceLineFile.Replace(".mp3", ".txt");
        super(min, max, name, voiceLineFile);
        this.floor = floor;
        debug_strokeColor = GenRandomColor();
        resetOnLeave = false;
        @subtitles = SubtitlesAnim(subtitlesFile);
    }

    OctTreeRegion@ _tmpPrevTrigger;
    void OnEnteredTrigger(OctTreeRegion@ prevTrigger) override {
        if (Stats::HasPlayedVoiceLine(floor)) return;
        @_tmpPrevTrigger = prevTrigger;
        startnew(CoroutineFunc(this.RunTrigger));
    }

    void RunTrigger() {
        PlaySoundTrigger::OnEnteredTrigger(_tmpPrevTrigger);
        while (audioChain is null || !audioChain.isPlaying) {
            yield();
        }
        Stats::SetVoiceLinePlayed(floor);
        if (subtitles !is null) {
            AddSubtitleAnimation(subtitles);
        }
    }
}

const uint TITLE_GAG_DELAY_AFTER_FALLING = 3000;

class TitleGagTrigger : GagVoiceLineTrigger {
    TitleGagTrigger(vec3 &in min, vec3 &in max, const string &in name) {
        super(min, max, name);
    }

    void OnEnteredTrigger(OctTreeRegion@ prevTrigger) override {
        Dev_Notify(name + " entered.");
        if (NewTitleGagOkay()) {
            startnew(CoroutineFunc(SelectNewTitleGagAnimationAndCollect));
        }
    }

    void OnLeftTrigger(OctTreeRegion@ newTrigger) override {
        Dev_Notify(name + " left.");
        ClearLastTriggerIfNewNull(newTrigger);
    }

    protected void SelectNewTitleGagAnimationAndCollect() {
        CollectionItem@ gag;
        bool isLocalPlayer = PS::viewedPlayer !is null && PS::viewedPlayer.isLocal;
        uint lastRespawn = PS::viewedPlayer.lastRespawn;
        if (isLocalPlayer) {
            @gag = GLOBAL_TITLE_COLLECTION.SelectOneUncollected();
        } else {
            @gag = GLOBAL_TITLE_COLLECTION.SelectOne();
        }
        if (gag is null) {
            @gag = GLOBAL_GG_TITLE_COLLECTION.SelectOne();
        }
        if (gag !is null) {
            TitleGag::MarkWaiting();
            // don't play immediately if we're falling
            if (PS::viewedPlayer !is null && PS::viewedPlayer.fallTracker !is null) {
                while (PS::viewedPlayer !is null && PS::viewedPlayer.fallTracker !is null) yield();
                sleep(TITLE_GAG_DELAY_AFTER_FALLING);
                if (PS::viewedPlayer is null || lastRespawn != PS::viewedPlayer.lastRespawn) return;
            }
            gag.PlayItem(isLocalPlayer);
        } else {
            Dev_Notify("No title gags left to select.");
        }
    }
}

class GG_VLineTrigger : AntiCylinderTrigger {
    GG_VLineTrigger(float radius, vec2 &in center, vec2 &in minMaxHeight, const string &in name) {
        super(radius, center, minMaxHeight, name);
        resetOnLeave = true;
    }

    void OnEnteredTrigger(OctTreeRegion@ prevTrigger) override {
        Notify(name + " entered.");
        if (NewTitleGagOkay()) {
            SelectNewGGAnimationAndCollect();
        }
    }

    void OnLeftTrigger(OctTreeRegion@ newTrigger) override {
        Notify(name + " left.");
        if (newTrigger is null) {
            @lastTriggerHit = null;
            lastTriggerName = "";
        }
    }

    protected void SelectNewGGAnimationAndCollect() {
        auto gag = GLOBAL_GG_TITLE_COLLECTION.SelectOneUncollected();
        if (gag !is null) {
            gag.PlayItem();
            TitleGag::MarkWaiting();
        } else {
            Notify("No GG title gags left to select.");
        }
    }
}


class TextOverlayTrigger : GameTrigger {
    TextOverlayTrigger(vec3 &in min, vec3 &in max, const string &in name) {
        super(min, max, name);
        debug_strokeColor = GenRandomColor();
        resetOnLeave = true;
    }
}

enum MonumentSubject {
    Bren = 0, Jave,
    Mapper_Maji, Mapper_Lent, Mapper_MaxChess, Mapper_SparklingW,
    Mapper_Jakah, Mapper_Classic, Mapper_Tekky, Mapper_Doondy,
    Mapper_Rioyter, Mapper_Maverick, Mapper_Sightorld, Mapper_Whiskey,
    Mapper_Plax, Mapper_Viiru, Mapper_Kubas, Mapper_Jumper471,
}

class MonumentTrigger : TextOverlayTrigger {
    MonumentSubject subject;

    MonumentTrigger(vec3 &in min, vec3 &in max, const string &in name, MonumentSubject subject) {
        super(min, max, name);
        this.subject = subject;
    }

    void OnLeftTrigger(OctTreeRegion@ newTrigger) override {
        // TextOverlayAnim handles fading out itself
    }

    void OnEnteredTrigger(OctTreeRegion@ prevTrigger) override {
        // in same trigger group, do nothing
        if (prevTrigger !is null && prevTrigger.name == name) return;
        // add text overlay anim
        if (subject == MonumentSubject::Bren) {
            textOverlayAnims.InsertLast(Bren_TextOverlayAnim());
        } else if (subject == MonumentSubject::Jave) {
            textOverlayAnims.InsertLast(Jave_TextOverlayAnim());
        }
    }
}

/*
f1 maji trigger,vec3(697, 169, 800),	vec3(725, 178, 832)
f2 lentillion,	vec3(518, 241, 640),	vec3(538, 247, 671)
f3 max,	        vec3(640, 337, 576),	vec3(672, 346, 608)
f4 sparkling,	vec3(887, 458, 604),	vec3(920, 470, 640)
f5 jakah,	    vec3(826, 546, 800),	vec3(863, 554, 832)
f6 classic,	    vec3(581, 627, 926),	vec3(630, 634, 961)
f7 tekky,	    vec3(867, 800, 673),	vec3(929, 807, 707)
f8 Doondy,	    vec3(768, 871, 993),	vec3(801, 879, 1025)
f9 rioyter,	    vec3(608, 1026, 935),	vec3(640, 1041, 960)
f10 maverick,	vec3(735, 1074, 511),	vec3(772, 1084, 545)
f11 sightorld,	vec3(830, 1161, 608),	vec3(864, 1171, 640)
f12 whiskey,	vec3(864, 1311, 762),	vec3(895, 1320, 801)
F13 plax,	    vec3(992, 1383, 746),	vec3(1024, 1389, 782)
f14 viiru,	    vec3(529, 1553, 544),	vec3(610, 1564, 608)
f15 kubas,	    vec3(799, 1640, 610),	vec3(835, 1647, 636)
f16 jumper,	    vec3(796, 1691, 546),	vec3(860, 1700, 576)


Intro,		vec3(160, 33, 672),	vec3(192, 42, 704)
Floor Gang,		vec3(298.5513916015625, 7, 421),	vec3(1101, 56, 1086)
 */


GameTrigger@[]@ generateVoiceLineTriggers() {
    GameTrigger@[] ret;
    ret.InsertLast(FloorVLTrigger(vec3(168, 24, 672),	vec3(192, 42, 740), "VL Intro", 0));
    // 420 min x = late on bridge
    ret.InsertLast(TitleGagTrigger(vec3(424, 7, 424),	vec3(1100, 57, 1100), "Floor Gang"));
    ret.InsertLast(TitleGagTrigger(vec3(384, 7, 760),	vec3(424, 57, 776), "Floor Gang"));
    ret.InsertLast(FloorVLTrigger(vec3(697, 169, 800), vec3(725, 178, 832), "VL Floor 1 - Majijej", 1));
    ret.InsertLast(FloorVLTrigger(vec3(518, 241, 640), vec3(538, 247, 671), "VL Floor 2 - Lentillion", 2));
    ret.InsertLast(FloorVLTrigger(vec3(640, 337, 576), vec3(672, 346, 608), "VL Floor 3 - MaxChess", 3));
    ret.InsertLast(FloorVLTrigger(vec3(887, 458, 604), vec3(920, 470, 640), "VL Floor 4 - SparklingW", 4));
    ret.InsertLast(FloorVLTrigger(vec3(826, 546, 800), vec3(863, 554, 832), "VL Floor 5 - Jakah", 5));
    ret.InsertLast(FloorVLTrigger(vec3(581, 626, 926), vec3(630, 634, 961), "VL Floor 6 - Classic", 6));
    ret.InsertLast(FloorVLTrigger(vec3(867, 800, 673), vec3(929, 807, 707), "VL Floor 7 - Tekky", 7));
    ret.InsertLast(FloorVLTrigger(vec3(768, 871, 993), vec3(801, 879, 1025), "VL Floor 8 - Doondy", 8));
    ret.InsertLast(FloorVLTrigger(vec3(936, 1042, 843), vec3(977, 1050, 885), "VL Floor 9 - Rioyter", 9));
    ret.InsertLast(FloorVLTrigger(vec3(735, 1074, 511), vec3(772, 1084, 545), "VL Floor 10 - Maverick", 10));
    ret.InsertLast(FloorVLTrigger(vec3(830, 1161, 608), vec3(864, 1171, 640), "VL Floor 11 - sightorld", 11));
    ret.InsertLast(FloorVLTrigger(vec3(864, 1311, 762), vec3(895, 1320, 801), "VL Floor 12 - Whiskey", 12));
    ret.InsertLast(FloorVLTrigger(vec3(992, 1383, 746), vec3(1024, 1389, 782), "VL Floor 13 - Plaxity", 13));
    ret.InsertLast(FloorVLTrigger(vec3(529, 1553, 544), vec3(610, 1564, 608), "VL Floor 14 - Viiru", 14));
    ret.InsertLast(FloorVLTrigger(vec3(800, 1640, 610), vec3(833, 1647, 637), "VL Floor 15 - Kubas", 15));
    ret.InsertLast(FloorVLTrigger(vec3(796, 1690, 544), vec3(860, 1700, 576), "VL Floor 16 - Jumper471", 16));
    // ret.InsertLast(FloorVLTrigger(vec3(), vec3(), "Finish"));
    return ret;
}

GameTrigger@[]@ generateMonumentTriggers() {
    GameTrigger@[] ret;
    // ret.InsertLast(MonumentTrigger(vec3(379, 9, 799), vec3(400, 21, 835), "Bren Monument", MonumentSubject::Bren));
    // ret.InsertLast(MonumentTrigger(vec3(400, 9, 818), vec3(405, 21, 835), "Bren Monument", MonumentSubject::Bren));
    // ret.InsertLast(MonumentTrigger(vec3(400, 9, 799), vec3(420, 21, 818), "Jave Monument", MonumentSubject::Jave));
    // far from water
    ret.InsertLast(MonumentTrigger(vec3(380, 9, 818), vec3(405, 21, 842), "Bren Monument", MonumentSubject::Bren));
    // water side bren
    ret.InsertLast(MonumentTrigger(vec3(380, 9, 800), vec3(400, 21, 818), "Bren Monument", MonumentSubject::Bren));
    ret.InsertLast(MonumentTrigger(vec3(400, 9, 800), vec3(424, 21, 818), "Jave Monument", MonumentSubject::Jave));
    return ret;
}

GameTrigger@[]@ genSpecialTriggers() {
    GameTrigger@[] ret;
    ret.InsertLast(GG_VLineTrigger(360, vec2(768, 768), vec2(169, 2000.0), "Geep Gip"));
    return ret;
}

GameTrigger@[]@ genEasterEggTriggers() {
    GameTrigger@[] ret;
    ret.InsertLast(PlaySoundTrigger(vec3(916.0, 382.0, 769.15), vec3(970.0, 408.0, 780.0), "Mario: Bye Bye", "ee/mario-byebye.mp3"));
    return ret;
}

GameTrigger@[]@ specialTriggers = genSpecialTriggers();
GameTrigger@[]@ voiceLineTriggers = generateVoiceLineTriggers();
GameTrigger@[]@ monumentTriggers = generateMonumentTriggers();
GameTrigger@[]@ easterEggTriggers = genEasterEggTriggers();

OctTree@ dd2TriggerTree = OctTree();

void InitDD2TriggerTree() {
    for (uint i = 0; i < voiceLineTriggers.Length; i++) {
        dd2TriggerTree.Insert(voiceLineTriggers[i]);
    }
    for (uint i = 0; i < monumentTriggers.Length; i++) {
        dd2TriggerTree.Insert(monumentTriggers[i]);
    }
    for (uint i = 0; i < specialTriggers.Length; i++) {
        dd2TriggerTree.Insert(specialTriggers[i]);
    }
    for (uint i = 0; i < easterEggTriggers.Length; i++) {
        dd2TriggerTree.Insert(easterEggTriggers[i]);
    }
}

void TriggerCheck_Reset() {
    @lastTriggerHit = null;
    lastTriggerName = "";
    @currTriggerHit = null;
    currTriggerName = "";
    triggerHit = false;
}

GameTrigger@ lastTriggerHit;
string currTriggerName;
GameTrigger@ currTriggerHit;
string lastTriggerName;
bool triggerHit = false;

void TriggerCheck_Update() {
    triggerHit = false;
    if (PS::localPlayer is null) return;

    auto t = cast<GameTrigger>(dd2TriggerTree.root.PointToDeepestRegion(PS::localPlayer.pos));
    bool updateCurr = t !is currTriggerHit;
    bool updateLast = t !is null && t !is lastTriggerHit;
    if (updateCurr) {
        if (currTriggerHit !is null) {
            OnLeaveTrigger(currTriggerHit, t);
        }
        currTriggerName = t is null ? "" : t.name;
        @currTriggerHit = t;
    }

    if (t is null && lastTriggerHit !is null && lastTriggerHit.resetOnLeave) {
        @lastTriggerHit = null;
        lastTriggerName = "";
    }

    if (updateLast) {
        if (t.name != lastTriggerName) {
            OnNewTriggerHit(lastTriggerHit, t);
        }
        lastTriggerName = t.name;
        @lastTriggerHit = t;
    }
}

void OnLeaveTrigger(GameTrigger@ prevTrigger, GameTrigger@ newTrigger) {
    prevTrigger.OnLeftTrigger(newTrigger);
}

void OnNewTriggerHit(GameTrigger@ lastTriggerHit, GameTrigger@ newTrigger) {
    trace('OnNewTriggerHit @ ' + PS::localPlayer.pos.ToString());
    // Notify("Hit trigger: " + newTrigger.name);
    // AddTitleScreenAnimation(MainTitleScreenAnim(newTrigger.name, "test", null));
    // NotifyWarning("Added title screen anim");
    newTrigger.OnEnteredTrigger(lastTriggerHit);
}

















// DEBUG

bool m_debugDrawTriggers = false;
bool m_debugDrawRegions = false;

void DrawTriggersTab() {
    if (voiceLineTriggers is null || dd2TriggerTree is null) return;

    bool hasGameScene = GetApp().GameScene !is null;

    m_debugDrawTriggers = UI::Checkbox("(Debug) Draw Triggers", m_debugDrawTriggers);

    // m_debugDrawRegions = UI::Checkbox("(Debug) Draw Trigger Regions", m_debugDrawRegions);
    // if (m_debugDrawRegions && hasGameScene) {
    //     dd2TriggerTree.root.Debug_NvgDrawRegions();
    // }

    if (m_debugDrawTriggers && hasGameScene) {
        for (uint i = 0; i < voiceLineTriggers.Length; i++) {
            voiceLineTriggers[i].Debug_NvgDrawTrigger();
        }
        for (uint i = 0; i < monumentTriggers.Length; i++) {
            monumentTriggers[i].Debug_NvgDrawTrigger();
        }
        for (uint i = 0; i < specialTriggers.Length; i++) {
            specialTriggers[i].Debug_NvgDrawTrigger();
        }
        for (uint i = 0; i < easterEggTriggers.Length; i++) {
            easterEggTriggers[i].Debug_NvgDrawTrigger();
        }
        for (uint i = 0; i < voiceLineTriggers.Length; i++) {
            voiceLineTriggers[i].Debug_NvgDrawTriggerName();
        }
        for (uint i = 0; i < monumentTriggers.Length; i++) {
            monumentTriggers[i].Debug_NvgDrawTriggerName();
        }
        for (uint i = 0; i < specialTriggers.Length; i++) {
            specialTriggers[i].Debug_NvgDrawTriggerName();
        }
        for (uint i = 0; i < easterEggTriggers.Length; i++) {
            easterEggTriggers[i].Debug_NvgDrawTriggerName();
        }
    }

    if (PS::localPlayer !is null) {
        UI::Text("Local Player Pos: "+PS::localPlayer.pos.ToString());
        auto t = dd2TriggerTree.root.PointToDeepestRegion(PS::localPlayer.pos);
        UI::Text("Deepest trigger: " + (t is null ? "<None>" : t.name));
        @t = dd2TriggerTree.root.PointToFirstRegion(PS::localPlayer.pos);
        UI::Text("First trigger: " + (t is null ? "<None>" : t.name));
        auto hits = dd2TriggerTree.root.PointHitsRegion(PS::localPlayer.pos);
        auto ts = dd2TriggerTree.root.PointToRegions(PS::localPlayer.pos);
        UI::Text("Hits: "+tostring(hits));
        UI::SameLine();
        UI::Text("Triggers: ("+ts.Length+")");
        UI::Indent();
        for (uint i = 0; i < ts.Length; i++) {
            UI::Text("Trigger: "+ts[i].name);
        }
        UI::Unindent();
        UI::Text("Title Gag State: " + tostring(TitleGag::state));
    } else {
        UI::Text("Local Player Pos: <None>");
    }

    UI::Separator();

    UI_Debug_OctTree(dd2TriggerTree, "DD2 Triggers");

    UI::Separator();

    UI::AlignTextToFramePadding();
    UI::Text("VL Triggers: ("+voiceLineTriggers.Length+")");
    UI::Indent();
    for (uint i = 0; i < voiceLineTriggers.Length; i++) {
        UI::Text(voiceLineTriggers[i].name);
    }
    UI::Unindent();

    UI::AlignTextToFramePadding();
    UI::Text("Monument Triggers: ("+monumentTriggers.Length+")");
    UI::Indent();
    for (uint i = 0; i < monumentTriggers.Length; i++) {
        UI::Text(monumentTriggers[i].name);
    }
    UI::Unindent();

    UI::AlignTextToFramePadding();
    UI::Text("Special Triggers: ("+specialTriggers.Length+")");
    UI::Indent();
    for (uint i = 0; i < specialTriggers.Length; i++) {
        UI::Text(specialTriggers[i].name);
    }
    UI::Unindent();

    UI::AlignTextToFramePadding();
    UI::Text("Easter Egg Triggers: ("+easterEggTriggers.Length+")");
    UI::Indent();
    for (uint i = 0; i < easterEggTriggers.Length; i++) {
        UI::Text(easterEggTriggers[i].name);
    }
    UI::Unindent();
}


void UI_Debug_OctTree(OctTree@ tree, const string &in name) {
    UI_Debug_OctTreeNode(tree.root, name + "/");
}

void UI_Debug_OctTreeNode(OctTreeNode@ node, const string &in path) {
    if (node is null) return;
    if (UI::TreeNode(path)) {

        if (node.children.Length > 0) {
            for (uint i = 0; i < node.children.Length; i++) {
                UI_Debug_OctTreeNode(node.children[i], path + i + "/");
            }
        }

        if (node.regions.Length > 0) {
            UI::AlignTextToFramePadding();
            UI::Text("Regions: ("+node.regions.Length+")");
            UI::Indent();
            for (uint i = 0; i < node.regions.Length; i++) {
                UI::Text(node.regions[i].ToString());
            }
            UI::Unindent();
        }

        if (node.points.Length > 0) {
            UI::AlignTextToFramePadding();
            UI::Text("Points: ("+node.points.Length+")");
            UI::Indent();
            for (uint i = 0; i < node.points.Length; i++) {
                UI::Text(node.points[i].ToString());
            }
            UI::Unindent();
        }

        UI::TreePop();
    }
}
