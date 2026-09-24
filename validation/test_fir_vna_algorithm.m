function test_fir_vna_algorithm(fft_root,scratch)
% Development regression. All generated files stay in the supplied scratch directory.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab'),fullfile(root,'matlab','lib'),fullfile(fft_root,'matlab','lib'));
if ~isfolder(scratch),mkdir(scratch);end
cfg=fir_config();cfg.show_figures=false;cfg.center_hz=1.2e9;
cfg.passband_hz=80e6;cfg.stopband_hz=90e6;cfg.target_delay_samples=149;
cfg.regularization=1e-4;cfg.max_gain_db=6;
f=linspace(-100e6,100e6,1001)';Fs=cfg.sample_rate_hz;
g=0.4*(1+0.25*cos(2*pi*f/Fs*3)).*exp(0.3j*sin(2*pi*f/Fs*2)).*exp(-2j*pi*f/Fs*20);
% Compare floating-tap design against the ACTUAL unmodified FFT function.
% Scale frequencies by 12 and use its maximum 257 taps so normalized problems match.
cmp=cfg;cmp.tap_count=257;cmp.target_delay_samples=128;
a=fir_vna_design(f,g,cmp);assert(a.attempts==1);
freq_axis=f*12;vna_data=g;ref_file=fullfile(scratch,'fft_equivalence.mat');save(ref_file,'freq_axis','vna_data');
fft_cfg=struct('center_hz',0,'passband_hz',cfg.passband_hz*12,'stopband_hz',cfg.stopband_hz*12,...
    'tap_count',257,'delay_samples',128,'regularization',cfg.regularization,'max_gain_db',6,...
    'file',ref_file,'output_dir',fullfile(scratch,'fft_reference_output'),'plots',false);
b=ce_vna(2,fft_cfg);
assert(max(abs(a.h-b.h))<1e-10,'Floating design differs from actual FFT implementation');
assert(abs(a.target_gain-b.target_gain)<1e-12 && a.regularization_used==b.regularization_used);
fprintf('PASS unmodified FFT equivalence: max tap difference %.12g\n',max(abs(a.h-b.h)));
% Flat attenuated channel: preserve its level rather than force absolute 0 dB.
flat=0.1*exp(-2j*pi*f/Fs*20);s=fir_vna_design(f,flat,cfg);
assert(abs(s.target_gain-0.1)<1e-12 && s.predicted_ripple_db<0.1 && abs(s.predicted_level_offset_db)<0.1);
fprintf('PASS flat -20 dB: ripple %.6g dB, level offset %.6g dB\n',s.predicted_ripple_db,s.predicted_level_offset_db);
% Known smooth amplitude/phase distortion; check all 300 quantized taps.
r=fir_vna_design(f,g,cfg);
assert(r.predicted_ripple_db<0.1 && r.predicted_ripple_db<r.baseline_ripple_db/10);
assert(r.predicted_phase_error_deg<1 && size(r.q,1)==300);
assert(all(r.q(:)>=-131072 & r.q(:)<=131071));
fprintf('PASS ripple correction: %.6g -> %.6g dB; phase %.6g deg\n',r.baseline_ripple_db,r.predicted_ripple_db,r.predicted_phase_error_deg);
% Strong notch requires regularization retries; cap is checked AFTER quantization.
notch=0.6*(1-0.98*exp(-(f/12e6).^2)).*exp(-2j*pi*f/Fs*20);
t=fir_vna_design(f,notch,cfg);assert(t.attempts>1 && t.peak_gain_db<=cfg.max_gain_db);
assert(20*log10(t.quantized_peak_gain)<=cfg.max_gain_db);
fprintf('PASS gain retry: attempts %d; bound %.6g dB; remaining ripple %.6g dB\n',t.attempts,t.peak_gain_db,t.predicted_ripple_db);
% Impossible constraints and malformed inputs must be rejected.
bad=cfg;bad.max_gain_db=-300;must_fail(@()fir_vna_design(f,g,bad));
must_fail(@()fir_vna_design([f(1);f], [g(1);g], cfg));
must_fail(@()fir_vna_design(f(1:5:end),g(1:5:end),cfg));
% Bypass export and both MAT/CSV input routes, without accessing PS directories.
export_root=fullfile(scratch,'export');freq_axis=f+cfg.center_hz;vna_data=g;
cfg.measurement_file=fullfile(scratch,'bypass.mat');save(cfg.measurement_file,'freq_axis','vna_data');
fir_vna(export_root,1,cfg);
re=read_hex(fullfile(export_root,'matlab','vna','output','bypass','h_re.mem'));
im=read_hex(fullfile(export_root,'matlab','vna','output','bypass','h_im.mem'));
assert(isequal(re,[65536;zeros(299,1)]) && all(im==0));
u=fir_vna(export_root,2,cfg);
base=fullfile(export_root,'matlab','vna','output','compensated');
assert(isequal(read_hex(fullfile(base,'h_re.mem')),mod(u.q(:,1),2^18)));
assert(isequal(read_hex(fullfile(base,'h_im.mem')),mod(u.q(:,2),2^18)));
rows=readmatrix(fullfile(base,'response.csv'));assert(size(rows,2)==7 && size(rows,1)==nnz(abs(f)<=cfg.passband_hz));
cfg.measurement_file=fullfile(scratch,'bypass.csv');writematrix([freq_axis,real(g),imag(g)],cfg.measurement_file);
v=fir_vna(export_root,2,cfg);assert(isequal(u.q,v.q));
% A total delay outside the available causal span must not look like a successful calibration.
long=fir_vna_design(f,0.5*exp(-2j*pi*f/Fs*400),cfg);
assert(abs(long.predicted_level_offset_db)>1 || long.predicted_ripple_db>1 || long.predicted_phase_error_deg>5);
fprintf('PASS infeasible-delay diagnostics: ripple %.6g dB; level %.6g dB; phase %.6g deg\n',long.predicted_ripple_db,long.predicted_level_offset_db,long.predicted_phase_error_deg);
fprintf('PASS VNA ALGORITHM: FFT equivalence, 300tap quantization, retries, input validation, exports and delay diagnostics\n');
end
function values=read_hex(path)
lines=strip(readlines(path));lines=lines(strlength(lines)>0);assert(numel(lines)==300 && all(strlength(lines)==5));values=hex2dec(lines);
end
function must_fail(fn)
failed=false;try,fn();catch,failed=true;end
assert(failed,'Expected invalid/unachievable input to be rejected');
end
