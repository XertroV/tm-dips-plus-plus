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
