function energy = qubo_energy(bits, Q, offset)
%QUBO_ENERGY Evaluate one or more rows of bits, including an optional offset.
if nargin < 3
    offset = 0;
end
validateattributes(Q, {'numeric'}, {'2d', 'square', 'real', 'finite'}, mfilename, 'Q');
validateattributes(bits, {'numeric', 'logical'}, ...
    {'2d', 'nonempty', 'real', 'finite'}, mfilename, 'bits');
validateattributes(offset, {'numeric'}, {'scalar', 'real', 'finite'}, mfilename, 'offset');
if size(bits, 2) ~= size(Q, 1) || any(bits(:) ~= 0 & bits(:) ~= 1)
    error('noma:InvalidBits', 'Each row must contain one binary value per QUBO variable.');
end
values = double(bits);
energy = offset + sum((values * Q) .* values, 2);
end
