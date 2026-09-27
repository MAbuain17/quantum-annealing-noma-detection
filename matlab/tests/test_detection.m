function test_detection
%TEST_DETECTION Check mappings, receiver decisions, channels, and QUBO energies.
matlab_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(matlab_dir);
fixture = jsondecode(fileread(fullfile(matlab_dir, 'tests', 'python_reference.json')));
for k = 1:numel(fixture.cases)
    ref = fixture.cases(k);
    H = complex(ref.H_real, ref.H_imag);
    y = complex(ref.y_real, ref.y_imag);
    candidates = noma.candidate_bits(numel(H), ref.modulation);
    symbols = noma.symbols_from_bits(candidates, ref.modulation);
    ml = noma.decode_ml(y, H, candidates, symbols);
    sic = noma.decode_sic(y, H, ref.modulation);
    assert(isequal(ml, ref.ml_bits(:).'), 'ML disagrees with the Python reference.');
    assert(isequal(sic, ref.sic_bits(:).'), 'SIC disagrees with the Python reference.');
    assert(isequal(noma.decode_sic(y, H(:), ref.modulation), sic));
    [Q, offset] = noma.qubo_from_frame(y, H, ref.modulation);
    assert(max(abs(Q(:) - ref.Q(:))) < 1e-12, 'QUBO coefficients disagree.');
    assert(abs(offset - ref.offset) < 1e-12);
    energies = noma.qubo_energy(candidates, Q, offset);
    residuals = abs(symbols * H(:) - y).^2;
    assert(max(abs(energies - residuals)) < 1e-11, 'QUBO residual identity failed.');
    assert(abs(noma.qubo_energy(ml, Q, offset) - min(residuals)) < 1e-11);

    [labels, points] = noma.constellation(ref.modulation);
    assert(isequal(labels, ref.constellation_bits));
    expected = complex(ref.constellation_real(:), ref.constellation_imag(:));
    assert(max(abs(points - expected)) < 1e-12, 'Constellation mapping disagrees.');
    assert(abs(max(abs(points)) - 1) < 1e-12, 'Peak normalization failed.');
    mean_energies = [1, 1, 5/9, 3/7];
    assert(abs(mean(abs(points).^2) - mean_energies(k)) < 1e-12);
    for point = 1:numel(points)
        channel = 0.4 + 0.7i;
        sample = channel * points(point);
        assert(isequal(noma.decode_ml(sample, channel, labels, points), labels(point, :)));
        assert(isequal(noma.decode_sic(sample, channel, ref.modulation), labels(point, :)));
    end
end
assert(isequal(noma.decode_sic(-0.6, [0.4, 1], 'BPSK'), [1, 0]), ...
    'SIC must cancel the strongest channel first and restore user order.');
assert_error(@() noma.candidate_bits(3, '64QAM'), 'noma:ExhaustiveLimit');
assert_error(@() noma.symbols_from_bits([0, 2], 'QPSK'), 'noma:InvalidBits');
assert_error(@() noma.symbols_from_bits([0, 1, 0], 'QPSK'), 'noma:BitCount');
assert_error(@() noma.bits_per_symbol('8PSK'), 'noma:UnsupportedModulation');

config = noma.scenario('QPSK', [100, 250, 400]);
stream_a = RandStream('mt19937ar', 'Seed', 12);
stream_b = RandStream('mt19937ar', 'Seed', 12);
[ya, Ha, ba] = noma.draw_frame(config, 5, stream_a);
[yb, Hb, bb] = noma.draw_frame(config, 5, stream_b);
assert(isequal(ya, yb) && isequal(Ha, Hb) && isequal(ba, bb));
before = rng;
result = noma.compare_detectors(config, [-10, 0, 10], 25, 19);
assert(isequal(before, rng), 'An explicit stream must leave the global RNG unchanged.');
repeat = noma.compare_detectors(config, [-10, 0, 10], 25, 19);
assert(isequal(result, repeat));
assert(result.total_bits == 25 * 3 * 2);
assert(isequal(result.errors / result.total_bits, [result.ml; result.sic]));
assert(all(result.errors(:) >= 0 & result.errors(:) <= result.total_bits));

config = noma.scenario('BPSK', [1, 2], 2.7, -30);
stream = RandStream('mt19937ar', 'Seed', 73);
channel_power = zeros(1, 2);
noise_power = 0;
draws = 6000;
for frame = 1:draws
    [y, H, ~, symbols, noise] = noma.draw_frame(config, 0, stream);
    assert(abs(y - H * symbols.' - noise) < 1e-14);
    channel_power = channel_power + abs(H).^2;
    noise_power = noise_power + abs(noise)^2;
end
expected_power = 1e-3 ./ [1, 2].^2.7;
assert(all(abs(channel_power / draws ./ expected_power - 1) < 0.07));
assert(abs(noise_power / draws / 1e-6 - 1) < 0.07);
fprintf('Passed constellation, Python parity, ML/SIC, QUBO, BER, and channel checks.\n');
end

function assert_error(action, identifier)
try
    action();
catch exception
    assert(strcmp(exception.identifier, identifier), 'Unexpected error: %s', exception.identifier);
    return
end
error('noma:MissingError', 'Expected %s.', identifier);
end
