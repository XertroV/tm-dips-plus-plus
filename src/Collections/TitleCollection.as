TitleCollection@ GLOBAL_TITLE_COLLECTION = TitleCollection();

class TitleCollection : Collection {
    TitleCollection() {
        startnew(CoroutineFunc(LoadTitleData));
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
        print("Loaded " + items.Length + " special titles");
    }
}

class TitleCollectionItem : CollectionItem {
    string title;

    TitleCollectionItem(const string &in title) {
        super(title, true);
        this.title = title;
    }

    void PlayItem() { throw("Not implemented"); }

    void DrawDebug() { throw("Not implemented"); }

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

    void PlayItem() override {
        CollectTitleSoon();
        AddTitleScreenAnimation(MainTitleScreenAnim(DEF_TITLE, title, AudioChain({DEF_TITLE_AUDIO, audioFile})));
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
