function result = fir_vna(root,mode,cfg)
% Single-channel measured-bypass calibration; exports MEM for manual transfer to PS.
assert(ismember(mode,[1 2]));N=cfg.tap_count;Fs=cfg.sample_rate_hz;
if mode==1
    h=zeros(N,1);h(1)=1;kind='bypass';
    result=struct('description','Unit impulse: calibration FIR H=1; interpolation remains active');
else
    [freq,H]=load_response(cfg.measurement_file);
    assert(min(freq)<=cfg.center_hz-100e6 && max(freq)>=cfg.center_hz+100e6,'Measurement must cover center +/-100 MHz');
    use=abs(freq-cfg.center_hz)<=100e6;f=freq(use)-cfg.center_hz;H=H(use);
    assert(numel(f)>=N,'Too few measured frequencies for this tap count');
    pass=abs(f)<=80e6;good=pass & abs(H)>0.05*max(abs(H(pass)));
    assert(nnz(good)>=3,'Insufficient valid passband response');
    ph=unwrap(angle(H));fit=polyfit(f(good),ph(good),1);bulk_delay=-fit(1)/(2*pi);
    % Keep the measured bulk transport delay. Fit only the residual channel.
    Hr=H.*exp(1j*2*pi*f*bulk_delay);
    mag=ones(size(f));tr=abs(f)>80e6;mag(tr)=0.5*(1+cos(pi*(abs(f(tr))-80e6)/20e6));
    delay=cfg.target_delay_samples;
    target=cfg.target_gain*mag.*exp(-1j*2*pi*f/Fs*delay);
    D=exp(-1j*2*pi*(f/Fs)*(0:N-1));A=Hr.*D;
    w=sqrt(max(mag,0.01));Aw=w.*A;bw=w.*target;
    lambda=cfg.regularization*real(trace(Aw'*Aw))/N;
    h=(Aw'*Aw+lambda*eye(N))\(Aw'*bw);
    max_gain=10^(cfg.max_gain_db/20);
    frequency_grid=(-4096:4095)'*Fs/8192;Dg=exp(-1j*2*pi*(frequency_grid/Fs)*(0:N-1));
    peak=max(abs(Dg*h));scale=min(1,max_gain/max(peak,eps));h=h*scale;
    result=struct('bulk_delay_seconds',bulk_delay,'added_delay_samples',delay,'gain_limit_scale',scale,'measurement_file',cfg.measurement_file);
    kind='compensated';
end
q=round([real(h),imag(h)]*2^16);
assert(all(isfinite(q(:))) && all(q(:)>=-2^17 & q(:)<=2^17-1),'Quantized coefficients exceed signed18; reduce target_gain');
out=fullfile(root,'matlab','vna','output',kind);if ~isfolder(out),mkdir(out);end
write_coe_file(fullfile(out,'fir_coef_re.coe'),q(:,1));write_coe_file(fullfile(out,'fir_coef_im.coe'),q(:,2));
write_fir_mem(fullfile(out,'h_re.mem'),q(:,1));write_fir_mem(fullfile(out,'h_im.mem'),q(:,2));
writematrix([(0:N-1)',q],fullfile(out,'taps.csv'));
if mode==2
    hq=complex(q(:,1),q(:,2))/2^16;G=D*hq;after=H.*G;
    target_raw=target.*exp(-1j*2*pi*f*bulk_delay);
    e=after-target_raw;
    result.passband_rms_error=sqrt(mean(abs(e(pass)).^2));
    result.quantized_peak_gain=max(abs(Dg*hq));
    writematrix([f+cfg.center_hz,real(H),imag(H),real(after),imag(after),real(target_raw),imag(target_raw)],fullfile(out,'response.csv'));
    if cfg.show_figures
        fig=figure('Name','FIR VNA measured bypass / quantized correction','Color','w');tiledlayout(2,1);
        nexttile;plot((f+cfg.center_hz)/1e9,20*log10(max(abs([H,after,target_raw]),1e-12)));grid on;legend('Measured bypass','After quantized FIR','Target');ylabel('Magnitude (dB)');xlabel('RF frequency (GHz)');
        nexttile;plot(f/1e6,unwrap(angle([Hr,Hr.*G,target]))*180/pi);grid on;legend('Bypass residual','After quantized FIR','Target');ylabel('Phase, bulk delay removed (deg)');xlabel('Baseband frequency (MHz)');
        exportgraphics(fig,fullfile(out,'response.png'),'Resolution',150);
    end
    fprintf('VNA: preserved bulk delay %.6g ns; quantized passband RMS error %.6g; gain-limit scale %.6g\n',bulk_delay*1e9,result.passband_rms_error,scale);
end
save(fullfile(out,'design.mat'),'h','q','result','cfg');
fprintf('VNA_MODE%d_READY: %s\nSelect vna_%s in MAIN mode 1 to use these COE files.\n',mode,out,kind);
end
function [f,H]=load_response(path)
assert(isfile(path),'Missing VNA measurement: %s',path);
[~,~,ext]=fileparts(path);
if strcmpi(ext,'.mat')
    d=load(path);
    if isfield(d,'freq_axis'),f=d.freq_axis(:);elseif isfield(d,'freq'),f=d.freq(:);else,error('MAT requires freq_axis in Hz');end
    if isfield(d,'vna_data'),H=d.vna_data(:);elseif isfield(d,'sdata_complex'),H=d.sdata_complex(:);else,error('MAT requires complex vna_data or sdata_complex');end
else
    d=readmatrix(path);assert(size(d,2)==3,'CSV columns: frequency_Hz, real_S21, imag_S21');f=d(:,1);H=complex(d(:,2),d(:,3));
end
assert(numel(f)==numel(H) && isreal(f) && all(isfinite(f)) && all(isfinite(H)),'Invalid VNA response');
[f,ix]=sort(f);H=H(ix);assert(all(diff(f)>0),'VNA frequencies must be unique');
end
