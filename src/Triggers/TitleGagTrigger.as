/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
namespace TitleGag {
    // either we are ready to trigger, or we are waiting for
    enum TGState {
        Ready, WaitingForReset
    }

    TGState state = TGState::Ready;

    void MarkWaiting() {
        state = TGState::WaitingForReset;
        dev_trace('title gags: waiting for reset');
    }

    void Reset() {
        state = TGState::Ready;
        dev_trace('title gags: reset');
    }

    void OnPlayerRespawn() {
        dev_trace('reset title gag on respawn');
        Reset();
    }
    void OnReachFloorOne() {
        dev_trace('reset title gag on reach floor 1');
        Reset();
    }

    bool IsReady() {
        return state == TGState::Ready;
    }
}


bool NewTitleGagOkay() {
    return TitleGag::IsReady()
        && !S_HideMovieTitles
        && (!Spectate::IsSpectatorOrMagicSpectator || S_TitleGagsInSpec);
}
