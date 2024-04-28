class Collection {
    CollectionItem@[] items;
    CollectionItem@[] uncollected;

    void AddItem(CollectionItem@ item) {
        items.InsertLast(item);
        if (!item.collected) {
            uncollected.InsertLast(item);
        } else {
            warn("duplicate added: " + item.name);
        }
    }

    CollectionItem@ SelectOne() {
        if (items.Length == 0) {
            return null;
        }
        return items[Math::Rand(0, items.Length)];
    }

    CollectionItem@ SelectOneUncollected() {
        UpdateUncollected();
        if (uncollected.Length == 0) {
            return null;
        }
        return uncollected[Math::Rand(0, uncollected.Length)];
    }

    void UpdateUncollected() {
        uncollected = {};
        for (uint i = 0; i < items.Length; i++) {
            if (!items[i].collected) {
                uncollected.InsertLast(items[i]);
            }
        }
    }
}

class CollectionItem {
    string name;
    // whether to automatically collect this when a trigger has been met
    bool autocollect;
    bool collected;
    uint64 collectedAt;

    CollectionItem(const string &in name, bool autocollect) {
        this.name = name;
        this.autocollect = autocollect;
    }

    CollectionItem(Json::Value@ spec) {
        FromSpecJson(spec);
    }

    // this should collect it at some point
    void PlayItem(bool collect = true) { throw("Not implemented"); }

    void DrawDebug() { throw("Not implemented"); }

    // overload me
    void LogCollected() {}

    void CollectSoonAsync(uint64 sleepTime) {
        if (!collected) {
            collectedAt = Time::Stamp;
            collected = true;
            sleep(sleepTime);
            EmitCollected(this);
        }
    }

    void CollectSoonTrigger(uint64 sleepTime) {
        startnew(CoroutineFuncUserdataUint64(CollectSoonAsync), sleepTime);
    }

    Json::Value@ ToSpecJson() {
        Json::Value@ spec = Json::Object();
        ToSpecJsonInner(spec);
        return spec;
    }

    protected void ToSpecJsonInner(Json::Value@ j) {
        j["name"] = name;
        j["autocollect"] = autocollect;
    }

    protected void ToUserJsonInner(Json::Value@ j) {
        j["collected"] = collected;
        j["collectedAt"] = collectedAt;
    }

    Json::Value@ ToUserJson() {
        Json::Value@ data = Json::Object();
        ToUserJsonInner(data);
        return data;
    }

    void FromUserJson(Json::Value@ data) {
        collected = data["collected"];
        collectedAt = data["collectedAt"];
    }

    void FromSpecJson(Json::Value@ spec) {
        name = spec["name"];
        autocollect = spec["autocollect"];
    }
}




void EmitCollected(CollectionItem@ item) {
    print("Collected " + item.name);
    item.LogCollected();
}
