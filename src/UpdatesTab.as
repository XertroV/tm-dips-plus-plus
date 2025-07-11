void DrawUpdatesTab() {
    DrawCenteredText("Recent Updates", f_DroidBig);
    UI::SeparatorText("");

    UI::Markdown("## Performance Tab");
    UI::TextWrapped("-  \\$<\\$4f4Added experimental fix for low FPS on servers with many disconnected players\\$>");
    UI::TextWrapped("-  Added some suggested plugins to disable");
    UI::TextWrapped("");

    UI::Markdown("## Minimap");
    UI::TextWrapped("-  Added top live climbers \\$<\\$i(Solo: default on, Server: enable in settings)\\$>");
    UI::TextWrapped("-  Added rank next to PB \\$<\\$i(disable in settings)\\$>");
    UI::TextWrapped("-  Show PB label on RHS when equal to WR");
    UI::TextWrapped("-  Show PB of players on minimap when hovering \\$<\\$i(disable in settings)\\$>");
    UI::TextWrapped("-  Add settings for limiting the number of players shown.");
    UI::TextWrapped("");

    UI::Markdown("## Custom Voice Lines");
    UI::TextWrapped("-  Show voice lines (if any) in current map tab.");
    UI::TextWrapped("-  \\$<\\$i\\$888(for Mappers)\\$> Added `maxPlays` attribute.");
}
