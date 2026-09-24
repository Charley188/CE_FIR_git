% MAIN: edit MODE, then click Run. No external runner is needed.
% 1: generate active COE/MEM + ADC input. 2: fixed-point model + FPGA comparison.
MODE = 1;
COEFFICIENT_SOURCE = 'standard'; % standard | current | vna_bypass | vna_compensated
BASE_SAMPLES = 2048;
AMPLITUDE_LSB = 2048;

matlab_dir = fileparts(mfilename('fullpath'));
addpath(matlab_dir,fullfile(matlab_dir,'lib'));
root = fileparts(matlab_dir);
cfg = fir_config();
cfg.coefficient_source = COEFFICIENT_SOURCE;
cfg.base_samples = BASE_SAMPLES;
cfg.amplitude_lsb = AMPLITUDE_LSB;
result = fir_run(root,MODE,cfg);
