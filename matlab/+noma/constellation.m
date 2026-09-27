function [bits, symbols] = constellation(modulation)
%CONSTELLATION Binary labels and complex points for one user.
bits = noma.candidate_bits(1, modulation);
symbols = noma.symbols_from_bits(bits, modulation);
end
