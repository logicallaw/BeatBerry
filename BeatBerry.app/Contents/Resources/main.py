import os
import sys
from pydub import AudioSegment
import argparse

# Define fixed directories for input and output
# Uses the user's Downloads folder
INPUT_DIR = os.path.expanduser('~/Downloads')
OUTPUT_DIR = os.path.join(INPUT_DIR, 'outputs')

def convert_m4a_to_mp3():
    """
    Converts all .m4a files in the INPUT_DIR to .mp3 format 
    and saves them in the OUTPUT_DIR.
    
    Requires FFmpeg to be installed and accessible (e.g., via Conda).
    """
    
    parser = argparse.ArgumentParser(description="Convert .m4a files in INPUT_DIR to .mp3 format.")
    parser.add_argument("--clean", action="store_true")
    parser.add_argument("--prefix", type=str)
    args = parser.parse_args()

    clean_mode = args.clean

    print(f"--- M4A to MP3 Converter Starting ---")
    
    # Check if the inputs directory exists
    if not os.path.isdir(INPUT_DIR):
        print(f"Error: Input directory '{INPUT_DIR}' not found.")
        print(f"Please create an '{INPUT_DIR}' folder and place your .m4a files inside.")
        sys.exit(1)
        
    # Create the output directory if it doesn't exist
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Get the list of all .m4a files in the input directory
    try:
        m4a_files = [f for f in os.listdir(INPUT_DIR) if f.lower().endswith('.m4a')]
    except Exception as e:
        print(f"Error: Could not read files from '{INPUT_DIR}'. Details: {e}")
        sys.exit(1)

    if not m4a_files:
        print(f"Warning: No .m4a files found in the '{INPUT_DIR}' directory.")
        return

    print(f"Found a total of {len(m4a_files)} .m4a files. Starting conversion...")

    for m4a_file in m4a_files:
        if clean_mode:
            clean_name = m4a_file.replace(args.prefix, "")
            print(f"-> Converting {clean_name} (cleaned)...")
        else:
            clean_name = m4a_file
        input_path = os.path.join(INPUT_DIR, m4a_file)
        # Create the new MP3 filename (changing the extension only)
        # Slicing [:-4] removes the last 4 characters, which is usually '.m4a'
        mp3_filename = clean_name[:-4] + '.mp3'
        output_path = os.path.join(OUTPUT_DIR, mp3_filename)
        
        try:
            # Load the m4a file
            audio = AudioSegment.from_file(input_path, format="m4a")
            
            # Export to mp3 (using a common bitrate like 192k)
            # FFmpeg is required for this step to work.
            audio.export(output_path, format="mp3", bitrate="192k") 
            
            print(f"   Successfully converted and saved to '{output_path}'")
            
        except FileNotFoundError:
             # This specific error usually means FFmpeg is not found/accessible
            print(f"   Error: FFmpeg not found or not accessible. Make sure it is installed in your environment.")
            print(f"   (Conversion of {m4a_file} failed.)")
            sys.exit(1)
            
        except Exception as e:
            print(f"   Error: Failed to convert {m4a_file}. (Details: {e})")

    print("\nAll conversion tasks completed.")
    print(f"--- Results saved in the '{OUTPUT_DIR}' directory. ---")

if __name__ == "__main__":
    convert_m4a_to_mp3()