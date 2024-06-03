// const string LS_ENDPOINT = "https://dips-plus-plus.xk.io/logstream";

// class LogStream {
//     string[] queue;
//     uint sentGood = 0;
//     uint sentFail = 0;

//     LogStream() {
//         startnew(CoroutineFunc(SendLoop));
//     }

//     void SendLoop() {
//         awaitany({
//             TimeoutCoro(10000),
//             startnew(AwaitAuthToken)
//         });
//         while (true) {
//             if (queue.Length > 0) {
//                 startnew(CoroutineFuncUserdataString(SendLogs), Json::Write(queue.ToJson()));
//                 queue.RemoveRange(0, queue.Length);
//             }
//             yield();

//         }
//     }

//     void SendLogs(const string &in data) {
//         Net::HttpRequest@ req = Net::HttpRequest();
//         req.Headers["Authorization"] = g_opAuthToken;
//         req.Headers["Content-Type"] = "application/json";
//         req.Body = data;
//         req.Method = Net::HttpMethod::Post;
//         req.Url = LS_ENDPOINT;
//         req.Start();
//         yield();
//         while (!req.Finished()) {
//             yield();
//         }
//         if (req.ResponseCode() != 200) {
//             print("Failed to send logs: " + req.ResponseCode());
//             sentFail++;
//         } else {
//             sentGood++;
//         }
//     }
// }

// LogStream@ g_LogStream = LogStream();

// namespace Log {
//     void info (const string &in msg) {
//         print(msg);

//     }
// }






// Meta::PluginCoroutine@ TimeoutCoro(uint ms) {
//     return startnew(CoroutineFuncUserdataUint64(WaitSleep), ms);
// }

// void WaitSleep(uint64 ms) {
//     sleep_fix(ms);
// }
