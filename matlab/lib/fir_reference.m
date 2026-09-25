function ref = fir_reference(x,cr,ci)
% Integer operands and <2^48 accumulators are represented exactly by doubles.
% RFDC filters are outside this PL-only fixed-point model.
x=double(x);d=x;
ri=conv(d(:,1),cr)-conv(d(:,2),ci);
rq=conv(d(:,1),ci)+conv(d(:,2),cr);
a=[ri(1:size(d,1)),rq(1:size(d,1))];
assert(all(abs(a(:))<2^48),'Complex accumulator outside supported 49-bit range');
f=min(32767,max(-32768,floor(a/2^16)));
ref.adc=d;ref.fir=f;ref.dac=f;
end
