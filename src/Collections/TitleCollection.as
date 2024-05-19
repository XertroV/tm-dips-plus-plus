/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
TitleCollection@ GLOBAL_TITLE_COLLECTION = TitleCollection();
TitleCollection@ GLOBAL_GG_TITLE_COLLECTION = GG_TitleCollection();

class TitleCollection : Collection {
    bool initialized = false;
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

    void AddItem(CollectionItem@ item) override {
        Collection::AddItem(item);
        auto titleItem = cast<TitleCollectionItem>(item);
        if (titleItem !is null) {
            @titleItem.parent = this;
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
        startnew(CoroutineFunc(RestoreFromSaved));
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
        startnew(CoroutineFunc(RestoreFromSaved));
    }

    void DrawStats() {
        uint total = items.Length;
        uint nb_uncollected = uncollected.Length;
        uint nb_collected = total - nb_uncollected;
        UI::AlignTextToFramePadding();
        UI::PushFont(f_DroidBig);
        if (isGeepGip && nb_collected == 0) {
            UI::Text("?????????");
        } else {
            UI::Text("Collection: " + (isGeepGip ? "Geep Gips" : "Title Gags"));
        }
        UI::PopFont();
        UI::Text("Collected: " + nb_collected + " / " + items.Length);
    }

    string get_FileName() {
        return IO::FromStorageFolder(isGeepGip ? "gg_titles_collected.txt" : "norm_titles_collected.txt");
    }

    void RestoreFromSaved() override {
        if (!IO::FileExists(FileName)) return;
        IO::File f(FileName, IO::FileMode::Read);
        string line;
        Json::Value@ j;
        Json::Value@[] collected;
        while (!f.EOF()) {
            line = f.ReadLine();
            if (line.Length == 0) continue;
            try {
                @j = Json::Parse(line);
                if (j !is null && j.HasKey("name") && j.HasKey("collected") && bool(j["collected"])) {
                    collected.InsertLast(j);
                }
            } catch {
                warn("Failed to parse title collection line: " + line);
                continue;
            }
        }
        f.Close();
        string cName;
        print("loaded " + collected.Length + " collected titles");
        for (uint i = 0; i < collected.Length; i++) {
            cName = collected[i]["name"];
            if (itemLookup.Exists(cName)) {
                auto item = cast<TitleCollectionItem>(itemLookup[cName]);
                if (item !is null) {
                    item.collected = true;
                    item.collectedAt = collected[i]["collectedAt"];
                } else {
                    warn("Failed to find item for " + cName);
                }
            }
        }
        UpdateUncollected();
        initialized = true;
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
    TitleCollection@ parent;

    TitleCollectionItem(const string &in title) {
        super(title, true);
        this.title = title;
    }

    void CollectTitleSoon() {
        CollectSoonTrigger(1200);
        startnew(CoroutineFunc(LogCollectedWhenCollected));
    }

    void LogCollectedWhenCollected() {
        while (!collected) {
            yield();
        }
        IO::File f(parent.FileName, IO::FileMode::Append);
        f.WriteLine(Json::Write(this.ToUserJson()));
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

    void LogCollected() override {
        Stats::LogTriggeredTitleSpecial(title);
    }

    void PlayItem(bool collect = true) override {
        if (!AudioFilesExist({audioFile}, true)) {
            return;
        }
        if (collect) {
            CollectTitleSoon();
        }
        if (titleLines.Length == 1) {
            AddTitleScreenAnimation(MainTitleScreenAnim(titleLines[0], AudioChain({audioFile}).WithPlayAnywhere()));
        } else if (titleLines.Length >= 2) {
            AddTitleScreenAnimation(MainTitleScreenAnim(titleLines[0], titleLines[1], AudioChain({audioFile}).WithPlayAnywhere(), 0.0));
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

    void PlayItem(bool collect = true) override {
        if (!AudioFilesExist({MainTitlePath, audioFile}, false)) {
            return;
        }
        if (IsTitleGagPlaying()) {
            return;
        }
        if (collect) {
            CollectTitleSoon();
        }
        AddTitleScreenAnimation(MainTitleScreenAnim(MainTitleText, title, AudioChain({MainTitlePath, audioFile}).WithPlayAnywhere()));
    }

    void LogCollected() override {
        Stats::LogTriggeredTitle(title);
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

    void LogCollected() override {
        Stats::LogTriggeredGG(title);
    }

    const string get_MainTitlePath() override {
        return "gg/geep_gip_2.mp3";
    }

    const string get_MainTitleText() override {
        return "Geep Gip 2";
    }
}
