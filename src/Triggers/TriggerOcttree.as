enum GameTriggerTy {
    VoiceLine,
    TextOverlay,
    FloorEntry,
}

class GameTrigger : OctTreeRegion {
    // string name;
    mat4 mat;

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

class VoiceLineTrigger : GameTrigger {
    VoiceLineTrigger(vec3 &in min, vec3 &in max, const string &in name) {
        super(min, max, name);
        debug_strokeColor = vec4(Math::Rand(0.5, 1.0), Math::Rand(0.5, 1.0), Math::Rand(0.5, 1.0), 1.0);
    }
}

class TextOverlayTrigger : GameTrigger {
    TextOverlayTrigger(vec3 &in min, vec3 &in max, const string &in name) {
        super(min, max, name);
        debug_strokeColor = vec4(Math::Rand(0.5, 1.0), Math::Rand(0.5, 1.0), Math::Rand(0.5, 1.0), 1.0);
    }
}

enum MonumentSubject {
    Bren, Jave,
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
    ret.InsertLast(VoiceLineTrigger(vec3(160, 33, 672),	vec3(192, 42, 704), "VL Intro"));
    ret.InsertLast(VoiceLineTrigger(vec3(298, 7, 421),	vec3(1101, 56, 1086), "Floor Gang"));
    ret.InsertLast(VoiceLineTrigger(vec3(697, 169, 800), vec3(725, 178, 832), "VL Floor 1 - Majijej"));
    ret.InsertLast(VoiceLineTrigger(vec3(518, 241, 640), vec3(538, 247, 671), "VL Floor 2 - Lentillion"));
    ret.InsertLast(VoiceLineTrigger(vec3(640, 337, 576), vec3(672, 346, 608), "VL Floor 3 - MaxChess"));
    ret.InsertLast(VoiceLineTrigger(vec3(887, 458, 604), vec3(920, 470, 640), "VL Floor 4 - SparklingW"));
    ret.InsertLast(VoiceLineTrigger(vec3(826, 546, 800), vec3(863, 554, 832), "VL Floor 5 - Jakah"));
    ret.InsertLast(VoiceLineTrigger(vec3(581, 627, 926), vec3(630, 634, 961), "VL Floor 6 - Classic"));
    ret.InsertLast(VoiceLineTrigger(vec3(867, 800, 673), vec3(929, 807, 707), "VL Floor 7 - Tekky"));
    ret.InsertLast(VoiceLineTrigger(vec3(768, 871, 993), vec3(801, 879, 1025), "VL Floor 8 - Doondy"));
    ret.InsertLast(VoiceLineTrigger(vec3(608, 1026, 935), vec3(640, 1041, 960), "VL Floor 9 - Rioyter"));
    ret.InsertLast(VoiceLineTrigger(vec3(735, 1074, 511), vec3(772, 1084, 545), "VL Floor 10 - Maverick"));
    ret.InsertLast(VoiceLineTrigger(vec3(830, 1161, 608), vec3(864, 1171, 640), "VL Floor 11 - sightorld"));
    ret.InsertLast(VoiceLineTrigger(vec3(864, 1311, 762), vec3(895, 1320, 801), "VL Floor 12 - Whiskey"));
    ret.InsertLast(VoiceLineTrigger(vec3(992, 1383, 746), vec3(1024, 1389, 782), "VL Floor 13 - Plaxity"));
    ret.InsertLast(VoiceLineTrigger(vec3(529, 1553, 544), vec3(610, 1564, 608), "VL Floor 14 - Viiru"));
    ret.InsertLast(VoiceLineTrigger(vec3(799, 1640, 610), vec3(835, 1647, 636), "VL Floor 15 - Kubas"));
    ret.InsertLast(VoiceLineTrigger(vec3(796, 1691, 546), vec3(860, 1700, 576), "VL Floor 16 - Jumper471"));
    // ret.InsertLast(VoiceLineTrigger(vec3(), vec3(), "Finish"));
    return ret;
}

GameTrigger@[]@ generateMonumentTriggers() {
    GameTrigger@[] ret;
    // ret.InsertLast(MonumentTrigger(vec3(379, 9, 799), vec3(400, 21, 835), "Bren Monument", MonumentSubject::Bren));
    // ret.InsertLast(MonumentTrigger(vec3(400, 9, 818), vec3(405, 21, 835), "Bren Monument", MonumentSubject::Bren));
    // ret.InsertLast(MonumentTrigger(vec3(400, 9, 799), vec3(420, 21, 818), "Jave Monument", MonumentSubject::Jave));
    // far from water
    ret.InsertLast(MonumentTrigger(vec3(380, 9, 818), vec3(405, 21, 838), "Bren Monument", MonumentSubject::Bren));
    // water side bren
    ret.InsertLast(MonumentTrigger(vec3(380, 9, 800), vec3(400, 21, 818), "Bren Monument", MonumentSubject::Bren));
    ret.InsertLast(MonumentTrigger(vec3(400, 9, 800), vec3(424, 21, 818), "Jave Monument", MonumentSubject::Jave));
    return ret;
}

GameTrigger@[]@ genSpecialTriggers() {
    GameTrigger@[] ret;
    ret.InsertLast(AntiCylinderTrigger(380, vec2(768, 768), vec2(169, 2000.0), "Geep Gip"));
    return ret;
}

GameTrigger@[]@ specialTriggers = genSpecialTriggers();
GameTrigger@[]@ voiceLineTriggers = generateVoiceLineTriggers();
GameTrigger@[]@ monumentTriggers = generateMonumentTriggers();

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
        @currTriggerHit = t;
        currTriggerName = t is null ? "" : t.name;
    }

    if (t is null) return;

    if (updateLast) {
        if (t.name != lastTriggerName) {
            lastTriggerName = t.name;
            OnNewTriggerHit(lastTriggerHit, t);
        }
        @lastTriggerHit = t;
    }
}

void OnLeaveTrigger(GameTrigger@ prevTrigger, GameTrigger@ newTrigger) {
    prevTrigger.OnLeftTrigger(newTrigger);
}

void OnNewTriggerHit(GameTrigger@ lastTriggerHit, GameTrigger@ newTrigger) {
    // Notify("Hit trigger: " + newTrigger.name);
    // AddTitleScreenAnimation(MainTitleScreenAnim(newTrigger.name, "test", null));
    // NotifyWarning("Added title screen anim");
    newTrigger.OnEnteredTrigger(lastTriggerHit);
}

















// DEBUG

bool m_debugDrawTriggers = false;

void DrawTriggersTab() {
    if (voiceLineTriggers is null || dd2TriggerTree is null) return;

    m_debugDrawTriggers = UI::Checkbox("(Debug) Draw Triggers", m_debugDrawTriggers);
    if (m_debugDrawTriggers && GetApp().GameScene !is null) {
        for (uint i = 0; i < voiceLineTriggers.Length; i++) {
            voiceLineTriggers[i].Debug_NvgDrawTrigger();
        }
        for (uint i = 0; i < monumentTriggers.Length; i++) {
            monumentTriggers[i].Debug_NvgDrawTrigger();
        }
        for (uint i = 0; i < specialTriggers.Length; i++) {
            specialTriggers[i].Debug_NvgDrawTrigger();
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
