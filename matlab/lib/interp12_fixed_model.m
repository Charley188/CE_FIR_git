function [y_i,y_q,trace] = interp12_fixed_model(x_i,x_q,design)
%INTERP12_FIXED_MODEL Bit-accurate signed-16 3x2x2 interpolator model.

x_i = validate_samples_local(x_i,'x_i');
x_q = validate_samples_local(x_q,'x_q');
assert(numel(x_i) == numel(x_q),'I and Q input lengths must match.');
assert(design.coefficient_fraction_bits == 16, ...
    'The fixed model requires Q2.16 coefficients.');

stage1_i = interpolate_stage_local(x_i,design.stage1.full_i18,3);
stage1_q = interpolate_stage_local(x_q,design.stage1.full_i18,3);
stage2_i = interpolate_stage_local(stage1_i,design.stage2.full_i18,2);
stage2_q = interpolate_stage_local(stage1_q,design.stage2.full_i18,2);
y_i = interpolate_stage_local(stage2_i,design.stage3.full_i18,2);
y_q = interpolate_stage_local(stage2_q,design.stage3.full_i18,2);

stage2_delay = (design.stage2.tap_count-1)/4;
stage3_delay = (design.stage3.tap_count-1)/4;
assert(stage2_delay == floor(stage2_delay) && ...
       stage3_delay == floor(stage3_delay), ...
    'Half-band delay phases require 4*m+1 full-tap vectors.');

trace.stage1_i = stage1_i;
trace.stage1_q = stage1_q;
trace.stage1_delayed_i = delay_samples_local(stage1_i,stage2_delay);
trace.stage1_delayed_q = delay_samples_local(stage1_q,stage2_delay);
trace.stage2_i = stage2_i;
trace.stage2_q = stage2_q;
trace.stage2_delayed_i = delay_samples_local(stage2_i,stage3_delay);
trace.stage2_delayed_q = delay_samples_local(stage2_q,stage3_delay);
trace.stage3_i = y_i;
trace.stage3_q = y_q;
end

function y = interpolate_stage_local(x,h,factor)
    x = int64(x(:));
    h = int64(h(:));
    y = zeros(factor*numel(x),1,'int64');
    for input_index = 1:numel(x)
        history = x(input_index:-1:1);
        output_base = (input_index-1)*factor;
        for phase = 0:(factor-1)
            phase_coef = h((phase+1):factor:end);
            active_count = min(numel(history),numel(phase_coef));
            acc = sum(int64(history(1:active_count)).* ...
                int64(phase_coef(1:active_count)),'native');
            scaled = bitshift(acc,-16);
            sample = min(int64(32767),max(int64(-32768),scaled));
            y(output_base+phase+1) = sample;
        end
    end
end

function delayed = delay_samples_local(x,delay)
    delayed = zeros(size(x),'int64');
    if delay < numel(x)
        delayed((delay+1):end) = x(1:(end-delay));
    end
end

function x = validate_samples_local(x,name)
    assert(isnumeric(x) && isreal(x), ...
        '%s must be a real numeric vector.',name);
    x = x(:);
    assert(all(isfinite(x)) && all(x == fix(x)), ...
        '%s must contain finite integer samples.',name);
    assert(all(x >= -32768 & x <= 32767), ...
        '%s contains a value outside signed-16 range.',name);
    x = int64(x);
end
