function bits = decode_ml(y, H, candidate_bit_vectors, candidate_symbol_vectors)
%DECODE_ML Select the joint candidate with the smallest squared residual.
validateattributes(y, {'numeric'}, {'scalar', 'finite'}, mfilename, 'y');
validateattributes(H, {'numeric'}, {'vector', 'nonempty', 'finite'}, mfilename, 'H');
if size(candidate_symbol_vectors, 2) ~= numel(H) || ...
        size(candidate_symbol_vectors, 1) ~= size(candidate_bit_vectors, 1) || ...
        isempty(candidate_bit_vectors)
    error('noma:CandidateShape', 'Candidate bits and symbols must have matching rows and users.');
end
% Transpose without conjugation: the signal model is sum(H_k * s_k).
scores = abs(candidate_symbol_vectors * H(:) - y).^2;
[~, best] = min(scores);
bits = candidate_bit_vectors(best, :);
end
