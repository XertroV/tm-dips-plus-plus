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
