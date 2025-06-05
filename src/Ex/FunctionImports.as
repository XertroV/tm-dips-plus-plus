namespace MapCustomInfo {
    import bool CheckMinClientVersion(const string &in value) from "DipsPP";
}

import Json::Value@ Vec3ToJson(const vec3 &in v) from "DipsPP";
import vec3 JsonToVec3(const Json::Value@ j) from "DipsPP";

namespace CustomVL {
    // Blocks while files download
    import void StartTestVoiceLine_Async(IVoiceLineParams@ params) from "DipsPP";
    // Does not block
    import Meta::PluginCoroutine@ StartTestVoiceLine(IVoiceLineParams@ params) from "DipsPP";
}
