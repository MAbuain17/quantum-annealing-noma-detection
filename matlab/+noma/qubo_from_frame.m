function [Q, offset] = qubo_from_frame(y, H, modulation)
%QUBO_FROM_FRAME Upper-triangular Q with one coefficient per unordered pair.
validateattributes(y, {'numeric'}, {'scalar', 'finite'}, mfilename, 'y');
validateattributes(H, {'numeric'}, {'vector', 'nonempty', 'finite'}, mfilename, 'H');
[c, weights] = noma.symbol_affine(modulation);
A = kron(H(:).', weights);
d = y - c * sum(H(:));
diagonal = abs(A).^2 - 2 * real(conj(d) * A);
couplings = 2 * real(conj(A(:)) * A);
Q = diag(diagonal) + triu(couplings, 1);
offset = abs(d)^2;
end
