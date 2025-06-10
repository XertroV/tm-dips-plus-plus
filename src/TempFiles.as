namespace TempFiles {
    const string _TempFilesDirName = "temp";
    const string _TempFilesDir = IO::FromStorageFolder(_TempFilesDirName);

    // return the temp files directory, or a subpath of it if provided
    string GetTempFilesLoc(const string &in subPath = "") {
        if (!IO::FolderExists(_TempFilesDir)) {
            IO::CreateFolder(_TempFilesDir);
        }
        return _TempFilesDir + "/" + subPath;
    }

}
