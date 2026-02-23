@echo off
REM run_sim.bat — Compile and simulate with Vivado xsim
REM Run from: TBL1\ directory
REM Usage: team_4_submission\run_sim.bat

REM Change to TBL1 directory (parent of team_4_submission)
cd /d "%~dp0.."

echo === Step 1: xvlog compile ===
xvlog -sv ^
  team_4_submission\polar_common_pkg.sv ^
  team_4_submission\polar64_crc16_encoder.sv ^
  team_4_submission\polar64_crc16_decoder.sv ^
  tb_basic.sv
if errorlevel 1 goto error

echo === Step 2: xelab ===
xelab tb_basic -debug typical -s sim_snapshot
if errorlevel 1 goto error

echo === Step 3: xsim ===
xsim sim_snapshot -runall
if errorlevel 1 goto error

goto end

:error
echo ERROR: Simulation failed.
exit /b 1

:end
