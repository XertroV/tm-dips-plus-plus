namespace Tasks {
    void DrawDebugMenuItem() {
        UI::MenuItem("# Task CBs Waiting:", "" + taskIds.Length, false, false);
    }
    void DrawDebugText() {
        UI::Text("Task Callbacks Waiting: " + taskIds.Length);
    }

    void HandleTaskResponse(Json::Value@ msg) {
        // {id, success, error}
        uint id = 0;
        bool success = false;
        string error = "";
        JsonX::SafeGetUint(msg, "id", id);
        JsonX::SafeGetBool(msg, "success", success);
        JsonX::SafeGetString(msg, "error", error);
        _RunTaskCallback(id, success, error);
    }

    void HandleTaskResponseJson(Json::Value@ msg) {
        // implies success
        uint id = 0;
        JsonX::SafeGetUint(msg, "id", id);
        Json::Value@ data = JsonX::SafeGetJson(msg, "data");
        _RunTaskCallback(id, true, "", data);
    }

    uint GetTaskId(DPP_TaskCallback@ cb) {
        if (cb is null) return INVALID_MWID;
        uint id = _GetNextId();
        _RegisterTaskCallback(id, cb);
        return id;
    }

    uint _lastId = 0;
    uint _GetNextId() {
        // uint(Math::Rand(-2147483648, 2147483647))
        return ++_lastId;
    }

    uint[] taskIds;
    DPP_TaskCallback@[] taskCallbacks;
    void _RegisterTaskCallback(uint id, DPP_TaskCallback@ cb) {
        if (taskIds.Length != taskCallbacks.Length) {
            throw("taskIds and taskCallbacks must have the same length");
        }
        // ignore null cbs or if id == -1
        if (cb is null || id == INVALID_MWID) return;
        if (taskIds.Length == 0) {
            taskIds.Reserve(8); taskCallbacks.Reserve(8);
        }
        taskIds.InsertLast(id); taskCallbacks.InsertLast(cb);
    }

    void _RunTaskCallback(uint id, bool success, const string &in error, Json::Value@ extra = null) {
        // extra is non null only for TaskResponseJson
        int ix = -1;
        while ((ix = taskIds.Find(id)) >= 0) {
            if (ix < int(taskCallbacks.Length)) {
                DPP_TaskCallback@ cb = taskCallbacks[ix];
                if (cb !is null) {
                    cb(id, success, error, extra);
                }
            }
            taskIds.RemoveAt(ix);
            taskCallbacks.RemoveAt(ix);
        }
    }
}
