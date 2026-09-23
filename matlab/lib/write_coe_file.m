function write_coe_file(path,values)
fid = fopen(path,'wt');
assert(fid>=0,'Cannot write %s',path);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'radix=10;\ncoefdata=\n');
fprintf(fid,'%d,\n',values(1:end-1));
fprintf(fid,'%d;\n',values(end));
end
