function config = scenario(modulation, distances_m, path_loss_exponent, noise_dbm)
%SCENARIO Parameters for independent fading uplink frames.
if nargin < 3
    path_loss_exponent = 2.7;
end
if nargin < 4
    noise_dbm = -30;
end
noma.bits_per_symbol(modulation);
validateattributes(distances_m, {'numeric'}, ...
    {'vector', 'nonempty', 'real', 'positive', 'finite'}, mfilename, 'distances_m');
validateattributes(path_loss_exponent, {'numeric'}, ...
    {'scalar', 'real', 'positive', 'finite'}, mfilename, 'path_loss_exponent');
validateattributes(noise_dbm, {'numeric'}, ...
    {'scalar', 'real', 'finite'}, mfilename, 'noise_dbm');
config = struct('modulation', char(modulation), ...
    'distances_m', double(distances_m(:).'), ...
    'path_loss_exponent', double(path_loss_exponent), ...
    'noise_dbm', double(noise_dbm), 'users', numel(distances_m));
end
