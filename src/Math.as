
//
mat3 DirUpLeftToMat(const vec3 &in dir, const vec3 &in up, const vec3 &in left) {
    return mat3(left, up, dir);
}

bool Vec3Eq(const vec3 &in a, const vec3 &in b) {
    return a.x == b.x && a.y == b.y && a.z == b.z;
}

vec3 Nat3ToVec3(const nat3 &in n) {
    return vec3(n.x, n.y, n.z);
}
