# 🍓 BeatBerry

**BeatBerry** is a simple and powerful **Universal Audio Converter**.
Convert audio files (MP3, WAV, FLAC, M4A, etc.) quickly and easily.

## 🔑 Key Features
- **Intuitive GUI**: Easy click-based operation.
- **Multi-format Support**: MP3, WAV, FLAC, OGG, M4A.
- **Flexible Input**: Select individual files or entire folders.
- **Easy Execution**: Just run the `BeatBerry` app.

## 📋 Prerequisites
- **macOS**
- **Anaconda** (or Miniconda)
- **FFmpeg** (Installed automatically via Conda)

## 🚀 Installation

### 1. Download
Clone the repository:
```bash
git clone https://github.com/yourusername/beatberry.git
cd beatberry
```

### 2. Setup Conda Environment
Create the `beatberry` environment (required once):
```bash
conda env create -f environment.yml
```

## 📖 How to Use

### Method A: Run App (Recommended)
1. Double-click the **`BeatBerry`** app.
2. Select files and click **`START CONVERSION`**.

### Method B: Alternative
- If the app fails to open, double-click **`Run.command`**.

### Method C: Developer (Terminal)
```bash
conda activate beatberry
python gui.py
```

## 🔧 Troubleshooting
- **"App is damaged/cannot be opened"**: Allow the app in System Settings > Privacy & Security, or use `Run.command`.
- **"conda not found"**: Ensure Anaconda/Miniconda is installed.

## 💻 Development
To update the app after modifying code:
1. Modify `gui.py` or other source files.
2. Run the rebuild script:
   ```bash
   ./rebuild_app.sh
   ```
3. The `BeatBerry` app is now updated.

## 📝 Questions or Support
If you have any questions or need support, feel free to open an issue on GitHub or reach out via the following contact methods:

 - Email: logicallawbio@gmail.com
 - GitHub: logicallaw
