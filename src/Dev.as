uint16 _CSmPlayer_NetPacketsBuf_Offset = 0;

uint get_O_CSmPlayer_NetPacketsBuf() {
    if (_CSmPlayer_NetPacketsBuf_Offset == 0) {
        auto TmGameVersion = GetApp().SystemPlatform.ExeVersion;
        if (TmGameVersion > "2024-03-19_14_47") {
            _CSmPlayer_NetPacketsBuf_Offset = 0x140;
        } else {
            _CSmPlayer_NetPacketsBuf_Offset = 0x130;
        }
        _CSmPlayer_NetPacketsBuf_Offset += O_CSmPlayer_Score;
    }
    return _CSmPlayer_NetPacketsBuf_Offset;
}

uint16 _CSmPlayer_NetPacketsUpdatedBuf = 0;
uint get_O_CSmPlayer_NetPacketsUpdatedBuf() {
    if (_CSmPlayer_NetPacketsUpdatedBuf == 0) {
        _CSmPlayer_NetPacketsUpdatedBuf =  O_CSmPlayer_NetPacketsBuf + SZ_CSmPlayer_NetPacketsBufStruct * LEN_CSmPlayer_NetPacketsBuf;
    }
    return _CSmPlayer_NetPacketsUpdatedBuf;
}

uint16 _CSmPlayer_NetPacketsBuf_NextIx = 0;
uint get_O_CSmPlayer_NetPacketsBuf_NextIx() {
    if (_CSmPlayer_NetPacketsBuf_NextIx == 0) {
        _CSmPlayer_NetPacketsBuf_NextIx =  O_CSmPlayer_NetPacketsUpdatedBuf + SZ_CSmPlayer_NetPacketsUpdatedBufEl * LEN_CSmPlayer_NetPacketsBuf;
    }
    return _CSmPlayer_NetPacketsBuf_NextIx;
}

const uint16 O_CSmPlayer_Score = GetOffset("CSmPlayer", "Score");
// 0x1160 -> 1180 -> 1190 (apr)
// use Get_CSmPlayer_NetPacketsBuf_Offset instead.
// const uint16 O_CSmPlayer_NetPacketsBuf = O_CSmPlayer_Score + 0x130 + 0x10;
const uint16 SZ_CSmPlayer_NetPacketsBufStruct = 0xD8;
const uint16 LEN_CSmPlayer_NetPacketsBuf = 201;
const uint16 SZ_CSmPlayer_NetPacketsUpdatedBufEl = 0x4;
// BAF8 -> BB18
// const uint16 O_CSmPlayer_NetPacketsUpdatedBuf = O_CSmPlayer_NetPacketsBuf + SZ_CSmPlayer_NetPacketsBufStruct * LEN_CSmPlayer_NetPacketsBuf;
// 0xBE1c -> 0xbe3C
// const uint16 O_CSmPlayer_NetPacketsBuf_NextIx = O_CSmPlayer_NetPacketsUpdatedBuf + SZ_CSmPlayer_NetPacketsUpdatedBufEl * LEN_CSmPlayer_NetPacketsBuf;


const uint16 O_PlayerNetStruct_Quat = 0x4;
const uint16 O_PlayerNetStruct_Pos = 0x14;
const uint16 O_PlayerNetStruct_Vel = 0x20;
const uint16 O_PlayerNetStruct_Flags = 0x38;
const uint16 O_PlayerNetStruct_RPM = 0x3C;
const uint16 O_PlayerNetStruct_Steering = 0x40;
const uint16 O_PlayerNetStruct_Gas = 0x44;
const uint16 O_PlayerNetStruct_WheelYaw = 0x48;
const uint16 O_PlayerNetStruct_DiscontinuityCount = 0x60;
const uint16 O_PlayerNetStruct_Wheels = 0x68;
const uint16 O_PlayerNetStruct_WheelOnGround = O_PlayerNetStruct_Wheels + 0x18;
const uint16 SZ_PlayerNetStruct_Wheel = 0x1C;


const uint16 O_VehicleState_DiscontCount = GetOffset("CSceneVehicleVisState", "DiscontinuityCount");
const uint16 O_VehicleState_Frozen = GetOffset("CSceneVehicleVisState", "RaceStartTime") + 0x8;

quat Dev_GetOffsetQuat(CMwNod@ nod, uint16 offset) {
    auto v = Dev::GetOffsetVec4(nod, offset);
    return quat(v.x, v.y, v.z, v.w);
}
