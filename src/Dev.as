// 0x1160
const uint16 O_CSmPlayer_NetPacketsBuf = GetOffset("CSmPlayer", "Score") + 0x118;
const uint16 SZ_CSmPlayer_NetPacketsBufStruct = 0xD8;
const uint16 LEN_CSmPlayer_NetPacketsBuf = 201;
const uint16 SZ_CSmPlayer_NetPacketsUpdatedBufEl = 0x4;
// BAF8
const uint16 O_CSmPlayer_NetPacketsUpdatedBuf = O_CSmPlayer_NetPacketsBuf + SZ_CSmPlayer_NetPacketsBufStruct * LEN_CSmPlayer_NetPacketsBuf;
// 0xBE1C
const uint16 O_CSmPlayer_NetPacketsBuf_NextIx = O_CSmPlayer_NetPacketsUpdatedBuf + SZ_CSmPlayer_NetPacketsUpdatedBufEl * LEN_CSmPlayer_NetPacketsBuf;


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
