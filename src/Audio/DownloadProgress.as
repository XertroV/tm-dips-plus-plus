
namespace DownloadProgress {
    uint count = 0;
    uint done = 0;
    uint errored = 0;
    string currLabel = "Download";

    bool get_IsNotDone() {
        return count > 0;
    }

    void Add(uint n, const string &in newLabel = "") {
        count += n;
        if (newLabel.Length > 0)
            currLabel = newLabel;
    }
    void Done(uint n = 1) {
        done += n;
        if (done >= count) {
            Reset();
        }
    }
    void Reset() {
        count = 0;
        done = 0;
        errored = 0;
    }
    void SubOne() {
        count -= 1;
    }
    void Error(const string &in msg) {
        errored++;
        done++;
        warn(currLabel + " Error: " + msg);
    }

    void Draw() {
        if (count == 0) return;
        if (count == done) {
            Reset();
            return;
        }

        UI::SetNextWindowPos(Draw::GetWidth() * 9 / 20, Draw::GetHeight() * 4 / 20, UI::Cond::Appearing);
        if (UI::Begin(currLabel + " Progress", UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoCollapse | UI::WindowFlags::NoCollapse)) {
            UI::Text(currLabel + " Progress:          ");
            UI::ProgressBar(float(done) / float(count), vec2(UI::GetContentRegionAvail().x, 40), tostring(done) + " / " + tostring(count) + (errored > 0 ? " / Err: " + errored : ""));
            UI::Separator();
            UI::TextWrapped("\\$aaaIf this appears to hang for a long time, try reloading the plugin under Developer > Reload > Dips++");
        }
        UI::End();
    }
}
