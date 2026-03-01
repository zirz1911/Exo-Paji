#!/bin/bash
# EXO-PAJI Safe Startup Script for M4 Macs
# Fixes force logout/crash issue on macOS 26.x + M4

set -e  # Exit on error

echo "🚀 Starting EXO-PAJI in Safe Mode for M4..."
echo ""

# ===================================
# Environment Variables (M4 Fixes)
# ===================================

# MLX_DISABLE_METAL_CACHE=1
#   → แก้ปัญหา Metal Performance Shaders cache ที่อาจ leak memory
#   → บน M4 ใหม่อาจมี compatibility issue กับ aggressive caching
export MLX_DISABLE_METAL_CACHE=1

# PYTHONPATH fix: uv venv + Python 3.13 does not process .pth files correctly
# exo uses src/ layout with editable install via .pth — must add manually
export PYTHONPATH="/Users/paji/Desktop/Paji/Exo-Paji/src${PYTHONPATH:+:$PYTHONPATH}"

# MLX_MEMORY_LIMIT (Optional - uncomment if needed)
#   → จำกัด memory ที่ MLX ใช้ได้ (ป้องกัน memory pressure)
#   → ตัวอย่าง: 8GB = 8589934592 bytes
# export MLX_MEMORY_LIMIT=8589934592

echo "✓ Environment variables set:"
echo "  - MLX_DISABLE_METAL_CACHE=1"
echo "  - PYTHONPATH=src/ (pth fix)"
# echo "  - MLX_MEMORY_LIMIT=8GB"
echo ""

# ===================================
# EXO Startup Flags
# ===================================
# --no-fast-synch : ปิด MLX FAST_SYNCH → ลด GPU overhead
# --offline       : ไม่ download/sync models อัตโนมัติ → ลด network/memory load

echo "🎯 Starting EXO with safe flags:"
echo "  - --no-fast-synch (reduce GPU overhead)"
echo "  - --offline (single-node mode)"
echo ""

# Start EXO
uv run exo --no-fast-synch --offline "$@"

# Note: "$@" allows passing additional arguments
# Example: ./start-exo-safe.sh -vv (enable verbose logging)
