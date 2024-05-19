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
        Reset();
    }
    void OnReachFloorOne() {
        Reset();
    }

    bool IsReady() {
        return state == TGState::Ready;
    }
}


bool NewTitleGagOkay() {
    return TitleGag::IsReady()
        && !S_HideMovieTitles;
}
