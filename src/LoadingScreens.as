// S_ShowDDLoadingScreens

bool IsLoadingScreenVisible() {
    auto app = GetApp();
    return app.LoadProgress.State != NGameLoadProgress::EState::Disabled;
}

void MaybeDrawLoadingScreen() {
    if (!S_ShowDDLoadingScreens) return;
    CheckPrepareLoadingScreen();
    if (g_currLoadingScreen !is null) {
        if (!IsLoadingScreenVisible()) {
            @g_currLoadingScreen = null;
        } else {
            g_currLoadingScreen.Draw();
        }
    } else if (IsLoadingScreenVisible()) {
        @g_currLoadingScreen = g_nextLoadingScreen;
        if (g_currLoadingScreen is null) {
            @g_currLoadingScreen = GetNewLoadingScreen();
        } else {
            @g_nextLoadingScreen = null;
        }
        g_currLoadingScreen.Draw();
    }
}

string[]@ genLoadingScreenFileList() {
    string[]@ ret = {"img/finish.jpg"};
    for (int i = 16; i >= 0; i--) {
        ret.InsertLast(Text::Format("img/floor%d.jpg", i));
        print("Added " + ret[ret.Length - 1] + " to loading screens");
    }
    return ret;

}

LoadingScreen@ g_currLoadingScreen;
LoadingScreen@ g_nextLoadingScreen;
LoadingScreen@[] usedLoadingScreens;
LoadingScreen@[] unusedLoadingScreens;
string[]@ toLoadLoadingScreens = genLoadingScreenFileList();

void CheckPrepareLoadingScreen() {
    if (toLoadLoadingScreens !is null && toLoadLoadingScreens.Length > 0) {
        auto path = toLoadLoadingScreens[toLoadLoadingScreens.Length - 1];
        if (IO::FileExists(IO::FromStorageFolder(path))) {
            toLoadLoadingScreens.RemoveLast();
            unusedLoadingScreens.InsertLast(LoadingScreen(path));
        } else {
            dev_trace("waiting for " + path + " to load");
        }
    }
    if (g_nextLoadingScreen is null) {
        @g_nextLoadingScreen = GetNewLoadingScreen();
        print("loaded next loading screen");
    }
}

LoadingScreen@ GetNewLoadingScreen() {
    if (unusedLoadingScreens.Length > 0) {
        auto ix = Math::Rand(0, unusedLoadingScreens.Length);
        auto screen = unusedLoadingScreens[ix];
        unusedLoadingScreens.RemoveAt(ix);
        usedLoadingScreens.InsertLast(screen);
        screen.LoadTexture();
        return screen;
    }
    dev_trace('no unused loading screens');
    if (usedLoadingScreens.Length == 0) return null;
    auto ix = Math::Rand(0, usedLoadingScreens.Length);
    return usedLoadingScreens[ix];
}

class LoadingScreen {
    string path;
    UI::Texture@ tex;
    LoadingScreen(const string &in path) {
        this.path = path;
    }

    void LoadTexture() {
        if (tex !is null) return;
        IO::File f(IO::FromStorageFolder(path), IO::FileMode::Read);
        @tex = UI::LoadTexture(f.Read(f.Size()));
        print("loaded texture " + path + " / " + tex.GetSize().ToString());
    }

    void Draw() {
        if (tex is null) {
            warn("null tex");
            return;
        }
        UI::DrawList@ dl = UI::GetBackgroundDrawList();
        // if (S_LoadingScreenDL == LoadingScreenDL::Foreground) {
        //     // @dl = UI::GetForegroundDrawList();
        //     @dl = UI::GetBackgroundDrawList();
        // } else if (S_LoadingScreenDL == LoadingScreenDL::Background) {
        //     @dl = UI::GetBackgroundDrawList();
        // } else {
        //     @dl = UI::GetWindowDrawList();
        // }
        // dl.PushClipRectFullScreen();
        dl.AddRectFilled(vec4(vec2(0), g_screen), vec4(0, 0, 0, 1), 0.);
        dl.AddImage(tex, GetPos(), GetSize());
    }

    vec2 GetPos() {
        if (g_screen.x / g_screen.y > 16./9.) {
            return vec2((g_screen.x - g_screen.y * 16./9.) / 2., 0);
        } else {
            return vec2(0, (g_screen.y - g_screen.x * 9./16.) / 2.);
        }
    }

    vec2 GetSize() {
        if (g_screen.x / g_screen.y > 16./9.) {
            return vec2(g_screen.y * 16./9., g_screen.y);
        } else {
            return vec2(g_screen.x, g_screen.x * 9./16.);
        }
    }
}

enum LoadingScreenDL {
    Background, Middle, Foreground
}
[Setting hidden]
LoadingScreenDL S_LoadingScreenDL = LoadingScreenDL::Foreground;
