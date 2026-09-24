function write_fir_mem(path,values)
values=values(:);
assert(numel(values)==300 && all(isfinite(values)) && all(values==round(values)) && all(values>=-131072 & values<=131071),'Expected 300 signed18 taps');
fid=fopen(path,'wt');assert(fid>=0,'Cannot write %s',path);cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%05X\n',mod(values,2^18));
end
