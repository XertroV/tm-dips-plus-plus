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
    Finish = 17,
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
    // implies player is local
    bool recordStats;

    FallTracker(float initHeight, float startFlyingHeight, PlayerState@ player) {
        startHeight = initHeight;
        startFloor = HeightToFloor(initHeight);
        startTime = Time::Now;
        recordStats = player.isLocal;
        this.startFlyingHeight = startFlyingHeight;
        if (recordStats) {
            Stats::LogFallStart();
        }
    }

    ~FallTracker() {
        if (recordStats) {
            // todo: only record stats permanently if the fall was greater than the min limit
            auto fd = HeightFallenSafe();
            if (Math::Abs(fd) >= MIN_FALL_HEIGHT_FOR_STATS) {
                Stats::AddFloorsFallen(Math::Max(0, FloorsFallen()));
                Stats::AddDistanceFallen(fd);
            } else {
                Stats::LogFallEndedLessThanMin();
            }
        }
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

    void OnEndFall() {
        endTime = Time::Now;
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

MapFloor HeightToFloor(float h) {
    return HeightToFloorBinarySearch(h);
    if (h < DD2_FLOOR_HEIGHTS[1]) return MapFloor::FloorGang;
    for (int i = 1; i < 17; i++) {
        if (h < DD2_FLOOR_HEIGHTS[i+1]) return MapFloor(i);
    }
    return MapFloor::Finish;
}

MapFloor HeightToFloorBinarySearch(float h) {
    int l = 0;
    int r = 18;
    while (l < r) {
        int m = (l + r) / 2;
        if (h < DD2_FLOOR_HEIGHTS[m]) {
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
