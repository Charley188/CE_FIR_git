function report = fir_compare(ref,out_dir,show_figures)
status=fileread(fullfile(out_dir,'tb_status.txt'));
assert(startsWith(strtrim(status),'PASS '),'TB did not complete successfully');
names={'decimator','fir','dac'};report=struct();pass=true;
for k=1:numel(names)
    name=names{k};d=read_rows(fullfile(out_dir,[name '.txt']),3);expected=ref.(name);
    assert(size(d,1)==size(expected,1),'Wrong %s output length',name);
    assert(isequal(d(:,1),(0:size(d,1)-1).'),'Invalid %s sample order',name);
    err=d(:,2:3)-expected;
    report.(name)=struct('samples',size(d,1),'max_error_lsb',max(abs(err(:))),'rms_error_lsb',sqrt(mean(err(:).^2)),'first_mismatch',find(any(err~=0,2),1)-1);
    pass=pass && all(err(:)==0);
    fprintf('%s: samples=%d max_error=%g LSB RMS=%g LSB\n',name,size(d,1),report.(name).max_error_lsb,report.(name).rms_error_lsb);
    if strcmp(name,'dac'),actual=d(:,2:3);dac_error=err;end
end
beats=read_rows(fullfile(out_dir,'dac_beats.txt'),17);
assert(isequal(beats(:,1),(0:size(beats,1)-1).'),'Invalid beat order');
unpacked=reshape(beats(:,2:end).',2,[]).';
assert(isequal(unpacked,actual),'DAC beat lane order does not match scalar output');
report.pass=pass;save(fullfile(out_dir,'comparison.mat'),'report','ref','actual');
fid=fopen(fullfile(out_dir,'comparison.txt'),'wt');assert(fid>=0);
fprintf(fid,'PASS=%d\n',pass);
for k=1:numel(names),s=report.(names{k});fprintf(fid,'%s samples=%d max_error_lsb=%g rms_error_lsb=%g\n',names{k},s.samples,s.max_error_lsb,s.rms_error_lsb);end
fclose(fid);
if show_figures
    fig=figure('Name','FIR MATLAB / FPGA fixed-point comparison','Color','w');tiledlayout(3,2);
    first=max(1,floor(size(actual,1)/2)-127);ix=first:min(first+255,size(actual,1));
    for ch=1:2
        nexttile;plot(ix-1,ref.dac(ix,ch));hold on;plot(ix-1,actual(ix,ch),'--');grid on;legend('MATLAB','FPGA');xlabel('Sample');ylabel(sprintf('%s (LSB)',char('I'+8*(ch-1))));
    end
    nexttile([1 2]);plot(dac_error);grid on;xlabel('Sample');ylabel('Error (LSB)');legend('I','Q');
    nexttile([1 2]);n=2^nextpow2(size(actual,1));f=(-n/2:n/2-1)'*2400/n;
    a=complex(actual(:,1),actual(:,2));m=complex(ref.dac(:,1),ref.dac(:,2));
    plot(f,20*log10(max(abs(fftshift(fft(m,n)))/numel(m)/32768,1e-12)));hold on;
    plot(f,20*log10(max(abs(fftshift(fft(a,n)))/numel(a)/32768,1e-12)),'--');
    grid on;xlabel('Frequency (MHz)');ylabel('Magnitude (dBFS)');legend('MATLAB','FPGA');
    exportgraphics(fig,fullfile(out_dir,'comparison.png'),'Resolution',150);
end
assert(pass,'MATLAB / FPGA mismatch. Inspect comparison.txt and intermediate outputs; no gain/phase/time alignment is applied.');
fprintf('MODE2_COMPARISON_PASS\n');
end
function d=read_rows(path,width)
lines=readlines(path);if ~isempty(lines) && strlength(lines(end))==0,lines(end)=[];end
pattern=['^\s*[+-]?\d+' repmat('\s+[+-]?\d+',1,width-1) '\s*$'];
assert(~isempty(lines) && all(~cellfun(@isempty,regexp(cellstr(lines),pattern,'once'))),'Malformed result: %s',path);
d=reshape(sscanf(strjoin(lines,newline),'%f'),width,[]).';
end
