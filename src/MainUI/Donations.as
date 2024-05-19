

namespace Donations {

    void DrawDonoCheers() {
        if (UI::BeginChild("donocheers", vec2(-1, 140), true, UI::WindowFlags::AlwaysVerticalScrollbar)) {
            float maxAmt = cheers.Length == 0 ? 100. : cheers[0].TotalAmt;
            maxAmt = Math::Max(maxAmt, 1.0);
            float tWidth;
            float maxW = UI::GetWindowContentRegionWidth() * .75;
            float t;
            vec2 cur;
            LBEntry@ pb;
            for (uint i = 0; i < cheers.Length; i++) {
                t = cheers[i].TotalAmt / maxAmt;
                @pb = Global::GetPlayersPBEntryWL(cheers[i].wsid, cheers[i].login);
                float ls = pb is null ? 0.0 : pb.color.LengthSquared();
                bool doColor = pb !is null && ls > 0.5 && ls < 2.5;
                cur = UI::GetCursorPos();
                if (doColor) UI::PushStyleColor(UI::Col::PlotHistogram, vec4(pb.color, 1.0));
                UI::ProgressBar(t, vec2(maxW, UI::GetTextLineHeight()));
                if (doColor) UI::PopStyleColor();
                UI::SetCursorPos(cur + vec2(maxW * t + 8., 0.));
                UI::Text(tostring(i + 1) + ". " + cheers[i].playerName + Text::Format(" ($%.2f)", cheers[i].TotalAmt));
            }
        }
        UI::EndChild();
    }

    DonoCheerCount@[] cheers;

    void SetUpCheers() {
        if (cheers.Length > 0) return;
        // top 20 2024-05-10
        cheers.InsertLast(DonoCheerCount("BrenTM", "bren", "5d6b14db-4d41-47a4-93e2-36a3bf229f9b"));
        cheers.InsertLast(DonoCheerCount("Hazardu.", "hazard", "e5a9863b-1844-4436-a8a8-cea583888f8b"));
        cheers.InsertLast(DonoCheerCount("eLconn21", "elcon", "d46fb45d-d422-47c9-9785-67270a311e25"));
        cheers.InsertLast(DonoCheerCount("Larstm", "lars", "e3ff2309-bc24-414a-b9f1-81954236c34b"));
        cheers.InsertLast(DonoCheerCount("WirtualTM", "wirt", "bd45204c-80f1-4809-b983-38b3f0ffc1ef"));
        cheers.InsertLast(DonoCheerCount("simo_900", "simo", "803695f6-8319-4b8e-8c28-44856834fe3b"));
        cheers.InsertLast(DonoCheerCount("SkandeaR", "skandear", "c1e8bbec-8bb3-40b3-9b0e-52e3cb36015e"));
        cheers.InsertLast(DonoCheerCount("Scrapie98", "scrapie", "da4642f9-6acf-43fe-88b6-b120ff1308ba"));
        cheers.InsertLast(DonoCheerCount("GranaDy.", "grana", "05477e79-25fd-48c2-84c7-e1621aa46517"));
        cheers.InsertLast(DonoCheerCount("Korchii", "korchi", "7f1707fe-bc7d-4b3c-90f7-a95e5be5f0da"));
        cheers.InsertLast(DonoCheerCount("TarporTM", "tarpor", "e387f7d8-afb0-4bf6-bb29-868d1a62de3b"));
        cheers.InsertLast(DonoCheerCount("Talliebird", "tallie", "a4699c4c-e6c1-4005-86f6-55888f854e6f"));
        cheers.InsertLast(DonoCheerCount("Schmaniol", "schman", "0fd26a9f-8f70-4f51-85e1-fe99a4ed6ffb"));
        cheers.InsertLast(DonoCheerCount("iiHugo", "hugo", "3433b0f2-5acd-47a8-b32c-8c811c984a9f"));
        cheers.InsertLast(DonoCheerCount("Spammiej", "spam", "3bb0d130-637d-46a6-9c19-87fe4bda3c52"));
        cheers.InsertLast(DonoCheerCount("Kubas.", "kubas", "21029447-5895-4e1e-829c-14dedb4af788"));
        cheers.InsertLast(DonoCheerCount("mtat_tm", "mtat", "fc54a67c-7bd3-4b33-aa7d-a77f13a7b621"));
        cheers.InsertLast(DonoCheerCount("CarlJr.", "carl", "0c857beb-fd95-4449-a669-21fb310cacae"));
        cheers.InsertLast(DonoCheerCount("Loupphok", "loupphok", "faedcf21-d61a-4305-9ffe-680b2ee5d65e"));
        cheers.InsertLast(DonoCheerCount("Massa.4PF", "massa", "b05db0f8-d845-47d2-b0e5-795717038ac6"));
    }

