import urllib.request
import os

def download_voice():
    # Harvard Sentences female voice
    url = "https://www.signalogic.com/melp/Eng/f3.wav"
    output_path = "app/core/speaker_ref.wav"
    
    print(f"Downloading signature voice reference from {url}...")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    urllib.request.urlretrieve(url, output_path)
    print(f"Downloaded to {output_path}")

if __name__ == "__main__":
    download_voice()
