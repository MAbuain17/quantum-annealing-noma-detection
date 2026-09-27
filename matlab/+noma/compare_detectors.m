function result = compare_detectors(config, tx_dbm_values, frames, seed)
%COMPARE_DETECTORS Count ML and SIC bit errors on the same received frames.
if nargin < 3
    frames = 200;
end
if nargin < 4
    seed = 2024;
end
validateattributes(frames, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'frames');
validateattributes(seed, {'numeric'}, ...
    {'scalar', 'integer', 'nonnegative', '<=', 2^32 - 1}, mfilename, 'seed');
validateattributes(tx_dbm_values, {'numeric'}, ...
    {'vector', 'nonempty', 'real', 'finite'}, mfilename, 'tx_dbm_values');
powers = tx_dbm_values(:).';
stream = RandStream('mt19937ar', 'Seed', seed);
candidates = noma.candidate_bits(config.users, config.modulation);
candidate_symbols = noma.symbols_from_bits(candidates, config.modulation);
errors = zeros(2, numel(powers));
for p = 1:numel(powers)
    for frame = 1:frames
        [y, H, sent] = noma.draw_frame(config, powers(p), stream);
        ml = noma.decode_ml(y, H, candidates, candidate_symbols);
        sic = noma.decode_sic(y, H, config.modulation);
        errors(1, p) = errors(1, p) + nnz(ml ~= sent);
        errors(2, p) = errors(2, p) + nnz(sic ~= sent);
    end
end
total_bits = frames * config.users * noma.bits_per_symbol(config.modulation);
result = struct('power_dbm', powers, 'ml', errors(1, :) / total_bits, ...
    'sic', errors(2, :) / total_bits, 'errors', errors, 'total_bits', total_bits);
end
