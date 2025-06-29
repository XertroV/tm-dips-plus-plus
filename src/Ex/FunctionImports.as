namespace MapCustomInfo {
    import bool CheckMinClientVersion(const string &in value) from "DipsPP";
}

namespace MyAuxSpecs {
    import Tasks::IWaiter@ List() from "DipsPP";
    import Tasks::IWaiter@ List_Async() from "DipsPP";
    import Tasks::IWaiter@ Delete(const string &in name_id) from "DipsPP";
    import Tasks::IWaiter@ Delete_Async(const string &in name_id) from "DipsPP";
    // submit/update a custom map aux spec
    import Tasks::IWaiter@ Report(const string &in name_id, Json::Value@ spec) from "DipsPP";
    // submit/update a custom map aux spec
    import Tasks::IWaiter@ Report_Async(const string &in name_id, Json::Value@ spec) from "DipsPP";

    import UploadedAuxSpec_Base@ JsonToAuxSpec(Json::Value@ j) from "DipsPP";
    import UploadedAuxSpec_Base@[]@ JsonArrToAuxSpecs(Json::Value@ j) from "DipsPP";
}

import Json::Value@ Vec3ToJson(const vec3 &in v) from "DipsPP";
import vec3 JsonToVec3(const Json::Value@ j) from "DipsPP";

namespace CustomVL {
    // Blocks while files download
    import void StartTestVoiceLine_Async(IVoiceLineParams@ params) from "DipsPP";
    // Does not block
    import awaitable@ StartTestVoiceLine(IVoiceLineParams@ params) from "DipsPP";
}

namespace DipsPPConnection {
    import bool IsConnected() from "DipsPP";
}

namespace Tasks {
    import IWaiter@ GetNewTaskWaiter() from "DipsPP";
}
