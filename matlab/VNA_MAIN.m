% Single-channel VNA calibration. Edit MODE and measurement path, then click Run.
% 1: H=1 bypass COE/MEM. 2: measured bypass -> quantized correction COE/MEM.
MODE = 1;
matlab_dir = fileparts(mfilename('fullpath'));
addpath(matlab_dir,fullfile(matlab_dir,'lib'));
root = fileparts(matlab_dir);
cfg = fir_config();
cfg.measurement_file = fullfile(matlab_dir,'vna','input','bypass.mat');
cfg.center_hz = 1.2e9;
cfg.target_delay_samples = floor((cfg.tap_count-1)/2);
cfg.target_gain = 1;
cfg.regularization = 1e-6;
cfg.max_gain_db = 12;
result = fir_vna(root,MODE,cfg);
