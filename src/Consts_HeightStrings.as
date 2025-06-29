// hmm doesn't seem to help

string[] heightStrings;

string[] GenerateHeightStrings() {
    uint nbStrs = 3000;
    heightStrings.Reserve(nbStrs);
    for (uint i = 0; i < nbStrs; i++) {
        heightStrings.InsertLast(tostring(i));
    }
    return heightStrings;
}

const string GetHeightString(int height) {
    if (Math::Abs(height) >= int(heightStrings.Length)) {
        return tostring(height);
    }
    if (height < 0) {
        return "-" + heightStrings[uint(-height)];
    }
    return heightStrings[height];
}
