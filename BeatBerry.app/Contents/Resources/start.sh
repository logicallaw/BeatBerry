#!/bin/bash

# Try to source Conda configuration from common locations
if [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
    source "/opt/anaconda3/etc/profile.d/conda.sh"
fi

# Fallback: hope conda is in PATH if sourcing failed
# Ensure we are in the script's directory so we can find gui.py
cd "$(dirname "$0")"

# Activate the environment
conda activate beatberry

# Run the GUI application
python gui.py