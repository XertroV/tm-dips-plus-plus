class Collection {
    CollectionItem@[] items;

    void AddItem(CollectionItem@ item) {
        items.InsertLast(item);
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
}
