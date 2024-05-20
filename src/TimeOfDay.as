// namespace SetTimeOfDay {
//     uint16 O_CHMSLIGHT_LOCATION2 = 0;
//     void SetSunAngle(float azumith, float elevation) {
//         auto gs = GetApp().GameScene;
//         if (gs is null) return;
//         CScene@ hs;
//         if ((@hs = gs.HackScene) is null) return;
//         if (hs.Lights.Length == 0) return;
//         // only 3 observed on server
//         if (hs.Lights.Length > 10) return;

//         // from tau to pi (left to right on screen); start 3.485, to 6.2
//         // elevation: PI/2 is noon, 3PI/2 is midnight (well sun under map); PI = horizon behind tower
//         mat4 lightingMat4 = mat4::Rotate(azumith, vec3(0, 1, 0)) * mat4::Rotate(elevation, vec3(0, 0, 1));
//         iso4 lightingMat = iso4(lightingMat4);

//         CHmsLight@ chl;
//         CSceneLight@ csl;
//         for (int i = 0; i < gs.HackScene.Lights.Length; i++) {
//             if ((@csl = hs.Lights[i]) is null) continue;
//             if ((@chl = cast<CHmsLight>(csl.HmsPoc)) is null) continue;
//             // static = 0; dynamic = 1
//             if (int(chl.UpdateType) > 0) continue;
//             // found sun
//             if (O_CHMSLIGHT_LOCATION2 == 0) {
//                 O_CHMSLIGHT_LOCATION2 = GetOffset(chl, "Location") + 0x30;
//             }
//             if (O_CHMSLIGHT_LOCATION2 < 0x100) {
//                 Dev::SetOffset(chl, O_CHMSLIGHT_LOCATION2, lightingMat);
//             }
//         }
//     }

//     iso4 GetSunIso4() {
//         auto gs = GetApp().GameScene;
//         if (gs is null) return iso4(mat4::Identity());
//         CScene@ hs;
//         if ((@hs = gs.HackScene) is null) return iso4(mat4::Identity());
//         if (hs.Lights.Length == 0) return iso4(mat4::Identity());
//         // only 3 observed on server
//         if (hs.Lights.Length > 10) return iso4(mat4::Identity());

//         CHmsLight@ chl;
//         CSceneLight@ csl;
//         for (int i = 0; i < gs.HackScene.Lights.Length; i++) {
//             if ((@csl = hs.Lights[i]) is null) continue;
//             if ((@chl = cast<CHmsLight>(csl.HmsPoc)) is null) continue;
//             // static = 0; dynamic = 1
//             if (int(chl.UpdateType) > 0) continue;
//             // found sun
//             if (O_CHMSLIGHT_LOCATION2 == 0) {
//                 O_CHMSLIGHT_LOCATION2 = GetOffset(chl, "Location") + 0x30;
//             }
//             if (O_CHMSLIGHT_LOCATION2 < 0x100) {
//                 return Dev::GetOffsetIso4(chl, O_CHMSLIGHT_LOCATION2);
//             }
//         }
//         return iso4(mat4::Identity());
//     }
// }
