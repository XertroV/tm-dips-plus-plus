namespace TitleGag {
    // either we are ready to trigger, or we are waiting for
    enum TGState {
        Ready, WaitingForReset
    }

    TGState state = TGState::Ready;

    void MarkWaiting() {
        state = TGState::WaitingForReset;
    }

    void Reset() {
        state = TGState::Ready;
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
    return TitleGag::IsReady();
}
