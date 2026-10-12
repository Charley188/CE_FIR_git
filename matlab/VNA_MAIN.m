% Single-channel VNA calibration. Edit MODE and settings, then click Run.
% 1: H=1 bypass COE/MEM. 2: measured bypass -> correction, FFT-style LS design.
% Select a unit-impulse FIR measurement made with the DAC-clock version.
% Re-estimate total target delay for the selected measurement before acceptance.
MODE = 2;
matlab_dir = fileparts(mfilename('fullpath'));
addpath(matlab_dir,fullfile(matlab_dir,'lib'));
root = fileparts(matlab_dir);
cfg = fir_config();
cfg.measurement_file = ''; % MODE=2 opens a MAT/CSV file selection dialog.
cfg.center_hz = 1.2e9; % Actual RF center; baseband = measured frequency - center.
% Passband/stopband default to +/-225 / +/-270 MHz in fir_config.m.
% Override them here if needed; stopband_hz must remain below Fs/2 = 300 MHz.
% Latest impulse-FIR baseline: bulk delay 840.579819 samples at 600 MSPS.
% Total target 990 adds 149.420181 causal FIR samples (~249.034 ns).
% Re-estimate this value for a different measurement; do not reuse blindly.
cfg.target_delay_samples = 990; % TOTAL target delay, not added delay.
cfg.regularization = 1e-4; % Same initial value and retry policy as FFT.
cfg.max_gain_db = 6;
% User confirmed this convention on this 600 MSPS board (2026-10-10).
% Applied exactly once at export. Do not negate the exported MEM again.
cfg.hardware_conjugate = true;
% Target amplitude is the measured passband median, as in the FFT designer.
% No automatic bulk-delay removal. Inspect phase/ripple metrics for feasibility.
result = fir_vna(root,MODE,cfg);
