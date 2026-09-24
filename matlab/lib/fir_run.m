function result = fir_run(root,mode,cfg)
in_dir=fullfile(root,'data','input');out_dir=fullfile(root,'data','output');coeff_dir=fullfile(root,'coeff');
if ~isfolder(in_dir),mkdir(in_dir);end
if ~isfolder(out_dir),mkdir(out_dir);end
assert(ismember(mode,[1 2]),'Mode must be 1 or 2');
if mode==1
    switch cfg.coefficient_source
        case 'standard'
            if cfg.tap_count==45,d=fir_design_45();else,d=fir_design_300();end
            write_coe_file(fullfile(coeff_dir,'fir_coef_re.coe'),d.real_i18);
            write_coe_file(fullfile(coeff_dir,'fir_coef_im.coe'),d.imag_i18);
        case {'vna_bypass','vna_compensated'}
            kind=erase(cfg.coefficient_source,'vna_');
            src=fullfile(root,'matlab','vna','output',kind);
            for name={'fir_coef_re.coe','fir_coef_im.coe'}
                copyfile(fullfile(src,name{1}),fullfile(coeff_dir,name{1}));
            end
        case 'current'
            % Keep manually selected active COE files.
        otherwise,error('Unknown coefficient_source');
    end
    [cr,ci,interp]=load_coefficients(coeff_dir,cfg.tap_count);
    write_fir_mem(fullfile(in_dir,'h_re.mem'),cr);
    write_fir_mem(fullfile(in_dir,'h_im.mem'),ci);
    validateattributes(cfg.base_samples,{'numeric'},{'scalar','integer','>=',32});
    validateattributes(cfg.amplitude_lsb,{'numeric'},{'scalar','positive','<=',16000});
    stream=RandStream('mt19937ar','Seed',cfg.seed);
    z=complex(randn(stream,cfg.base_samples,1),randn(stream,cfg.base_samples,1));
    z=z*(cfg.amplitude_lsb/max([abs(real(z));abs(imag(z))]));
    z=complex(round(real(z)),round(imag(z)));
    hi=interpft(z,12*numel(z));x=[round(real(hi)),round(imag(hi))];
    nt=[interp.stage1.tap_count interp.stage2.tap_count interp.stage3.tap_count];
    tail=cfg.tap_count-1+ceil(((nt(1)-1)*4+(nt(2)-1)*2+nt(3)-1)/12);
    tail=tail+mod(cfg.base_samples+tail,2);
    x=[x;zeros(12*tail,2)];
    assert(all(x(:)>=-32768 & x(:)<=32767),'Stimulus exceeds signed16; reduce amplitude_lsb');
    assert(size(x,1)<=1048576,'Stimulus exceeds TB capacity');
    writematrix(x(:,1),fullfile(in_dir,'input_2400_i.txt'));
    writematrix(x(:,2),fullfile(in_dir,'input_2400_q.txt'));
    fid=fopen(fullfile(in_dir,'config.txt'),'wt');assert(fid>=0);fprintf(fid,'%d\n',size(x,1));fclose(fid);
    result=struct('samples',size(x,1),'tap_count',cfg.tap_count);
    fprintf('MODE1_READY: %d ADC samples, %d taps.\nCOE: %s\nInput: %s\n',size(x,1),cfg.tap_count,coeff_dir,in_dir);
    fprintf('Online FIR MEM: %s. Manually copy h_re.mem / h_im.mem to ps/src/coeff, then Vitis Clean > Build > Run.\n',in_dir);
    fprintf('Integer coefficient symmetry: real=%d imag=%d (1=symmetric).\n',isequal(cr,flipud(cr)),isequal(ci,flipud(ci)));
    fprintf('Fixed reloadable IP: 300 taps, non-symmetric, 48-bit AXI output. No IP regeneration when changing taps.\n');
    if cfg.show_figures
        figure('Name','FIR mode 1: coefficients and stimulus','Color','w');tiledlayout(2,1);
        nexttile;plot(cr/2^16);hold on;plot(ci/2^16);grid on;legend('Real taps','Imag taps');xlabel('Tap');
        nexttile;plot(x(1:min(256,end),:));grid on;legend('I','Q');xlabel('ADC sample');ylabel('LSB');
    end
else
    [cr,ci,interp]=load_coefficients(coeff_dir,cfg.tap_count);
    x=[readmatrix(fullfile(in_dir,'input_2400_i.txt')),readmatrix(fullfile(in_dir,'input_2400_q.txt'))];
    assert(size(x,2)==2 && all(isfinite(x(:))) && all(x(:)==fix(x(:))) && all(x(:)>=-32768 & x(:)<=32767));
    ns=readmatrix(fullfile(in_dir,'config.txt'));assert(isscalar(ns) && ns==size(x,1) && mod(ns,24)==0,'Invalid input count');
    ref=fir_reference(x,cr,ci,interp);
    result=fir_compare(ref,out_dir,cfg.show_figures);
end
end
function [cr,ci,interp]=load_coefficients(dir,n)
cr=fir_read_coe(fullfile(dir,'fir_coef_re.coe'));ci=fir_read_coe(fullfile(dir,'fir_coef_im.coe'));
assert(numel(cr)==n && numel(ci)==n,'COE tap count does not match this branch');
interp=fir_interpolation(dir);
end
