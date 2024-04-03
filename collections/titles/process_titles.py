#!/usr/bin/env python3

import os, sys, time
from pathlib import Path


def sanitize_filename(filename: str):
    """Sanitize the filename to be filesystem-friendly."""
    if filename == "Dips++":
        return "dipsplusplus"
    return "".join([c for c in filename if c.isalpha() or c.isdigit() or c==' ']).rstrip().replace(" ", "").replace('é', 'e')

def sanitize_filename_underscore(filename: str):
    """Sanitize the filename to be filesystem-friendly."""
    if filename == "Dips++":
        return "dips_plus_plus"
    return "".join([c for c in filename if c.isalpha() or c.isdigit() or c==' ']).rstrip().replace(" ", "_").replace('é', 'e')

def proc_normal_titles(titles_p: Path):
    titles = list([t for t in titles_p.read_text().split("\n") if len(t.strip()) > 0])
    audios: list[Path] = list([mp3 for mp3 in Path("../../remote_assets/audio/").iterdir() if mp3.suffix == ".mp3"])
    print(f"Titles: {len(titles)}")
    print(f"Audios: {len(audios)}")

    def match_filename(filename: str, audios: list[Path]):
        for audio in audios:
            if str(audio).lower().endswith('/'+filename.lower()):
                return audio

    ordered_titles = []
    ordered_files = []
    for title in titles:
        name1 = sanitize_filename(title).lower() + ".mp3"
        name2 = sanitize_filename_underscore(title).lower() + ".mp3"
        m1 = match_filename(name1, audios)
        m2 = match_filename(name2, audios)
        if m1:
            ordered_files.append(m1)
            ordered_titles.append(title)
        elif m2:
            ordered_files.append(m2)
            ordered_titles.append(title)
        else:
            print(f"Title not found: {title}: {name1}, {name2}")

    lines = []
    for t,f in zip(ordered_titles, ordered_files):
        lines.append(f"{t}|{f.name}")
    out_file = titles_p.with_name(titles_p.stem.lower() + ".psv")
    print(f"Saving to {out_file}...")
    out_file.write_text("\n".join(lines))

if __name__ == "__main__":
    proc_normal_titles(Path("Titles_Normal.txt"))
    proc_normal_titles(Path("Titles_Special.txt"))
    proc_normal_titles(Path("Titles_GeepGip.txt"))
