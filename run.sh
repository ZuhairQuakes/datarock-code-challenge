#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

export MPLBACKEND=Agg
export MPLCONFIGDIR="${MPLCONFIGDIR:-$PROJECT_DIR/.matplotlib-cache}"
export JUPYTER_CONFIG_DIR="${JUPYTER_CONFIG_DIR:-$PROJECT_DIR/.jupyter-config}"
export JUPYTER_DATA_DIR="${JUPYTER_DATA_DIR:-$PROJECT_DIR/.jupyter-data}"
export JUPYTER_RUNTIME_DIR="${JUPYTER_RUNTIME_DIR:-$PROJECT_DIR/.jupyter-runtime}"
export IPYTHONDIR="${IPYTHONDIR:-$PROJECT_DIR/.ipython}"

mkdir -p \
  "$MPLCONFIGDIR" \
  "$JUPYTER_CONFIG_DIR" \
  "$JUPYTER_DATA_DIR" \
  "$JUPYTER_RUNTIME_DIR" \
  "$IPYTHONDIR"

python3 -m jupyter nbconvert \
  --to notebook \
  --execute \
  --inplace \
  --ExecutePreprocessor.timeout=600 \
  --ExecutePreprocessor.kernel_name=python3 \
  nbtk/geochem_proximity_model.ipynb

echo "Analysis complete: output/predictions.csv"
