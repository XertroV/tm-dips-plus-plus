
// call me every frame.
void TellArenaIfaceToGetPositionData() {
    auto app = GetApp();
    CSmArenaClient@ cp = cast<CSmArenaClient>(app.CurrentPlayground);
    if (cp is null) return;
    auto arean_iface_mgr = cp.ArenaInterface;
    if (arean_iface_mgr is null) return;
    // unfortunately no offset to do something relative to.
    Dev::SetOffset(arean_iface_mgr, 0x12c, uint8(0));
}
