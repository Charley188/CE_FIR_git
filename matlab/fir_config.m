function cfg = fir_config()
% Branch hardware configuration. Changing tap_count also requires FIR IP/RTL changes.
cfg.tap_count=300;
cfg.sample_rate_hz=600e6;
cfg.samples_per_clock=2;
cfg.passband_hz=225e6; % Total useful passband 450 MHz, below RFDC's nominal 480 MHz.
cfg.stopband_hz=270e6;
cfg.coefficient_source='standard';
cfg.base_samples=2048;
cfg.amplitude_lsb=2048;
cfg.seed=300;
cfg.show_figures=true;
end
