Json::Value@ Nat2ToJson(const nat2 &in v) {
    auto @j = Json::Array();
    j.Add(v.x);
    j.Add(v.y);
    return j;
}

Json::Value@ Vec3ToJson(const vec3 &in v) {
    auto @j = Json::Array();
    j.Add(v.x);
    j.Add(v.y);
    j.Add(v.z);
    return j;
}

Json::Value@ QuatToJson(const quat &in q) {
    auto @j = Json::Array();
    j.Add(q.x);
    j.Add(q.y);
    j.Add(q.z);
    j.Add(q.w);
    return j;
}

// [[f32; 3]; 4]
Json::Value@ Iso4ToJson(const iso4 &in iso) {
    auto @j = Json::Array();
    auto @x = Json::Array();
    x.Add(iso.xx);
    x.Add(iso.xy);
    x.Add(iso.xz);
    j.Add(x);
    auto @y = Json::Array();
    y.Add(iso.yx);
    y.Add(iso.yy);
    y.Add(iso.yz);
    j.Add(y);
    auto @z = Json::Array();
    z.Add(iso.zx);
    z.Add(iso.zy);
    z.Add(iso.zz);
    j.Add(z);
    auto @t = Json::Array();
    t.Add(iso.tx);
    t.Add(iso.ty);
    t.Add(iso.tz);
    j.Add(t);
    return j;
}
