function d = fir_interpolation(coeff_dir)
% Reconstruct full halfband taps from the actual odd-phase COE used by the IP.
d.coefficient_fraction_bits=16;
d.stage1.full_i18=fir_read_coe(fullfile(coeff_dir,'interp3_stage1.coe'));
d.stage1.tap_count=numel(d.stage1.full_i18);
for k=2:3
    odd=fir_read_coe(fullfile(coeff_dir,sprintf('interp2_stage%d_odd.coe',k)));
    full=zeros(2*numel(odd)+1,1);full(2:2:end)=odd;full((numel(full)+1)/2)=2^16;
    assert(mod(numel(full)-1,4)==0,'Halfband layout requires 4m+1 taps');
    d.(sprintf('stage%d',k))=struct('full_i18',full,'tap_count',numel(full),'odd_i18',odd);
end
end
