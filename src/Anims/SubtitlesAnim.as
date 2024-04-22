class SubtitlesAnim : Animation {
    string file;
    uint[] startTimes;
    string[] lines;
    uint endTime;

    SubtitlesAnim(const string &in file) {
        super(file);
        this.file = file;
        bool fileExists = false;
        try {
            IO::FileSource f(file);
            fileExists = true;
        } catch {
            warn("Failed to find subtitles file: " + file);
        }
        if (fileExists) {
            LoadSubtitles();
            // delay slightly to avoid fading out too fast
            endTime = startTimes[startTimes.Length - 1] + 350;
            trace('Subtitles duration: ' + endTime);
            for (uint i = 0; i < startTimes.Length; i++) {
                trace(startTimes[i] + " -> " + lines[i]);
            }
        }
    }

    void LoadSubtitles() {
        IO::FileSource f(file);
        string l;
        string[]@ parts;
        uint start;
        while ((l = f.ReadLine()) != "") {
            // if (l == "") continue;
            @parts = l.Split(":", 2);
            if (parts.Length != 2) {
                warn("Bad subtitle parts: " + Json::Write(parts.ToJson()));
            }
            if (parts.Length < 2) continue;
            try {
                start = Text::ParseUInt(parts[0].Trim());
            } catch {
                warn("Bad subtitle start time: " + parts[0]);
                continue;
            }
            startTimes.InsertLast(start);
            lines.InsertLast(parts[1].Trim());
        }
        if (lines[lines.Length - 1] != "") {
            throw("Last subtitle line is not empty");
        }
        startTimes.InsertLast(startTimes[startTimes.Length - 1] + fadeDuration + 100);
        lines.InsertLast("");
    }

    string ToString(int i) override {
        return file + " | " + progressMs + " / " + endTime
            + " | ix: " + currIx + " | lineFade: " + currLineFadeProgress;
    }

    void OnEndAnim() override {
        lastUpdate = 0;
        time = 0;
        delta = 0;
        progressMs = 0;
        currIx = -1;
        currLineStarts.RemoveRange(0, currLineStarts.Length);
        currLineIxs.RemoveRange(0, currLineIxs.Length);
        currLineFadeProgress = 0;
    }

    uint delta;
    uint time;
    uint lastUpdate;
    uint progressMs;

    bool Update() override {
        time = Time::Now;
        if (lastUpdate == 0) {
            delta = 0;
        } else {
            delta = time - lastUpdate;
            if (delta > 100) {
                warn("[subtitles] Large delta: " + delta);
            }
        }
        if (!IsPauseMenuOpen()) {
            progressMs += delta;
            UpdateInner();
        }
        lastUpdate = time;
        return progressMs < endTime;
    }

    uint fadeDuration = 500;

    /*
        we can show at most 3 lines at once (when 1 is fading out and 1 is fading in).
        usually, 2 lines are shown.
        when we start, only 1 is shown, and empty lines should not be drawn as an empty line.
        globally we want to fade in/out everything at the start/end.

    */

    float globalFadeIn;
    float globalFadeOut;
    int currIx = -1;
    // should have no more than 3 at once.
    uint[] currLineStarts;
    uint[] currLineIxs;
    float currLineFadeProgress;
    float fontSize;
    float maxWidth;
    vec2[] lineBounds;
    float textOffset;

    uint get_currLineStart() {
        auto l = currLineStarts.Length;
        if (l == 0) return 0;
        return currLineStarts[l - 1];
    }

    void UpdateInner() {
        // 0 -> 1
        globalFadeIn = Math::Clamp(float(progressMs) / float(fadeDuration), 0., 1.);
        // 1 -> 0
        globalFadeOut = Math::Clamp(float(endTime - progressMs) / float(fadeDuration), 0., 1.);
        // -----
        bool wentNext = false;
        if (currIx < 0) {
            currIx = 0;
            currLineStarts.InsertLast(startTimes[currIx]);
            currLineIxs.InsertLast(currIx);
            currLineFadeProgress = 0;
            wentNext = true;
        }
        if (currIx < startTimes.Length - 1) {
            if (progressMs >= startTimes[currIx + 1]) {
                currIx++;
                currLineStarts.InsertLast(startTimes[currIx]);
                currLineIxs.InsertLast(currIx);
                currLineFadeProgress = 0;
                wentNext = true;
            }
        }
        currLineFadeProgress = Math::Clamp(float(progressMs - currLineStart) / float(fadeDuration), 0.0, 1.0);

        if (currLineFadeProgress >= 1.0 && currLineIxs.Length == 3) {
            currLineIxs.RemoveAt(0);
            currLineStarts.RemoveAt(0);
            textOffset = 0;
            wentNext = true;
        }
        if (wentNext) {
            priorTextBounds = fullTextBounds;
            GenerateTextBounds();
            if (priorTextBounds.x <= 0.0) {
                priorTextBounds = fullTextBounds;
            }
        }
        UpdateTextBounds();
    }

    void SetupNvgFonts() {
        nvg::FontSize(fontSize);
        nvg::FontFace(f_Nvg_ExoMediumItalic);
        nvg::TextLineHeight(1.2);
        nvg::TextAlign(nvg::Align::Top | nvg::Align::Left);
    }


    void GenerateTextBounds() {
        fontSize = g_screen.y / 40.0;
        maxWidth = g_screen.x * .5;
        SetupNvgFonts();
        fullTextBounds = vec2(maxWidth, 0);
        lineBounds.RemoveRange(0, lineBounds.Length);

        uint startIx = currLineIxs.Length >= 3 ? 1 : 0;
        for (uint i = 0; i < currLineIxs.Length; i++) {
            // todo: currLineIxs[i].Length == 0 check?
            auto ix = currLineIxs[i];
            auto bounds = nvg::TextBoxBounds(maxWidth, lines[ix]);
            if (bounds.y > 0) {
                bounds.y += fontSize * .2;
            }
            lineBounds.InsertLast(bounds);
            // trace("inserted lineBounds: " + bounds.ToString());
            if (i >= startIx) {
                fullTextBounds.y += bounds.y; // todo: add padding?
            }
        }
    }

    void UpdateTextBounds() {
        currTextBounds = Math::Lerp(priorTextBounds, fullTextBounds, currLineFadeProgress);
        if (currLineFadeProgress < 1.0 && lineBounds.Length > 2) {
            // todo: add padding?
            textOffset = lineBounds[0].y * currLineFadeProgress;
        } else {
            textOffset = 0;
        }
        centerPos = g_screen * vec2(.5, .85);
    }

    /*
        animation cases:
        1. single voice line fading in
        2. second voice line fading in
        3. first voice line fading out on blank line
        4. third voice line fading in + first voice line fading out

        background rect should animate height when changing lines.
        fading in/out also has a slide up respectively.
    */

    vec2 fullTextBounds;
    vec2 priorTextBounds;
    // for animating bg box
    vec2 currTextBounds;

    vec2 Draw() override {
        nvg::Reset();
        SetupNvgFonts();
        auto alpha = globalFadeIn * globalFadeOut;
        nvg::GlobalAlpha(alpha);

        DrawBackgroundBox(alpha);
        DrawSubtitleLines();

        nvg::GlobalAlpha(1.0);

        return fullTextBounds;
    }

    vec2 centerPos;
    vec2 textTL;

    void DrawBackgroundBox(float alpha) {
        float round = g_screen.y * .03;
        vec2 pad = vec2(round, round / 2.);
        auto yPosOff = 0.0; // g_screen.y * .1 * (1.0 - alpha);
        textTL = centerPos - currTextBounds * .5 + vec2(0, yPosOff);
        auto tl = textTL + vec2(round / 5., fontSize * -0.65) - pad;
        auto bgSize = currTextBounds + vec2(round) + pad * 2.0;
        nvg::BeginPath();
        nvg::FillColor(cBlack75);
        nvg::RoundedRect(tl, bgSize, round);
        nvg::Fill();
        nvg::ClosePath();
    }

    void DrawSubtitleLines() {
        float yOff = 0.0;
        auto nbLines = currLineIxs.Length;
        bool fadingIn, fadingOut;
        float textAlpha = 1.0;
        for (uint i = 0; i < nbLines; i++) {
            fadingIn = i == nbLines - 1 && currLineFadeProgress < 1.0;
            fadingOut = !fadingIn && i == 0 && nbLines == 3 && currLineFadeProgress < 1.0;
            textAlpha = fadingIn ? currLineFadeProgress : fadingOut ? 1.0 - currLineFadeProgress : 1.0;
            nvg::FillColor(cWhite * vec4(1, 1, 1, textAlpha));
            auto ix = currLineIxs[i];
            nvg::TextBox(textTL + vec2(0, yOff - textOffset), maxWidth, lines[ix]);
            yOff += lineBounds[i].y;
        }
    }
}
