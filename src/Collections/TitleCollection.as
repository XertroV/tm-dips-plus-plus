TitleCollection@ GLOBAL_TITLE_COLLECTION = TitleCollection();
TitleCollection@ GLOBAL_GG_TITLE_COLLECTION = GG_TitleCollection();

class TitleCollection : Collection {
    bool isGeepGip = false;
    TitleCollection(bool isGeepGip = false) {
        this.isGeepGip = isGeepGip;
        if (isGeepGip) {
            trace('loading GG titles');
            startnew(CoroutineFunc(LoadGeepGipTitleData));
        } else {
            trace('loading normal titles');
            startnew(CoroutineFunc(LoadTitleData));
            // startnew(CoroutineFunc(LoadSpecialTitleData));
        }
    }

    void LoadTitleData() {
        IO::FileSource file("Collections/titles_normal.psv");
        string line;
        while ((line = file.ReadLine()).Length > 0) {
            auto@ parts = line.Split("|");
            if (parts.Length < 2) {
                warn("Invalid title line: " + line);
                continue;
            }
            AddItem(TitleCollectionItem_Norm(parts[0], parts[1]));
        }
        print("Loaded " + items.Length + " titles");
        LoadSpecialTitleData();
    }
    void LoadSpecialTitleData() {
        auto initLen = items.Length;
        IO::FileSource file("Collections/titles_special.psv");
        string line;
        while ((line = file.ReadLine()).Length > 0) {
            auto@ parts = line.Split("|");
            if (parts.Length < 2) {
                warn("Invalid title line: " + line);
                continue;
            }
            AddItem(TitleCollectionItem_Special(parts[0], parts[1]));
        }
        print("Loaded " + (items.Length - initLen) + " special titles");
    }
    void LoadGeepGipTitleData() {
        auto initLen = items.Length;
        IO::FileSource file("Collections/titles_geepgip.psv");
        string line;
        while ((line = file.ReadLine()).Length > 0) {
            auto@ parts = line.Split("|");
            if (parts.Length < 2) {
                warn("Invalid title line: " + line);
                continue;
            }
            AddItem(TitleCollectionItem_GeepGip(parts[0], "gg/" + parts[1]));
        }
        print("Loaded " + (items.Length - initLen) + " gg titles");
    }
}

class GG_TitleCollection : TitleCollection {
    GG_TitleCollection() {
        this.isGeepGip = true;
        super(true);
    }
}

class TitleCollectionItem : CollectionItem {
    string title;

    TitleCollectionItem(const string &in title) {
        super(title, true);
        this.title = title;
    }

    void CollectTitleSoon() {
        CollectSoonTrigger(1200);
    }
}

class TitleCollectionItem_Special : TitleCollectionItem {
    string audioFile;
    string[] titleLines;
    string specialType;

    TitleCollectionItem_Special(const string &in title, const string &in audio) {
        super(title);
        this.audioFile = audio;
        if (title.Contains("Dipenator")) {
            specialType = "Terminator";
        } else if (title.Contains("Deep Trek: ")) {
            specialType = "Star Trek";
        }
        this.titleLines = title.Split(": ");
    }

    void PlayItem() override {
        if (!AudioFilesExist({audioFile}, true)) {
            return;
        }
        CollectTitleSoon();
        if (titleLines.Length == 1) {
            AddTitleScreenAnimation(MainTitleScreenAnim(titleLines[0], AudioChain({audioFile})));
        } else if (titleLines.Length == 2) {
            AddTitleScreenAnimation(MainTitleScreenAnim(titleLines[0], titleLines[1], AudioChain({audioFile})));
        } else {
            throw('cant deal with more than 2 title lines');
        }
    }

    void DrawDebug() override {
        UI::AlignTextToFramePadding();
        UI::Text(title);
        UI::SameLine();
        if (UI::Button("Play##" + title)) {
            print("Playing " + title + ", audio " + audioFile);
            PlayItem();
        }
        UI::SameLine();
        if (collected) {
            UI::Text("\\$4e4" + Icons::Check);
        } else {
            UI::Text("\\$e44" + Icons::Times);
        }
    }
}

const string DEF_TITLE_AUDIO = "deep_dip_2.mp3";
const string DEF_TITLE = "Deep Dip 2";

class TitleCollectionItem_Norm : TitleCollectionItem {
    string audioFile;

    TitleCollectionItem_Norm(const string &in title, const string &in audio) {
        super(title);
        this.audioFile = audio;
    }

    const string get_MainTitlePath() {
        return DEF_TITLE_AUDIO;
    }

    const string get_MainTitleText() {
        return DEF_TITLE;
    }

    void PlayItem() override {
        if (!AudioFilesExist({MainTitlePath, audioFile}, false)) {
            return;
        }
        CollectTitleSoon();
        AddTitleScreenAnimation(MainTitleScreenAnim(MainTitleText, title, AudioChain({MainTitlePath, audioFile})));
    }

    void DrawDebug() override {
        UI::AlignTextToFramePadding();
        UI::Text(title);
        UI::SameLine();
        if (UI::Button("Play##" + title)) {
            print("Playing " + title + ", audio " + audioFile);
            PlayItem();
        }
        UI::SameLine();
        if (collected) {
            UI::Text("\\$4e4" + Icons::Check);
        } else {
            UI::Text("\\$e44" + Icons::Times);
        }
    }
}

class TitleCollectionItem_GeepGip : TitleCollectionItem_Norm {
    TitleCollectionItem_GeepGip(const string &in title, const string &in audio) {
        super(title, audio);
    }

    const string get_MainTitlePath() override {
        return "gg/geep_gip_2.mp3";
    }

    const string get_MainTitleText() override {
        return "Geep Gip 2";
    }
}
