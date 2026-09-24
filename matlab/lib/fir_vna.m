function result = fir_vna(root,mode,cfg)
% Single-channel FIR VNA design; manual MEM transfer to PS only.
assert(ismember(mode,[1 2]),'MODE must be 1 or 2');
assert(cfg.tap_count==300 && cfg.sample_rate_hz==200e6,'This hardware requires 300 taps at 200 MSPS');
N=cfg.tap_count;
if mode==1
    h=zeros(N,1);h(1)=1;q=[round(real(h)*65536),round(imag(h)*65536)];kind='bypass';
    result=struct('mode',1,'description','Unit impulse: calibration FIR H=1; interpolation remains active');
else
    if strlength(string(cfg.measurement_file))==0
        [name,folder]=uigetfile({'*.mat;*.csv','VNA complex response (.mat/.csv)'});
        assert(~isequal(name,0),'No VNA file selected');cfg.measurement_file=fullfile(folder,name);
    end
    validateattributes(cfg.center_hz,{'numeric'},{'scalar','real','finite'});
    [freq,H]=load_response(cfg.measurement_file);
    result=fir_vna_design(freq-cfg.center_hz,H,cfg);
    h=result.h;q=result.q;kind='compensated';
end
out=fullfile(root,'matlab','vna','output',kind);if ~isfolder(out),mkdir(out);end
write_coe_file(fullfile(out,'fir_coef_re.coe'),q(:,1));write_coe_file(fullfile(out,'fir_coef_im.coe'),q(:,2));
write_fir_mem(fullfile(out,'h_re.mem'),q(:,1));write_fir_mem(fullfile(out,'h_im.mem'),q(:,2));
writematrix([(0:N-1)',q],fullfile(out,'taps.csv'));
if mode==2
    f=result.frequency_baseband_hz;H=result.measured_response;
    after=result.predicted_response;target=result.target_response;
    % Same seven columns as before, now restricted to the fitted passband.
    writematrix([f+cfg.center_hz,real(H),imag(H),real(after),imag(after),real(target),imag(target)],fullfile(out,'response.csv'));
    fid=fopen(fullfile(out,'metrics.txt'),'wt');assert(fid>=0);
    cleaner=onCleanup(@()fclose(fid));
    names={'target_gain','target_delay_samples','regularization_used','attempts',...
        'baseline_ripple_db','predicted_ripple_db','predicted_level_offset_db',...
        'predicted_max_amplitude_error_db','predicted_phase_error_deg',...
        'passband_rms_error','quantized_error_l1','peak_gain_db','quantized_peak_gain'};
    for k=1:numel(names),fprintf(fid,'%s=%.12g\n',names{k},result.(names{k}));end
    clear cleaner;
    if cfg.show_figures
        fig=figure('Name','FIR VNA: measured bypass / quantized correction','Color','w');tiledlayout(2,1);
        nexttile;plot(f/1e6,20*log10(max(abs([H,after,target])/result.target_gain,1e-12)));
        grid on;legend('Measured bypass','Quantized prediction','Target');ylabel('Relative magnitude (dB)');xlabel('Baseband frequency (MHz)');
        nexttile;plot(f/1e6,angle(after./target)*180/pi);grid on;
        ylabel('Residual phase vs target delay (deg)');xlabel('Baseband frequency (MHz)');
        exportgraphics(fig,fullfile(out,'response.png'),'Resolution',150);
    end
    fprintf('VNA prediction: ripple %.6g -> %.6g dB; level offset %.6g dB; phase error %.6g deg.\n',...
        result.baseline_ripple_db,result.predicted_ripple_db,result.predicted_level_offset_db,result.predicted_phase_error_deg);
    fprintf('Target gain %.6g; total target delay %d samples; regularization %.6g (%d attempts); peak bound %.6g dB.\n',...
        result.target_gain,result.target_delay_samples,result.regularization_used,result.attempts,result.peak_gain_db);
    fprintf('Prediction uses quantized taps. Confirm actual correction by remeasuring S21.\n');
end
save(fullfile(out,'design.mat'),'h','q','result','cfg');
fprintf('VNA_MODE%d_READY: %s\nSelect vna_%s in MAIN mode 1 for digital verification.\nManually copy the two MEM files to PS; Clean > Build > Run.\n',mode,out,kind);
end
function [f,H]=load_response(path)
assert(isfile(path),'Missing VNA measurement: %s',path);
[~,~,ext]=fileparts(path);
if strcmpi(ext,'.mat')
    d=load(path);
    if isfield(d,'freq_axis'),f=d.freq_axis(:);elseif isfield(d,'freq'),f=d.freq(:);else,error('MAT requires freq_axis in Hz');end
    if isfield(d,'vna_data'),H=d.vna_data(:);elseif isfield(d,'sdata_complex'),H=d.sdata_complex(:);else,error('MAT requires complex vna_data or sdata_complex');end
elseif strcmpi(ext,'.csv')
    d=readmatrix(path);assert(size(d,2)==3,'CSV columns: frequency_Hz, real_S21, imag_S21');f=d(:,1);H=complex(d(:,2),d(:,3));
else
    error('Supported files: MAT or CSV');
end
assert(numel(f)==numel(H) && isreal(f) && all(isfinite(f)) && all(isfinite(H)),'Invalid VNA response');
[f,ix]=sort(f);H=H(ix);assert(all(diff(f)>0),'VNA frequencies must be unique');
end
