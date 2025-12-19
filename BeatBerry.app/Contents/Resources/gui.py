import os
import sys
import threading
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from pydub import AudioSegment

# Supported formats for conversion
FORMATS = ["mp3", "wav", "flac", "ogg", "m4a"]

class AudioConverterApp:
    def __init__(self, root):
        self.root = root
        self.root.title("BeatBerry 🍓 Audio Converter")
        self.root.geometry("700x450")
        
        # Variables
        self.selected_files = []
        self.output_dir = tk.StringVar()
        self.target_format = tk.StringVar(value="mp3")
        
        # UI Setup
        self.create_widgets()
        
    def create_widgets(self):
        # 1. File Selection Section
        frame_input = tk.LabelFrame(self.root, text="Input Selection", padx=10, pady=10)
        frame_input.pack(fill="x", padx=10, pady=5)
        
        btn_files = tk.Button(frame_input, text="Select Files...", command=self.select_files)
        btn_files.pack(side="left", padx=5)
        
        btn_folder = tk.Button(frame_input, text="Select Folder...", command=self.select_folder)
        btn_folder.pack(side="left", padx=5)
        
        btn_clear = tk.Button(frame_input, text="Clear", command=self.clear_selection)
        btn_clear.pack(side="right", padx=5)
        
        self.lbl_count = tk.Label(frame_input, text="No files selected")
        self.lbl_count.pack(side="left", padx=20)

        # 2. Options Section
        frame_opts = tk.LabelFrame(self.root, text="Conversion Options", padx=10, pady=10)
        frame_opts.pack(fill="x", padx=10, pady=5)
        
        # Format Selection
        tk.Label(frame_opts, text="Target Format:").pack(side="left")
        combo = ttk.Combobox(frame_opts, textvariable=self.target_format, values=FORMATS, width=10, state="readonly")
        combo.pack(side="left", padx=5)
        
        # Output Folder Selection
        tk.Label(frame_opts, text="Output Folder:").pack(side="left", padx=(20, 0))
        self.entry_out = tk.Entry(frame_opts, textvariable=self.output_dir, width=20, state="readonly")
        self.entry_out.pack(side="left", padx=5)
        tk.Button(frame_opts, text="Browse...", command=self.select_output_dir).pack(side="left")

        # 3. Action Section
        frame_action = tk.Frame(self.root, pady=10)
        frame_action.pack(fill="x", padx=10)
        
        self.btn_convert = tk.Button(frame_action, text="START CONVERSION", bg="#4CAF50", fg="black", font=("Arial", 12, "bold"), command=self.start_conversion_thread)
        self.btn_convert.pack(fill="x")

        # 4. Log Section
        frame_log = tk.LabelFrame(self.root, text="Progress Log", padx=5, pady=5)
        frame_log.pack(fill="both", expand=True, padx=10, pady=5)
        
        self.text_log = tk.Text(frame_log, height=10, state="disabled", font=("Courier New", 12))
        self.text_log.pack(fill="both", expand=True)
        
    def log(self, message):
        self.text_log.config(state="normal")
        self.text_log.insert("end", message + "\n")
        self.text_log.see("end")
        self.text_log.config(state="disabled")

    def select_files(self):
        files = filedialog.askopenfilenames(title="Select Audio Files")
        if files:
            self.selected_files.extend(files)
            # Remove duplicates
            self.selected_files = list(set(self.selected_files))
            self.update_count()
            
    def select_folder(self):
        folder = filedialog.askdirectory(title="Select Folder containing Audio")
        if folder:
            # Walk through folder and find audio files
            count = 0
            for root, _, files in os.walk(folder):
                for file in files:
                    # Check common extensions
                    if file.lower().endswith(('.m4a', '.mp3', '.wav', '.flac', '.ogg', '.wma')):
                        full_path = os.path.join(root, file)
                        self.selected_files.append(full_path)
                        count += 1
            self.selected_files = list(set(self.selected_files))
            self.update_count()
            self.log(f"Added {count} files from folder: {folder}")

    def clear_selection(self):
        self.selected_files = []
        self.update_count()
        self.log("Selection cleared.")

    def update_count(self):
        self.lbl_count.config(text=f"{len(self.selected_files)} files selected")

    def select_output_dir(self):
        folder = filedialog.askdirectory(title="Select Output Folder")
        if folder:
            self.output_dir.set(folder)

    def start_conversion_thread(self):
        if not self.selected_files:
            messagebox.showwarning("No Files", "Please select files to convert first.")
            return
            
        # Run in separate thread to keep UI responsive
        threading.Thread(target=self.convert_files, daemon=True).start()

    def convert_files(self):
        self.btn_convert.config(state="disabled", text="Converting...")
        target_fmt = self.target_format.get()
        out_root = self.output_dir.get()
        
        success_count = 0
        fail_count = 0
        
        self.log(f"--- Starting Batch Conversion to .{target_fmt} ---")
        
        for idx, file_path in enumerate(self.selected_files):
            try:
                fname = os.path.basename(file_path)
                self.log(f"[{idx+1}/{len(self.selected_files)}] Processing: {fname}")
                
                # Determine output path
                if out_root:
                    save_dir = out_root
                else:
                    # Default: create 'outputs' folder in the source file's directory
                    save_dir = os.path.join(os.path.dirname(file_path), "outputs")
                
                if not os.path.exists(save_dir):
                    os.makedirs(save_dir)
                    
                base_name = os.path.splitext(fname)[0]
                out_path = os.path.join(save_dir, f"{base_name}.{target_fmt}")
                
                # Load and Export
                # Note: pydub relies on ffmpeg for most formats
                audio = AudioSegment.from_file(file_path)
                audio.export(out_path, format=target_fmt)
                
                self.log(f"  -> Saved: {out_path}")
                success_count += 1
                
            except Exception as e:
                self.log(f"  -> ERROR: {str(e)}")
                fail_count += 1
        
        self.log("--- Conversion Completed ---")
        self.log(f"Success: {success_count}, Failed: {fail_count}")
        messagebox.showinfo("Done", f"Conversion Finished!\nSuccess: {success_count}\nFailed: {fail_count}")
        self.btn_convert.config(state="normal", text="START CONVERSION")
        self.selected_files = [] # Optional: clear after done
        self.update_count()

if __name__ == "__main__":
    root = tk.Tk()
    app = AudioConverterApp(root)
    root.mainloop()
