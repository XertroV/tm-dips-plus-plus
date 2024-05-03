/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
void SetClipboard(const string &in msg) {
    IO::SetClipboard(msg);
    Notify("Copied: " + msg);
}

funcdef bool LabeledValueF(const string &in l, const string &in v);

bool ClickableLabel(const string &in label, const string &in value) {
    return ClickableLabel(label, value, ": ");
}
bool ClickableLabel(const string &in label, const string &in value, const string &in between) {
    UI::Text(label.Length > 0 ? label + between + value : value);
    return UI::IsItemClicked();
}

// bool CopiableLabeledPtr(CMwNod@ nod) {
//     return CopiableLabeledValue("ptr", Text::FormatPointer(Dev_GetPointerForNod(nod)));
// }
bool CopiableLabeledPtr(const uint64 ptr) {
    return CopiableLabeledValue("ptr", Text::FormatPointer(ptr));
}

bool CopiableLabeledValue(const string &in label, const string &in value) {
    if (ClickableLabel(label, value)) {
        SetClipboard(value);
        return true;
    }
    return false;
}

bool CopiableValue(const string &in value) {
    if (ClickableLabel("", value)) {
        SetClipboard(value);
        return true;
    }
    return false;
}




// get an offset from class name & member name
uint16 GetOffset(const string &in className, const string &in memberName) {
    // throw exception when something goes wrong.
    auto ty = Reflection::GetType(className);
    auto memberTy = ty.GetMember(memberName);
    if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
    return memberTy.Offset;
}


// get an offset from a nod and member name
uint16 GetOffset(CMwNod@ obj, const string &in memberName) {
    if (obj is null) return 0xFFFF;
    // throw exception when something goes wrong.
    auto ty = Reflection::TypeOf(obj);
    if (ty is null) throw("could not find a type for object");
    auto memberTy = ty.GetMember(memberName);
    if (memberTy is null) throw(ty.Name + " does not have a child called " + memberName);
    if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
    return memberTy.Offset;
}
