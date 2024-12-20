
// hmm doesn't seem to help

string[] heightStrings;

string[] GenerateHeightStrings() {
    uint nbStrs = 3000;
    heightStrings.Reserve(nbStrs);
    for (int i = 0; i < nbStrs; i++) {
        heightStrings.InsertLast(tostring(i));
    }
    return heightStrings;
}

const string GetHeightString(int height) {
    if (Math::Abs(height) >= heightStrings.Length) {
        return tostring(height);
    }
    if (height < 0) {
        return "-" + heightStrings[-height];
    }
    return heightStrings[height];
}
