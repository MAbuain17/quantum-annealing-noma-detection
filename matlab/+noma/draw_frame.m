function [y, H, bits, symbols, noise] = draw_frame(config, tx_dbm, stream)
%DRAW_FRAME Draw one received sample shared by all detectors.
% noise_dbm is total complex noise power, E[abs(noise)^2].
if nargin < 3
    stream = RandStream.getGlobalStream;
end
validateattributes(tx_dbm, {'numeric'}, ...
    {'scalar', 'real', 'finite'}, mfilename, 'tx_dbm');
users = config.users;
fading = (randn(stream, 1, users) + 1i * randn(stream, 1, users)) / sqrt(2);
h = fading ./ config.distances_m.^(config.path_loss_exponent / 2);
tx_w = 10^((tx_dbm - 30) / 10);
H = sqrt(tx_w) * h;
bits = randi(stream, [0, 1], 1, users * noma.bits_per_symbol(config.modulation));
symbols = noma.symbols_from_bits(bits, config.modulation);
noise_w = 10^((config.noise_dbm - 30) / 10);
noise = sqrt(noise_w / 2) * (randn(stream) + 1i * randn(stream));
y = H * symbols.' + noise;
end
