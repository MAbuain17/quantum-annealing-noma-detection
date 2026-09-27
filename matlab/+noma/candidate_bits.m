function bits = candidate_bits(users, modulation)
%CANDIDATE_BITS Enumerate binary vectors in ascending, most-significant-first order.
validateattributes(users, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'users');
count = users * noma.bits_per_symbol(modulation);
if count > 16
    error('noma:ExhaustiveLimit', 'Exhaustive ML is limited to 16 bits.');
end
indices = uint32((0:2^count - 1).');
bits = zeros(numel(indices), count);
for column = 1:count
    bits(:, column) = bitget(indices, count - column + 1);
end
end
