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
