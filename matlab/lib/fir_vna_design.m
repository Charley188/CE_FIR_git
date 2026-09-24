function result = fir_vna_design(f,g,cfg)
% Same finite-tap LS objective as CE_FFT_git/ce_vna; quantize TIME-domain taps.
% f is baseband Hz. Delay is the TOTAL target delay, as in the FFT designer.
N=cfg.tap_count;Fs=cfg.sample_rate_hz;
validateattributes(N,{'numeric'},{'scalar','integer','positive','<=',32768});
validateattributes(Fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(cfg.passband_hz,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(cfg.stopband_hz,{'numeric'},{'scalar','real','finite','positive'});
assert(cfg.passband_hz<cfg.stopband_hz && cfg.stopband_hz<Fs/2,'Require passband < stopband < Fs/2');
validateattributes(cfg.target_delay_samples,{'numeric'},{'scalar','integer','>=',0,'<',N});
validateattributes(cfg.regularization,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(cfg.max_gain_db,{'numeric'},{'scalar','real','finite'});
f=f(:);g=g(:);
assert(numel(f)==numel(g) && ~isempty(f) && isreal(f) && all(isfinite(f)) && all(isfinite(g)) && all(diff(f)>0),'Invalid complex frequency data');
assert(f(1)<=-cfg.passband_hz && f(end)>=cfg.passband_hz,'Measurement must cover requested passband');
pass=abs(f)<=cfg.passband_hz;fp=f(pass);gp=g(pass);
assert(numel(fp)>N && all(abs(gp)>1e-10),'Insufficient passband points / deep null');
target_gain=median(abs(gp));gp=gp/target_gain;
ix=unique(round(linspace(1,numel(fp),min(4097,numel(fp)))));fw=fp(ix);gw=gp(ix);
A=exp(-2j*pi*(fw/Fs)*(0:N-1));B=gw.*A;
desired=exp(-2j*pi*fw/Fs*cfg.target_delay_samples);
guardf=[linspace(-Fs/2,-cfg.stopband_hz,128),linspace(cfg.stopband_hz,Fs/2,128)]';
C=exp(-2j*pi*(guardf/Fs)*(0:N-1));
lambda=cfg.regularization*numel(fw);
for attempt=1:8
    h=[B;0.25*C;sqrt(lambda)*eye(N)]\[desired;zeros(numel(guardf)+N,1)];
    q=round([real(h),imag(h)]*65536);
    fits=all(isfinite(q(:))) && all(q(:)>=-131072 & q(:)<=131071);
    hq=complex(q(:,1),q(:,2))/65536;
    % FIR has no OLS tail. The tap-error L1 norm bounds response quantization error.
    quantized_error_l1=sum(abs(hq-h));
    peak_gain_db=20*log10(max(abs(fft(h,32768)))+quantized_error_l1);
    if fits && peak_gain_db<=cfg.max_gain_db,break;end
    if attempt<8,lambda=lambda*10;end
end
assert(fits && peak_gain_db<=cfg.max_gain_db,'Cannot fit tap range/gain limit; inspect measurement and settings');
D=exp(-2j*pi*(fp/Fs)*(0:N-1));
desired_full=exp(-2j*pi*fp/Fs*cfg.target_delay_samples);
float_predicted=gp.*(D*h);predicted=gp.*(D*hq);
e=predicted./desired_full;
level_db=20*log10(max(abs(e),realmin));
before_db=20*log10(abs(gp));
result=struct('mode',2,'cfg',cfg,'h',h,'hq',hq,'q',q,...
    'regularization_used',lambda/numel(fw),'attempts',attempt,...
    'target_gain',target_gain,'target_delay_samples',cfg.target_delay_samples,...
    'baseline_ripple_db',max(before_db)-min(before_db),...
    'predicted_ripple_db',max(level_db)-min(level_db),...
    'predicted_level_offset_db',median(level_db),...
    'predicted_max_amplitude_error_db',max(abs(level_db)),...
    'predicted_phase_error_deg',max(abs(angle(e)*180/pi)),...
    'passband_rms_error',target_gain*sqrt(mean(abs(predicted-desired_full).^2)),...
    'quantized_error_l1',quantized_error_l1,'peak_gain_db',peak_gain_db,...
    'quantized_peak_gain',max(abs(fft(hq,32768))),...
    'float_predicted_ripple_db',range(20*log10(max(abs(float_predicted),realmin))),...
    'frequency_baseband_hz',fp,'measured_response',g(pass),...
    'predicted_response',target_gain*predicted,'target_response',target_gain*desired_full);
end