    void ResetDonoCheers() {
        for (uint i = 0; i < cheers.Length; i++) {
            cheers[i].Reset();
        }
    }

    void SortCheers() {
        for (uint i = 0; i < cheers.Length; i++) {
            cheers[i].DoneCounting();
        }
        DonationQuicksort(cheers, DonoCheerCountDesc);
    }

    DonoCheerCount@[] donoMatches;
    string tmp_donoCommentLower;

    void AddDonation(Global::Donation@ dono) {
        tmp_donoCommentLower = dono.comment.ToLower();
        donoMatches.Resize(0);
        for (uint i = 0; i < cheers.Length; i++) {
            if (cheers[i].MatchComment(tmp_donoCommentLower)) {
                donoMatches.InsertLast(cheers[i]);
            }
        }
        if (donoMatches.Length == 0) return;
        float amt = dono.amount / float(donoMatches.Length);
        for (uint i = 0; i < donoMatches.Length; i++) {
            donoMatches[i].AddDonationAmt(amt);
        }
        // print("Dono Matchs: " + donoMatches.Length + " /for/ " + dono.comment);
    }

    class DonoCheerCount {
        MwId targetWsidMwId;
        MwId targetLoginMwId;
        string login;
        string wsid;
        string playerName;
        string detectionString;
        float totalAmt = 0.;
        float lastTotalAmt = 0.;

        DonoCheerCount(const string &in name, const string &in detection, const string &in wsid) {
            this.wsid = wsid;
            this.login = WSIDToLogin(wsid);
            targetWsidMwId.SetName(wsid);
            targetLoginMwId.SetName(WSIDToLogin(wsid));
            playerName = name;
            this.detectionString = detection;
        }

        float get_TotalAmt() {
            return lastTotalAmt;
        }

        void Reset() {
            totalAmt = 0.;
        }

        bool MatchComment(const string &in commentLowerCase) {
            return commentLowerCase.Contains(detectionString);
        }

        void AddDonationAmt(float amt) {
            totalAmt += amt;
        }

        void DoneCounting() {
            lastTotalAmt = totalAmt;
        }
    }
}


int DonoCheerCountDesc(Donations::DonoCheerCount@ m1, Donations::DonoCheerCount@ m2) {
    if (m1.TotalAmt < m2.TotalAmt) return 1;
    if (m1.TotalAmt > m2.TotalAmt) return -1;
    auto pb1 = Global::GetPlayersPBEntryWL(m1.wsid, m1.login);
    auto pb2 = Global::GetPlayersPBEntryWL(m2.wsid, m2.login);
    if (pb1 is null) {
        if (pb2 is null) return 0;
        return 1;
    } else if (pb2 is null) return -1;
    if (pb1.height > pb2.height) return -1;
    if (pb1.height < pb2.height) return 1;
    return 0;
}


// -1 = less, 0 = eq, 1 = greater
// funcdef int DonationLessF(Donations::DonoCheerCount@ &in m1, Donations::DonoCheerCount@ &in m2);
funcdef int DonationLessF(Donations::DonoCheerCount@ m1, Donations::DonoCheerCount@ m2);
void DonationQuicksort(Donations::DonoCheerCount@[]@ arr, DonationLessF@ f, int left = 0, int right = -1) {
    if (arr.Length < 2) return;
    if (right < 0) right = arr.Length - 1;
    int i = left;
    int j = right;
    Donations::DonoCheerCount@ pivot = arr[(left + right) / 2];
    Donations::DonoCheerCount@ temp;

    while (i <= j) {
        while (f(arr[i], pivot) < 0) i++;
        while (f(arr[j], pivot) > 0) j--;
        if (i <= j) {
            @temp = arr[i];
            @arr[i] = arr[j];
            @arr[j] = temp;
            i++;
            j--;
        }
    }

    if (left < j) DonationQuicksort(arr, f, left, j);
    if (i < right) DonationQuicksort(arr, f, i, right);
}
