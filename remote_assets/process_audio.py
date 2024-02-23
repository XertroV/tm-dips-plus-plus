#!/usr/bin/env python3

from pydub import AudioSegment, silence
import os
from pathlib import Path

# Define the path to the directory containing the MP3 files
directory_path = Path(os.curdir).absolute()
print(f"Current directory: {directory_path}")

# Function to trim silence from the beginning and end
def trim_silence(audio_segment, silence_threshold=-50.0, chunk_size=10, silence_duration=200):
    """
    Trims silence from the beginning and end of an audio segment.

    :param audio_segment: The audio segment to process.
    :param silence_threshold: The silence threshold in dB. Default is -50 dB.
    :param chunk_size: The chunk size to use when processing the audio. Default is 10 ms.
    :param silence_duration: The maximum allowed silence duration at the beginning and end in milliseconds. Default is 200 ms.
    :return: Trimmed audio segment.
    """
    # Detect non-silent chunks
    nonsilent_chunks = silence.detect_nonsilent(audio_segment, min_silence_len=chunk_size, silence_thresh=silence_threshold)

    # If no non-silent chunks are found, return the original segment
    if not nonsilent_chunks:
        return audio_segment

    # Calculate start and end times for trimming
    start_trim = nonsilent_chunks[0][0]
    end_trim = nonsilent_chunks[-1][1]
    print(f"Trimming {start_trim} to {end_trim}")

    # Ensure the trimming does not exceed the file's length
    start_trim = max(start_trim - silence_duration, 0)
    end_trim = min(end_trim + silence_duration, len(audio_segment))

    # Return the trimmed audio segment
    return audio_segment[start_trim:end_trim]

# Process each MP3 file in the directory
for filename in os.listdir(directory_path):
    if filename.endswith(".mp3"):
        file_path = directory_path / filename
        print(f"Processing {file_path}")

        # Load the MP3 file
        audio = AudioSegment.from_mp3(file_path)

        # Trim silence from the beginning and end
        trimmed_audio = trim_silence(audio, silence_duration=200) # 200 milliseconds = 0.2 seconds

        outpath = file_path.with_name(f"{filename}")
        print(f"Saving to {outpath}")

        print(f"Length before: {len(audio)}")
        print(f"Length after:  {len(trimmed_audio)}\n\n")

        # Save the trimmed audio back to the file
        trimmed_audio.export(outpath, format="mp3")
