namespace MapCustomInfo {
    import bool CheckMinClientVersion(const string &in value) from "DipsPP";
}

import Json::Value@ Vec3ToJson(const vec3 &in v) from "DipsPP";
import vec3 JsonToVec3(const Json::Value@ j) from "DipsPP";
