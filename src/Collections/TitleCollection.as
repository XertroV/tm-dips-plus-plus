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
        if (!collected) {
            collectedAt = Time::Stamp;
            collected = true;
        }
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
