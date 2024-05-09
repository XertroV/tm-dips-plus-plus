// #if DEPENDENCY_MLHOOK
// const bool MAGIC_SPEC_ENABLED = true;

// namespace Spectate {
//     void Unload() {
//         MLHook::UnregisterMLHooksAndRemoveInjectedML();
//     }

//     void Load() {
//         MLHook::RegisterPlaygroundMLExecutionPointCallback(onMLExec);
//     }

//     uint currentlySpectating = 0;
//     void onMLExec(ref@ _x) {
//         if (!g_Active) return;
//     }
// }

// #else
// const bool MAGIC_SPEC_ENABLED = false;
// #endif
