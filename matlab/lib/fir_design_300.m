function design = fir_design_300(cfg)
% 300-tap Type-II raised-cosine FIR; no VNA data dependency.
if nargin==0,cfg=fir_config();end
N = 300;
Fs=cfg.sample_rate_hz;fp=cfg.passband_hz;fst=cfg.stopband_hz;
assert(cfg.tap_count==N && 0<fp && fp<fst && fst<Fs/2,'Invalid FIR frequency specification');
f = linspace(0,Fs/2,8193).';
desired = ones(size(f));
transition = f > fp & f < fst;
desired(transition) = 0.5*(1+cos(pi*(f(transition)-fp)/(fst-fp)));
desired(f>=fst)=0;
% Mirrored pairs about n=149.5; Nyquist zero follows from even symmetry.
B = 2*cos((2*pi*f/Fs)*(0.5:1:(N/2-0.5)));
dc = B(1,:);
K = [B.'*B+1e-12*eye(N/2), dc.'; dc, 0];
solution = K\[B.'*desired; 1];
pair = solution(1:N/2);
taps = [flipud(pair);pair];
qpair = round(pair*2^16);
qpair(1) = qpair(1)+(2^15-sum(qpair));
q = [flipud(qpair);qpair];
design.kind = 'standard_fir';
design.sample_rate_hz = Fs;
design.tap_count = N;
design.passband_edge_hz = fp;
design.stopband_edge_hz = fst;
design.coefficient_fraction_bits = 16;
design.taps = taps;
design.real_i18 = int64(q);
design.imag_i18 = zeros(N,1,'int64');
assert(isequal(q,flipud(q)) && sum(q)==2^16);
H = abs(freqz(q/2^16,1,2*pi*f/Fs));
assert(max(abs(H(f<=fp)-1))<=0.01,'Standard FIR passband exceeds 1%%.');
assert(max(H(f>=fst))<=0.01,'Standard FIR stopband exceeds 1%%.');
[~,mid] = min(abs(f-(fp+fst)/2));
assert(abs(H(mid)-0.5)<=0.02,'Standard FIR transition midpoint exceeds tolerance.');
assert(abs(sum(q.*(-1).^(0:N-1).'))==0);

end
