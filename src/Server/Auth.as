/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
uint lastAuthTime = 0;
string g_opAuthToken;
uint authFails = 0;

bool _IsRequestingAuthToken = false;
const string CheckTokenUpdate() {
    while (_IsRequestingAuthToken) yield_why("waiting for auth token");
    if (!HasAuthToken()) {
        try {
            _IsRequestingAuthToken = true;
            auto task = Auth::GetToken();
            while (!task.Finished()) yield_why("waiting for auth token task to finish");
            g_opAuthToken = task.Token();
            lastAuthTime = Time::Now;
            authFails = 0;
            // OnGotNewToken();
        } catch {
            authFails++;
            log_warn("Auth Fail ("+authFails+"); Got exception refreshing auth token: " + getExceptionInfo());
            g_opAuthToken = "";
            uint waitFor = 5000 * Math::Pow(2, Math::Clamp(authFails, 1, 4));
            sleep_fix(waitFor + Math::Rand(0, 5000));
        }
        _IsRequestingAuthToken = false;
    }
    return g_opAuthToken;
}

// for coros
void UpdateAuthTokenIfNeeded() {
    if (!HasAuthToken()) {
        CheckTokenUpdate();
    }
}

const string GetAuthToken() {
    string ret = CheckTokenUpdate();
    while (ret == "") {
        sleep_fix(1000);
        ret = CheckTokenUpdate();
    }
    return ret;
}

bool HasAuthToken() {
    return g_opAuthToken != "" && lastAuthTime > 0 && Time::Now < lastAuthTime + (180 * 1000);
}

void AwaitAuthToken() {
    while (!HasAuthToken()) {
        yield();
    }
}
