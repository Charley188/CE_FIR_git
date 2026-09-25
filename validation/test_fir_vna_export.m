function test_fir_vna_export(scratch)
% Verify the VNA-to-hardware sign convention and the downstream MAIN handoff.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab'),fullfile(root,'matlab/lib'));
if ~isfolder(scratch),mkdir(scratch);end
cfg=fir_config();cfg.show_figures=false;cfg.center_hz=1.2e9;
cfg.passband_hz=80e6;cfg.stopband_hz=90e6;
cfg.target_delay_samples=149;cfg.regularization=1e-4;cfg.max_gain_db=6;
f=linspace(-100e6,100e6,1001)';
freq_axis=f+cfg.center_hz;
vna_data=0.4*(1+0.15*cos(2*pi*f/cfg.sample_rate_hz*2)).*exp(0.4j-2j*pi*f/cfg.sample_rate_hz*20);
cfg.measurement_file=fullfile(scratch,'bypass_measurement.mat');
save(cfg.measurement_file,'freq_axis','vna_data');
math=fir_vna_design(f,vna_data,cfg);
assert(any(math.q(:,2)~=0),'Test requires nonzero imaginary coefficients');
expected=[math.q(:,1),-math.q(:,2)];
r=fir_vna(scratch,2,cfg);
out=fullfile(scratch,'matlab/vna/output/compensated');
assert(isequal(read_mem(fullfile(out,'h_re.mem')),mod(expected(:,1),2^18)));
assert(isequal(read_mem(fullfile(out,'h_im.mem')),mod(expected(:,2),2^18)),...
    'Hardware MEM must negate the mathematical imaginary taps');
assert(isequal(r.q,math.q) && isequal(r.q_hw,expected) && r.hardware_conjugated);
assert(isequal(r.predicted_response,math.predicted_response));
s=load(fullfile(out,'design.mat'));
assert(isequal(s.q,expected) && isequal(s.h,conj(math.h)));
assert(isequal(fir_read_coe(fullfile(out,'fir_coef_re.coe')),expected(:,1)));
assert(isequal(fir_read_coe(fullfile(out,'fir_coef_im.coe')),expected(:,2)));
assert(isequal(readmatrix(fullfile(out,'taps.csv')),[(0:299)',expected]));
r2=fir_vna(scratch,2,cfg);
assert(isequal(r2.q_hw,expected),'Repeated export must not conjugate twice');
cfg.coefficient_source='vna_compensated';cfg.base_samples=64;
if ~isfolder(fullfile(scratch,'coeff')),mkdir(fullfile(scratch,'coeff'));end
fir_run(scratch,1,cfg);
assert(isequal(read_mem(fullfile(scratch,'data/input/h_im.mem')),mod(expected(:,2),2^18)));
fir_vna(scratch,1,cfg);
bypass=fullfile(scratch,'matlab/vna/output/bypass');
assert(isequal(read_mem(fullfile(bypass,'h_re.mem')),[65536;zeros(299,1)]));
assert(all(read_mem(fullfile(bypass,'h_im.mem'))==0));
fprintf('PASS VNA conjugate export: MEM/COE/CSV/MAT agree; prediction preserved; repeat, MAIN handoff and bypass checked.\n');
end
function q=read_mem(path)
rows=strip(readlines(path));rows=rows(strlength(rows)>0);
assert(numel(rows)==300 && all(strlength(rows)==5));q=hex2dec(rows);
end
