function symbols = symbols_from_bits(bits, modulation)
%SYMBOLS_FROM_BITS Map rows of user-major binary labels to complex symbols.
% Each user stores real-axis bits first, then imaginary-axis bits.
validateattributes(bits, {'numeric', 'logical'}, ...
    {'2d', 'nonempty', 'real', 'finite'}, mfilename, 'bits');
if any(bits(:) ~= 0 & bits(:) ~= 1)
    error('noma:InvalidBits', 'Bits must contain only zeros and ones.');
end
count = noma.bits_per_symbol(modulation);
if mod(size(bits, 2), count) ~= 0
    error('noma:BitCount', 'Each row must contain a whole number of user symbols.');
end
[c, weights] = noma.symbol_affine(modulation);
users = size(bits, 2) / count;
symbols = complex(zeros(size(bits, 1), users));
for k = 1:users
    columns = (k - 1) * count + (1:count);
    symbols(:, k) = c + double(bits(:, columns)) * weights.';
end
end
