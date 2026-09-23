function design = fir_design_45()
%DESIGN_IDEAL_RAISED_COSINE_FIR Design the standalone calibration FIR.
%   The desired zero-phase magnitude is unity through 80 MHz and follows
%   a raised-cosine transition to zero at the 100 MHz Nyquist frequency.
%   The returned 45-tap filter is real, symmetric, and quantized to the
%   signed-18/Q2.16 format used by the existing FIR Compiler instances.

sample_rate_hz = 200e6;
tap_count = 45;
passband_edge_hz = 80e6;
stopband_edge_hz = 100e6;
coefficient_fraction_bits = 16;
coefficient_scale = 2^coefficient_fraction_bits;

frequency_hz = linspace(0, sample_rate_hz/2, 8193).';
desired_magnitude = ones(size(frequency_hz));
transition = frequency_hz > passband_edge_hz;
transition_position = (frequency_hz(transition) - passband_edge_hz) / ...
    (stopband_edge_hz - passband_edge_hz);
desired_magnitude(transition) = 0.5 * ...
    (1 + cos(pi * transition_position));
desired_magnitude(frequency_hz >= stopband_edge_hz) = 0;

% Solve directly for the 23 unique coefficients of a 45-tap Type-I
% linear-phase FIR.  The two equality constraints make the standalone
% response exactly unity at DC and zero at the 100 MHz Nyquist point;
% window truncation would smear that endpoint and miss the intended rolloff.
half_length = (tap_count - 1)/2;
angular_frequency = pi * frequency_hz / (sample_rate_hz/2);
cosine_basis = [ones(size(angular_frequency)), ...
    2*cos(angular_frequency*(1:half_length))];
endpoint_constraints = cosine_basis([1 end],:);
normal_matrix = cosine_basis.' * cosine_basis + ...
    1e-12 * eye(half_length + 1);
kkt_matrix = [normal_matrix, endpoint_constraints.'; ...
              endpoint_constraints, zeros(2)];
kkt_rhs = [cosine_basis.' * desired_magnitude; 1; 0];
kkt_solution = kkt_matrix \ kkt_rhs;
unique_taps = kkt_solution(1:half_length+1);
taps = [flip(unique_taps(2:end)); unique_taps(1); unique_taps(2:end)];

real_i18 = round(taps * coefficient_scale);
real_i18((tap_count+3)/2:end) = ...
    real_i18((tap_count-1)/2:-1:1);
center_index = (tap_count+1)/2;
real_i18(center_index) = real_i18(center_index) + ...
    (coefficient_scale - sum(real_i18));

% Preserve both exact integer DC gain and the exact Nyquist zero after
% Q2.16 rounding.  Symmetry makes the alternating sum a multiple of four;
% equal-and-opposite corrections to one even and one odd mirrored pair do
% not change the coefficient sum.
alternating_sign = (-1).^(0:tap_count-1).';
nyquist_integer_gain = sum(real_i18 .* alternating_sign);
pair_correction = -nyquist_integer_gain / 4;
if pair_correction ~= round(pair_correction)
    error('Symmetric Q2.16 coefficients cannot satisfy the Nyquist constraint.');
end
real_i18([1 end]) = real_i18([1 end]) + pair_correction;
real_i18([2 end-1]) = real_i18([2 end-1]) - pair_correction;

if any(real_i18 < -2^17 | real_i18 > 2^17-1)
    error('Raised-cosine coefficients exceed the signed-18 range.');
end

imag_i18 = zeros(size(real_i18));

design = struct();
design.sample_rate_hz = sample_rate_hz;
design.tap_count = tap_count;
design.passband_edge_hz = passband_edge_hz;
design.stopband_edge_hz = stopband_edge_hz;
design.coefficient_fraction_bits = coefficient_fraction_bits;
design.taps = taps(:);
design.real_i18 = int64(real_i18(:));
design.imag_i18 = int64(imag_i18(:));
end
