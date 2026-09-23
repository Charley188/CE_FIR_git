function design = fir_design_300()
% 300-tap Type-II raised-cosine FIR; no VNA data dependency.
% Match the 45-tap design's 200 MHz / 80--100 MHz magnitude specification.
N = 300;
f = linspace(0,100e6,8193).';
desired = ones(size(f));
transition = f > 80e6;
desired(transition) = 0.5*(1+cos(pi*(f(transition)-80e6)/20e6));
% Mirrored pairs about n=149.5; Nyquist zero follows from even symmetry.
B = 2*cos((2*pi*f/200e6)*(0.5:1:(N/2-0.5)));
dc = B(1,:);
K = [B.'*B+1e-12*eye(N/2), dc.'; dc, 0];
solution = K\[B.'*desired; 1];
pair = solution(1:N/2);
taps = [flipud(pair);pair];
qpair = round(pair*2^16);
qpair(1) = qpair(1)+(2^15-sum(qpair));
q = [flipud(qpair);qpair];
design.kind = 'standard_fir';
design.sample_rate_hz = 200e6;
design.tap_count = N;
design.passband_edge_hz = 80e6;
design.stopband_edge_hz = 100e6;
design.coefficient_fraction_bits = 16;
design.taps = taps;
design.real_i18 = int64(q);
design.imag_i18 = zeros(N,1,'int64');
assert(isequal(q,flipud(q)) && sum(q)==2^16);
H = abs(freqz(q/2^16,1,2*pi*f/200e6));
assert(max(abs(H(f<=80e6)-1))<=0.01,'Standard FIR passband exceeds 1%%.');
[~,mid] = min(abs(f-90e6));
assert(abs(H(mid)-0.5)<=0.02,'Standard FIR transition midpoint exceeds tolerance.');
assert(abs(sum(q.*(-1).^(0:N-1).'))==0);

end
