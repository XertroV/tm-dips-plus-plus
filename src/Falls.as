/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
enum MapFloor {
    FloorGang = 0,
    Floor1 = 1,
    Floor2 = 2,
    Floor3 = 3,
    Floor4 = 4,
    Floor5 = 5,
    Floor6 = 6,
    Floor7 = 7,
    Floor8 = 8,
    Floor9 = 9,
    Floor10 = 10,
    Floor11 = 11,
    Floor12 = 12,
    Floor13 = 13,
    Floor14 = 14,
    Floor15 = 15,
    Floor16 = 16,
    Floor17 = 17,
    Finish = 18,
}

const string[] F13_BOUNCE_LINES = {
    "Good Job!",
    "Nice Bounce!",
    "#NotBait",
    "#NotBait",
    "#NotBait",
    "Wicked!",
    "Amazing!",
    "You're a pro!",
    "You're doing great!",
    "Keep it up!",
    "Impressive!",
    "Exciting Maneuver!"
    "plaxxdd"
};

const string ChooseF13BounceLine() {
    return F13_BOUNCE_LINES[Math::Rand(0, F13_BOUNCE_LINES.Length)];
}

const float MIN_FALL_HEIGHT_FOR_STATS = 31.0;

class FallTracker {
    float startHeight;
    float fallDist;
    float startFlyingHeight;
    MapFloor startFloor;
    MapFloor currentFloor;
    float currentHeight;
    uint startTime;
    uint endTime;
    vec3 endPos;
    float startSpeed;
    vec3 startVel;
    // implies player is local
    bool recordStats;
    bool f13DropStartCheck;
    bool f13DropEndCheck;

    FallTracker(float initHeight, float startFlyingHeight, PlayerState@ player) {
        startHeight = initHeight;
        startFloor = HeightToFloor(initHeight);
        startTime = Time::Now;
        recordStats = player.isLocal;
        this.startFlyingHeight = startFlyingHeight;
        SetSpeed(player);
        if (recordStats) {
            Stats::LogJumpStart();
            Stats::LogFallStart();
            f13DropStartCheck = f13_dropStart.PointInside(player.pos);
            if (f13DropStartCheck) Dev_Notify("F13 drop start check passed");
            PushMessage(ReportFallStartMsg(uint8(startFloor), player.pos, player.vel, startTime));
        }
    }

    // gets called instead of update before fall tracker destroyed
    void OnPlayerRespawn(PlayerState@ player) {
        if (currentHeight > 50.) {
            // fall gang
            currentHeight = 10.;
            currentFloor = MapFloor::FloorGang;
            fallDist = startHeight - currentHeight;
        }
    }

    void OnContinueFall(PlayerState@ player) {
        SetSpeed(player);
    }

    void SetSpeed(PlayerState@ p) {
        startSpeed = p.vel.Length() * 3.6; // m/s to km/h
        startVel = p.vel;
    }

    ~FallTracker() {
        if (recordStats) {
            // todo: only record stats permanently if the fall was greater than the min limit
            if (IsFallPastMinFall()) {
                Stats::AddFloorsFallen(Math::Max(0, FloorsFallen()));
                Stats::AddDistanceFallen(HeightFallenSafe());
            } else {
                Stats::LogFallEndedLessThanMin();
            }
            PushMessage(ReportFallEndMsg(uint8(currentFloor), endPos, endTime));
        }
    }

    bool IsFallPastMinFall() {
        return Math::Max(0.0, HeightFallenFromFlying()) >= MIN_FALL_HEIGHT_FOR_STATS
            && !(f13DropStartCheck && f13DropEndCheck)
            && Time::Now - startTime > 20;
    }

    bool IsFallOver100m() {
        return Math::Max(0.0, HeightFallenFromFlying()) >= 100.0;
    }

    // can be removed as a fall immediately
    bool ShouldIgnoreFall() {
        return HeightFallenFromFlying() < 4. ||
            (f13DropStartCheck && f13DropEndCheck);
    }

    void Update(float height) {
        currentHeight = height;
        currentFloor = HeightToFloor(height);
        fallDist = startHeight - currentHeight;
    }

    int FloorsFallen() {
        return Math::Max(0, int(startFloor) - int(currentFloor));
    }

