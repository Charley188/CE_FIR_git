function q = fir_read_coe(path)
s = fileread(path);
s = regexprep(s,'(?m)^\s*;[^\n]*','');
assert(~isempty(regexpi(s,'radix\s*=\s*10\s*;','once')),'COE must use radix 10: %s',path);
t = regexpi(s,'coefdata\s*=\s*([^;]+);','tokens','once');
assert(~isempty(t),'Missing coefdata: %s',path);
q = sscanf(strrep(t{1},',',' '),'%f');
assert(~isempty(q) && all(isfinite(q)) && all(q==fix(q)) && all(q>=-2^17 & q<2^17),'Invalid signed18 COE: %s',path);
end
