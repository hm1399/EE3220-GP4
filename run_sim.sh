#!/bin/bash
# run_sim.sh — Compile and simulate with Vivado xsim
# Run from: /Users/mandy/Documents/GitHub/EE3220-GP4/TBL1/
# Usage: bash team_4_submission/run_sim.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TBL1_DIR="$(dirname "$SCRIPT_DIR")"

cd "$TBL1_DIR"

echo "=== Step 1: xvlog compile ==="
xvlog -sv \
  polar_common_pkg.sv \
  polar64_crc16_encoder.sv \
  polar64_crc16_decoder.sv \
  tb_basic.sv

echo "=== Step 2: xelab ==="
xelab tb_basic -debug typical -s sim_snapshot

echo "=== Step 3: xsim ==="
xsim sim_snapshot -runall