    // can be < 0
    float HeightFallen() {
        return startHeight - currentHeight;
    }

    // always > 0
    float HeightFallenSafe() {
        return Math::Max(0.0, startHeight - currentHeight);
    }

    float HeightFallenFromFlying() {
        return startFlyingHeight - currentHeight;
    }

    void OnEndFall(PlayerState@ player) {
        endTime = Time::Now;
        endPos = player.pos;
        if (f13DropStartCheck && !f13DropEndCheck) {
            f13DropEndCheck = f13_dropEnd.PointInside(player.pos);
            if (f13DropEndCheck) {
                // Dev_Notify("F13 drop end check passed");
                EmitStatusAnimation(RainbowStaticStatusMsg(ChooseF13BounceLine()));
            }
        }
    }

    // inclusive, so more than 1 floor will be true as soon as you hit the next floor, and 0 floors will be true if you're on the same floor
    bool HasMoreThanXFloors(int x) {
        return FloorsFallen() >= x;
    }

    bool HasExpired() {
        return endTime + AFTER_FALL_MINIMAP_SHOW_DURATION < Time::Now;
    }

    string ToString() {
        return "Fell " + Text::Format("%.0f m / ", fallDist) + FloorsFallen() + " floors";
    }
}



class ClimbTracker {
    bool recordStats;
    int floorReached = 0;
    float maxH = 0;

    ClimbTracker(PlayerState@ player) {
        recordStats = player.isLocal;
    }

    void Reset() {
        floorReached = 0;
        maxH = 0;
    }

    void Update(float height) {
        if (recordStats && height > maxH) {
            maxH = height;
            auto f = HeightToFloor(height);
            if (f > floorReached) {
                floorReached = int(f);
                Stats::LogFloorReached(f);
            }
        }
    }
}



MapFloor HeightToFloor(float h) {
    return HeightToFloorBinarySearch(h);
    // if (h < DD2_FLOOR_HEIGHTS[1]) return MapFloor::FloorGang;
    // for (int i = 1; i < 18; i++) {
    //     if (h < DD2_FLOOR_HEIGHTS[i+1]) return MapFloor(i);
    // }
    // return MapFloor::Finish;
}

MapFloor HeightToFloorBinarySearch(float h) {
    const float[]@ heights = GetFloorHeights();
    int l = 0;
    int r = heights.Length - 1;
    while (l < r) {
        int m = (l + r) / 2;
        if (h < heights[m]) {
            r = m;

        } else {
            l = m + 1;
        }
    }
    return MapFloor(Math::Max(0, l - 1));
}


#if DEV


void test_HeightToFloorBinSearch() {
    for (int i = 0; i < 18; i++) {
        assert_eq(HeightToFloor(DD2_FLOOR_HEIGHTS[i]), MapFloor(i), "HeightToFloorBinSearch failed at " + i + " " + DD2_FLOOR_HEIGHTS[i]);
    }
    for (int i = 0; i < 18; i++) {
        assert_eq(HeightToFloor(DD2_FLOOR_HEIGHTS[i] - 0.01), MapFloor(Math::Max(0, i - 1)), "HeightToFloorBinSearch failed under " + i + " " + DD2_FLOOR_HEIGHTS[i]);
    }
    for (int i = 0; i < 18; i++) {
        assert_eq(HeightToFloor(DD2_FLOOR_HEIGHTS[i] + 0.01), MapFloor(i), "HeightToFloorBinSearch failed over " + i + " " + DD2_FLOOR_HEIGHTS[i]);
    }
    assert_eq(HeightToFloor(3000), MapFloor::Finish, "HeightToFloorBinSearch failed over finish");
    assert_eq(HeightToFloor(-1000), MapFloor::FloorGang, "HeightToFloorBinSearch failed under ground");
    print("\\$0f0HeightToFloorBinSearch done");
    return;
}

Meta::PluginCoroutine@ test_result = startnew(test_HeightToFloorBinSearch);

void assert_eq(MapFloor a, MapFloor b, const string &in msg) {
    if (a != b) {
        warn("assert_eq failed: " + tostring(a) + " != " + tostring(b) + " " + msg);
    }
}
#endif
