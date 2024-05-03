/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
[Setting hidden]
bool S_PassthroughAllLogs = true;

enum LogLevel {
    ERROR,
    WARN,
    INFO,
    DEBUG,
    TRACE
}

string[] LogLevelNames = {
    "EROR",
    "WARN",
    "INFO",
    "DBUG",
    "TRCE"
};

string FormatTimestampMsLong(int64 timestamp) {
    return Time::FormatString("%Y-%m-%d %H:%M:%S", timestamp);
}

string FormatTimestampMsShort(int64 timestamp) {
    return Time::FormatString("%H:%M:%S", timestamp);
}

class LogMessage {
    string msg;
    LogLevel level;
    uint64 timestamp;
    string logLine;

    LogMessage() {}

    LogMessage(const string &in msg, LogLevel level) {
        this.msg = msg;
        this.level = level;
        this.timestamp = Time::Stamp;
        logLine = Time::FormatString("%Y-%m-%d %H:%M:%S", timestamp) + "["+LogLevelNames[int(level)]+"] - " + msg;
    }
}

LogMessage@[] logs = array<LogMessage@>();

uint GetNbLogMsgs() {
    return logs.Length;
}

void log_error(const string &in msg) {
    error(msg);
    // logs.InsertLast(LogMessage(msg, LogLevel::ERROR));
}

void log_warn(const string &in msg) {
    warn(msg);
    // logs.InsertLast(LogMessage(msg, LogLevel::WARN));
}

void log_info(const string &in msg, bool passthrough = true) {
    if (passthrough) print(msg);
    // logs.InsertLast(LogMessage(msg, LogLevel::INFO));
}

void log_debug(const string &in msg) {
    log_debug(msg, S_PassthroughAllLogs);
}

void log_debug(const string &in msg, bool passthrough) {
    if (passthrough) trace(msg);
    // logs.InsertLast(LogMessage(msg, LogLevel::DEBUG));
}

void log_trace(const string &in msg) {
    log_trace(msg, S_PassthroughAllLogs);
}

void log_trace(const string &in msg, bool passthrough) {
    if (passthrough) trace(msg);
    // logs.InsertLast(LogMessage(msg, LogLevel::TRACE));
}

int PausedLogsLen = -1;

// void DrawLogsTab() {
//     UI::PushFont(g_MonoFont);
//     int nbLogs = logs.Length;
//     if (PausedLogsLen > nbLogs) PausedLogsLen = -1;
//     UI::AlignTextToFramePadding();
//     UI::Text("Logs: " + nbLogs);
//     UI::SameLine();
//     if (PausedLogsLen >= 0) {
//         if (UI::Button("Resume")) {
//             PausedLogsLen = -1;
//         } else {
//             nbLogs = PausedLogsLen;
//         }
//     } else {
//         if (UI::Button("Pause Logs")) {
//             PausedLogsLen = nbLogs;
//         }
//     }
//     UI::SameLine();
//     if (UI::Button("Clear Logs")) {
//         logs.RemoveRange(0, logs.Length);
//         nbLogs = 0;
//     }
//     if (UI::BeginChild("logschild", vec2(), false, UI::WindowFlags::AlwaysVerticalScrollbar)) {
//         UI::ListClipper clip(nbLogs);
//         while (clip.Step()) {
//             for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
//                 auto @item = logs[nbLogs - i - 1];
//                 UI::PushID('log'+i);
//                 UI::PushStyleColor(UI::Col::Text, LogLevelColor(item.level));
//                 UI::Text(item.logLine);
//                 UI::PopStyleColor();
//                 UI::PopID();
//             }
//         }
//     }
//     UI::EndChild();
//     UI::PopFont();
// }

vec4 LogLevelColor(LogLevel level) {
    switch (level) {
        case LogLevel::ERROR: return vec4(1, 0.4, 0.3, 1);
        case LogLevel::WARN: return vec4(1, 1, 0.3, 1);
        case LogLevel::INFO: return vec4(1, 1, 1, 1);
        case LogLevel::DEBUG: return vec4(0.3, 1, 0.5, 1);
        case LogLevel::TRACE: return vec4(0.6, 0.6, 0.6, 1);
    }
    return vec4(1, 1, 1, 1);
}
