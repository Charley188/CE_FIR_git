% Single-channel VNA calibration. Edit MODE and settings, then click Run.
% 1: H=1 bypass COE/MEM. 2: measured bypass -> correction, FFT-style LS design.
MODE = 1;
matlab_dir = fileparts(mfilename('fullpath'));
addpath(matlab_dir,fullfile(matlab_dir,'lib'));
root = fileparts(matlab_dir);
cfg = fir_config();
cfg.measurement_file = ''; % MODE=2: empty opens a MAT/CSV selection dialog.
cfg.center_hz = 1.2e9; % Actual RF center; baseband = measured frequency - center.
cfg.passband_hz = 80e6;
cfg.stopband_hz = 90e6; % Guard band begins here; must be below Fs/2 = 100 MHz.
cfg.target_delay_samples = floor((cfg.tap_count-1)/2); % TOTAL target delay, not added delay.
cfg.regularization = 1e-4; % Same initial value and retry policy as FFT.
cfg.max_gain_db = 6;
% Target amplitude is the measured passband median, as in the FFT designer.
% No automatic bulk-delay removal. Inspect phase/ripple metrics for feasibility.
result = fir_vna(root,MODE,cfg);
