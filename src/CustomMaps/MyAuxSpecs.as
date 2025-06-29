namespace MyAuxSpecs {
    Tasks::IWaiter@ List() {
        auto w = Tasks::GetNewTaskWaiter();
        PushMessage(ListCustomMapAuxSpecsMsg(w.ReqId));
        return w;
    }
    Tasks::IWaiter@ List_Async() {
        auto w = List();
        w.AwaitTask();
        return w;
    }

    Tasks::IWaiter@ Delete(const string &in name_id) {
        auto w = Tasks::GetNewTaskWaiter();
        PushMessage(DeleteCustomMapAuxSpecMsg(w.ReqId, name_id));
        return w;
    }
    Tasks::IWaiter@ Delete_Async(const string &in name_id) {
        auto w = Delete(name_id);
        w.AwaitTask();
        return w;
    }

    // submit/update a custom map aux spec
    Tasks::IWaiter@ Report(const string &in name_id, Json::Value@ spec) {
        auto w = Tasks::GetNewTaskWaiter();
        PushMessage(ReportCustomMapAuxSpecMsg(w.ReqId, name_id, spec));
        return w;
    }
    // submit/update a custom map aux spec
    Tasks::IWaiter@ Report_Async(const string &in name_id, Json::Value@ spec) {
        auto w = Report(name_id, spec);
        w.AwaitTask();
        return w;
    }

    UploadedAuxSpec_Base@ JsonToAuxSpec(Json::Value@ j) {
        if (!JsonX::IsObject(j)) return null;
        string user_id;
        string name_id;
        Json::Value@ spec;
        int64 hit_counter = 0;
        int64 created_at = 0;
        int64 updated_at = 0;
        JsonX::SafeGetString(j, "user_id", user_id);
        JsonX::SafeGetString(j, "name_id", name_id);
        @spec = JsonX::SafeGetJson(j, "spec");
        JsonX::SafeGetInt64(j, "hit_counter", hit_counter);
        JsonX::SafeGetInt64(j, "created_at", created_at);
        JsonX::SafeGetInt64(j, "updated_at", updated_at);
        return UploadedAuxSpec_Base(user_id, name_id, spec, hit_counter, created_at, updated_at);
    }

    UploadedAuxSpec_Base@[]@ JsonArrToAuxSpecs(Json::Value@ j) {
        if (!JsonX::IsArray(j)) return null;
        UploadedAuxSpec_Base@[]@ arr = {};
        for (uint i = 0; i < j.Length; i++) {
            UploadedAuxSpec_Base@ spec = JsonToAuxSpec(j[i]);
            if (spec !is null) {
                arr.InsertLast(spec);
            } else {
                warn("MyAuxSpecs::JsonArrToAuxSpecs: Failed to parse spec at index " + i);
            }
        }
        return arr;
    }
}
