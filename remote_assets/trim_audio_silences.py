#!/usr/bin/env python3

import os, sys
from pathlib import Path

import librosa
import noisereduce as nr
import soundfile as sf
from pydub import AudioSegment, silence

args = sys.argv[1:] + [os.curdir]
print(args)

# Define the path to the directory containing the MP3 files
directory_path = Path(args[0]).absolute()
print(f"Processing MP3 files in {directory_path}")
print(f"Press enter to continue or Ctrl+C to cancel")
input()

DO_NOISE_REDUCTION = False

# Function to convert MP3 to WAV (since librosa directly supports WAV)
def mp3_to_wav(mp3_file_path, wav_file_path):
    audio = AudioSegment.from_mp3(mp3_file_path)
    audio.export(wav_file_path, format="wav")

# Function to perform noise reduction on an audio file
def reduce_noise(input_file_path, output_file_path):
    # Load the file
    data, rate = librosa.load(input_file_path, sr=None)

    # Perform noise reduction
    reduced_noise_audio = nr.reduce_noise(y=data, sr=rate)

    # Save the output
    sf.write(output_file_path, reduced_noise_audio, rate)


# Function to trim silence from the beginning and end
def trim_silence(audio_segment, silence_threshold=-35.0, chunk_size=10, silence_duration=200):
    """
    Trims silence from the beginning and end of an audio segment.

    :param audio_segment: The audio segment to process.
    :param silence_threshold: The silence threshold in dB. Default is -35 dB.
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
        # out_filename = f"trimmed_{filename}"
        out_filename = f"{filename}"
        cleaned_mp3_path = file_path

        if DO_NOISE_REDUCTION:
            # Convert MP3 to WAV for processing
            temp_wav_path = os.path.join(directory_path, "temp.wav")
            mp3_to_wav(file_path, temp_wav_path)

            # Perform noise reduction
            output_wav_path = os.path.join(directory_path, "cleaned_temp.wav")
            reduce_noise(temp_wav_path, output_wav_path)

            # Convert the cleaned WAV back to MP3
            cleaned_mp3_path = os.path.join(directory_path, out_filename)
            cleaned_audio = AudioSegment.from_wav(output_wav_path)
            cleaned_audio.export(cleaned_mp3_path, format="mp3")

        # Load the MP3 file
        audio = AudioSegment.from_mp3(cleaned_mp3_path)

        # Trim silence from the beginning and end
        trimmed_audio = trim_silence(audio, silence_duration=200) # in milliseconds

        outpath = file_path.with_name(f"{out_filename}")
        print(f"Saving to {outpath}")
        # input("Press enter to save")

        print(f"Length before: {len(audio)}")
        print(f"Length after:  {len(trimmed_audio)}\n\n")

        # Save the trimmed audio back to the file
        trimmed_audio.export(outpath, format="mp3")

        # print(f"Continue? (press enter)")
        # input()
