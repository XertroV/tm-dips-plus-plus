/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
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

uint[] JsonToUintArray(const Json::Value@ j) {
    uint[] arr;
    if (j.GetType() != Json::Type::Array) {
        warn("non-array value passed to JsonToUIntArray");
        return arr;
    }
    for (uint i = 0; i < j.Length; i++) {
        try {
            arr.InsertLast(j[i]);
        } catch {
            warn("non-uint value in JsonToUIntArray: " + getExceptionInfo());
            arr.InsertLast(0);
        }
    }
    return arr;
}

bool[] JsonToBoolArray(const Json::Value@ j) {
    bool[] arr;
    if (j.GetType() != Json::Type::Array) {
        warn("non-array value passed to JsonToBoolArray");
        return arr;
    }
    for (uint i = 0; i < j.Length; i++) {
        try {
            arr.InsertLast(j[i]);
        } catch {
            warn("non-bool value in JsonToBoolArray: " + getExceptionInfo());
            arr.InsertLast(false);
        }
    }
    return arr;
}





int JGetInt(const Json::Value@ j, const string &in key, int _default = 0) {
    return j.Get(key, _default);
}

void IncrJsonIntCounter(Json::Value@ j, const string &in key) {
    bool hasKey = j.HasKey(key);
    if (!hasKey) {
        j[key] = 1;
        return;
    }
    if (j[key].GetType() != Json::Type::Number) {
        warn("json value is not a number: " + Json::Write(j[key]));
        return;
    }

    j[key] = int(j[key]) + 1;
}

void CopyJsonValuesIfGreater(Json::Value@ from, Json::Value@ to) {
    if (from.GetType() != Json::Type::Object) {
        warn("json 'from' value is not an object");
    }
    if (to.GetType() != Json::Type::Object) {
        warn("json 'to' value is not an object");
    }
    auto @keys = from.GetKeys();
    uint nb = keys.Length;
    Json::Value@ fv;
    Json::Value@ tv;
    for (uint i = 0; i < nb; i++) {
        string key = keys[i];
        if (to.HasKey(key)) {
            @fv = from[key];
            @tv = to[key];
            if (fv.GetType() == Json::Type::Number && to[key].GetType() == Json::Type::Number) {
                if (float(fv) > float(tv)) {
                    to[key] = fv;
                }
            } else if (fv.GetType() != Json::Type::Null) {
                to[key] = from[key];
            }
        } else {
            to[key] = from[key];
        }
    }
}
