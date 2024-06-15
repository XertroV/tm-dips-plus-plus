/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/

const string COLLECTION_FILE = "Collection.json";

class Collection {
    CollectionItem@[] items;
    CollectionItem@[] uncollected;
    dictionary itemLookup;

    void AddItem(CollectionItem@ item) {
        items.InsertLast(item);
        @itemLookup[item.name] = item;
        if (!item.collected) {
            uncollected.InsertLast(item);
        } else {
            warn("duplicate added: " + item.name);
        }
    }

    void RestoreFromSaved() {
        // ! todo
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
    string _blankedName;
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

    string get_BlankedName() {
        if (_blankedName == "") {
            _blankedName = name;
            for (uint i = 0; i < _blankedName.Length; i++) {
                if (_blankedName[i] != 0x20) {
                    _blankedName[i] = 0x3F; // Math::Rand(0x21, 0x41);
                }
            }
            _blankedName = "\\$999" + _blankedName;
        }
        return _blankedName;
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
            EmitCollected(this);
            sleep(sleepTime);
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
        j["name"] = name;
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
