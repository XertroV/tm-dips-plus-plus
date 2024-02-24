from pathlib import Path
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import os, sys

# Initialize the driver and set the implicit wait time if necessary
driver = webdriver.Firefox() # Or whichever browser you're using
driver.set_window_size(2420, 1280)
driver.set_window_position(100, 100)
driver.implicitly_wait(10)
driver.get('https://elevenlabs.io/speech-synthesis')
ls_key = os.environ.get('ELEVENLABS_AUTH_KEY')
ls_val = os.environ.get('ELEVENLABS_AUTH_VAL')
if len(ls_key) == 0 or len(ls_val) == 0:
    print(f"Please set the ELEVENLABS_AUTH_KEY and ELEVENLABS_AUTH_VAL environment variables")
    sys.exit(1)
driver.execute_script(f"window.localStorage.setItem('{ls_key}', '{ls_val}');")
ls_val = '{"7dYEhp5uUI7fL30Im2Ks":1708744717657,"tRHw88OXJFlj5KrSC7xX":1708744708825}'
driver.execute_script(f"window.localStorage.setItem('voice-dropdown', '{ls_val}');")
driver.execute_script(f"window.localStorage.setItem('xi:selected-voice-id', '7dYEhp5uUI7fL30Im2Ks');")
driver.get('https://elevenlabs.io/speech-synthesis')


def wait_for_voice_settings():
    # Wait for the voice settings to load
    WebDriverWait(driver, 60).until(
        EC.visibility_of_element_located((By.XPATH, "//span[text()='Voice Settings']"))
    )
    print(f"Voice settings loaded!")

wait_for_voice_settings()
time.sleep(0.2)

def switch_to_speech_to_speech_mode():
    # Find and click the 'Speech to Speech' mode button
    speech_to_speech_button = driver.find_element(By.XPATH, '//span[text()="Speech to Speech"]')
    speech_to_speech_button.click()
    print(f"Clicked: {speech_to_speech_button}")

def reset_form_to_text_to_speech():
    # Find and click the 'Text to Speech' button to reset the form
    text_to_speech_button = driver.find_element(By.XPATH, '//span[text()="Text to Speech"]')
    text_to_speech_button.click()
    print(f"Clicked: {text_to_speech_button}")

def hide_sound_bar():
    # Find and click the 'Speech to Speech' mode button
    speech_to_speech_button = driver.find_element(By.CSS_SELECTOR, 'button[aria-label="Minimize Audio Player"]')
    speech_to_speech_button.click()

def upload_file(file_path):
    # Find and click the upload area
    # upload_area = driver.find_element(By.CSS_SELECTOR, 'upload_area_selector')
    # upload_area.click()

    file_input = driver.find_element(By.CSS_SELECTOR, "input[type='file'][name='file-upload']")
    file_input.send_keys(file_path)
    print(f"Set upload to: {file_path}")

    # # This is browser and OS dependent, might require additional automation to handle the file dialog
    # # Alternatively, if the website allows, you can send the file path directly to the upload input element
    # upload_input = driver.find_element(By.CSS_SELECTOR, 'upload_input_selector')
    # upload_input.send_keys(file_path)

def click_generate():
    # Find and click the 'Generate' button
    generate_button = driver.find_element(By.XPATH, '//button[text()="Generate"]')
    generate_button.click()
    print(f"Clicked: {generate_button}")


generation_timeout = 60  # Adjust the time according to your needs

def wait_for_generation_to_complete():
    # Wait for the generation to complete, this will depend on how the website signals that the task is done
    # For example, waiting for a specific element to be visible
    WebDriverWait(driver, generation_timeout).until(
        # audio_player = driver.find_element(By.CSS_SELECTOR, "div[data-testid='audio-player']")
        EC.visibility_of_element_located((By.CSS_SELECTOR, "div[data-testid='audio-player'] div[aria-label='audio player']"))
    )
    print(f"Generation complete!")

def download_new_file():
    # get sidebar parent: ".px-1\\.5.py-2.overflow-y-auto .space-y-2"
    # dl icon button: aria-label="Download Audio"
    # Wait for the download link to appear in the sidebar
    download_link = WebDriverWait(driver, 30).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'button[aria-label="Download Audio"]'))
    )
    time.sleep(0.5)
    download_link = WebDriverWait(driver, 10).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'button[aria-label="Download Audio"]'))
    )
    download_link.click()
    print(f"Clicked: {download_link}")

download_dir = '/home/xertrov/Downloads'

def get_latest_downloaded_file(downloads_path):
    """
    Get the latest downloaded file from the Downloads directory.
    """
    # List all files in the Downloads directory and get their full paths
    files = [os.path.join(downloads_path, f) for f in os.listdir(downloads_path)]
    # Filter out directories, only keep files
    files = [f for f in files if os.path.isfile(f)]
    # Sort the files by modification time in descending order
    files.sort(key=lambda x: os.path.getmtime(x), reverse=True)
    # Return the first file in the list, which is the latest downloaded file
    if files:
        return files[0]
    else:
        return None

def wait_for_download_to_complete(downloads_path, timeout=30):
    """
    Wait for a new file to appear in the Downloads directory.
    """
    seconds = 0
    step = 0.1
    dl_wait = True
    latest_file = None
    while dl_wait and seconds < timeout:
        time.sleep(step)
        latest_file = get_latest_downloaded_file(downloads_path)
        if latest_file and latest_file.endswith(".mp3"):  # If there's an mp3 in the directory
            dl_wait = False
        seconds += step
    return latest_file


def wait_for_download_and_move(file_name: str):
    downloaded_file = wait_for_download_to_complete(download_dir)
    if downloaded_file:
        # Rename and move the file
        new_filename = output_path / file_name
        os.rename(downloaded_file, new_filename)
        print(f"File downloaded and moved from {downloaded_file} to {new_filename}")
    else:
        print("File download failed?")


def process_files(folder_path, output_path):
    files_completed = os.listdir(output_path)
    print(f"Files completed: {len(files_completed)} / {files_completed}")
    for i, file_name in enumerate(os.listdir(folder_path)):
        if file_name in files_completed:
            print(f"Skipping {file_name} as it already exists in the output directory")
            continue
        if file_name.endswith('.mp3'):
            file_path = os.path.join(folder_path, file_name)
            print(f"Processing {file_path}")
            # print(f"Press enter to continue")
            # input()
            reset_form_to_text_to_speech()
            # time.sleep(.1)  # Sleep for a short while to ensure the page has reset
            switch_to_speech_to_speech_mode()
            # time.sleep(.1)
            upload_file(file_path)
            print(f"Set upload file")
            time.sleep(0.2)
            # input("set upload, Press enter to continue")
            click_generate()
            print(f"wating for generation to complete")
            wait_for_generation_to_complete()
            print(f"generation complete, downloading")
            time.sleep(1)
            download_new_file()
            # hide_sound_bar()
            wait_for_download_and_move(file_name)
            driver.refresh()
        # if i > 1:
        #     print(f"debug breaking early")
        #     break

# Example usage:
folder_path = Path(sys.argv[1]).absolute()
output_path = Path(sys.argv[2]).absolute()

print(f"Processing MP3 files in {folder_path} and saving to {output_path}")
print(f"Please ensure the browser is open and on the correct page")
print(f"\nSet up any voice settings and things now")
print(f"\nPress enter to continue or Ctrl+C to cancel")
input()


process_files(folder_path, output_path)

# Don't forget to close the driver after the task is done
driver.quit()
