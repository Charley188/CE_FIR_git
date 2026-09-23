function cfg = fir_config()
% Branch hardware configuration. Changing tap_count also requires FIR IP/RTL changes.
cfg.tap_count=45;
cfg.sample_rate_hz=200e6;
cfg.coefficient_source='standard';
cfg.base_samples=2048;
cfg.amplitude_lsb=2048;
cfg.seed=300;
cfg.show_figures=true;
end
