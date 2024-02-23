mat3 DirUpLeftToMat(const vec3 &in dir, const vec3 &in up, const vec3 &in left) {
    return mat3(left, up, dir);
}
