function ref = fir_reference(x,cr,ci,interpolation)
% Integer operands and <2^48 accumulators are represented exactly by doubles.
% Physical /12 selector has no anti-alias prefilter; match the production RTL.
x=double(x);d=x(1:12:end,:);
ri=conv(d(:,1),cr)-conv(d(:,2),ci);
rq=conv(d(:,1),ci)+conv(d(:,2),cr);
a=[ri(1:size(d,1)),rq(1:size(d,1))];
assert(all(abs(a(:))<2^48),'Complex accumulator outside supported 49-bit range');
f=min(32767,max(-32768,floor(a/2^16)));
[oi,oq]=interp12_fixed_model(f(:,1),f(:,2),interpolation);
ref.decimator=d;ref.fir=f;ref.dac=double([oi,oq]);
end
