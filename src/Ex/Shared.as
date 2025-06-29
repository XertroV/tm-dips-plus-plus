// error is an empty string when success is true; extra is non-null only for TaskResponseJson
shared funcdef void DPP_TaskCallback(uint id, bool success, const string &in error, Json::Value@ extra);

namespace CustomVL {
    shared class IVoiceLineParams {
        bool isUrl;
        string pathOrUrl;
        string subtitles;
        string imagePathOrUrl;
        IVoiceLineParams(const string &in pathOrUrl, const string &in subtitles, const string &in imagePathOrUrl = "") {
            isUrl = pathOrUrl.StartsWith("https://") || pathOrUrl.StartsWith("http://");
            this.pathOrUrl = pathOrUrl;
            this.subtitles = subtitles;
            this.imagePathOrUrl = imagePathOrUrl;
        }
    }
}

namespace Tasks {
    shared interface IWaiter {
        void AwaitTask(int64 timeout_ms = -1);
        uint get_ReqId();
        bool IsDone();
        bool IsSuccess();
        string GetError();
        Json::Value@ GetExtra();
    }
}

// shared interface IAuxSpec {}

shared class UploadedAuxSpec_Base {
    string user_id; // WSID
    string name_id;
    Json::Value@ spec;
    uint hit_counter; // how many times this aux spec has been accessed
    int64 created_at; // Unix timestamp in milliseconds
    int64 updated_at; // Unix timestamp in milliseconds

    UploadedAuxSpec_Base(const string &in user_id, const string &in name_id, Json::Value@ spec, int64 hit_counter, int64 created_at, int64 updated_at) {
        this.user_id = user_id;
        this.name_id = name_id;
        @this.spec = spec;
        this.hit_counter = hit_counter;
        this.created_at = created_at;
        this.updated_at = updated_at;
    }
}






namespace JsonX {
    shared bool IsObject(const Json::Value@ j) {
        return j !is null && j.GetType() == Json::Type::Object;
    }
    shared bool IsArray(const Json::Value@ j) {
        return j !is null && j.GetType() == Json::Type::Array;
    }
    shared bool IsNumber(const Json::Value@ j) {
        return j !is null && j.GetType() == Json::Type::Number;
    }
    shared bool IsString(const Json::Value@ j) {
        return j !is null && j.GetType() == Json::Type::String;
    }
    shared bool IsBool(const Json::Value@ j) {
        return j !is null && j.GetType() == Json::Type::Boolean;
    }
    shared bool IsNull(const Json::Value@ j) {
        return j !is null && j.GetType() == Json::Type::Null;
    }
    shared bool IsUnknown(const Json::Value@ j) {
        return j !is null && j.GetType() == Json::Type::Unknown;
    }

    shared bool SafeGetUint(const Json::Value@ j, const string &in key, uint &out value) {
        if (!IsObject(j)) return false;
        if (!j.HasKey(key)) return false;
        auto j_inner = j[key];
        if (!IsNumber(j_inner)) return false;
        value = uint(j_inner);
        return true;
    }

    shared bool SafeGetInt(const Json::Value@ j, const string &in key, int &out value) {
        if (!IsObject(j)) return false;
        if (!j.HasKey(key)) return false;
        auto j_inner = j[key];
        if (!IsNumber(j_inner)) return false;
        value = int(j_inner);
        return true;
    }

    shared bool SafeGetInt64(const Json::Value@ j, const string &in key, int64 &out value) {
        if (!IsObject(j)) return false;
        if (!j.HasKey(key)) return false;
        auto j_inner = j[key];
        if (!IsNumber(j_inner)) return false;
        value = int64(j_inner);
        return true;
    }

    shared bool SafeGetFloat(const Json::Value@ j, const string &in key, float &out value) {
        if (!IsObject(j)) return false;
        if (!j.HasKey(key)) return false;
        auto j_inner = j[key];
        if (!IsNumber(j_inner)) return false;
        value = float(j_inner);
        return true;
    }

    shared bool SafeGetBool(const Json::Value@ j, const string &in key, bool &out value) {
        if (!IsObject(j)) return false;
        if (!j.HasKey(key)) return false;
        auto j_inner = j[key];
        if (!IsBool(j_inner)) return false;
        value = j_inner;
        return true;
    }

    shared bool SafeGetString(const Json::Value@ j, const string &in key, string &out value) {
        if (!IsObject(j)) return false;
        if (!j.HasKey(key)) return false;
        auto j_inner = j[key];
        if (!IsString(j_inner)) return false;
        value = j_inner;
        return true;
    }

    shared Json::Value@ SafeGetJson(Json::Value@ j, const string &in key) {
        if (!IsObject(j)) return null;
        if (!j.HasKey(key)) return null;
        auto j_inner = j[key];
        if (IsNull(j_inner)) return null;
        return j_inner;
    }
}
