function results = reproduce(frames, seed, output_dir)
%REPRODUCE Run the four classical reference scenarios and save BER results.
if nargin < 1
    frames = 1000;
end
if nargin < 2
    seed = 2024;
end
root = fileparts(fileparts(mfilename('fullpath')));
if nargin < 3
    output_dir = fullfile(root, 'results', 'matlab');
end
addpath(fullfile(root, 'matlab'));
validateattributes(frames, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'frames');
validateattributes(seed, {'numeric'}, ...
    {'scalar', 'integer', 'nonnegative', '<=', 2^32 - 4}, mfilename, 'seed');
scenarios = {
    noma.scenario('BPSK', 100:50:550, 2.7, -60)
    noma.scenario('QPSK', 100:100:500, 2.7, -60)
    noma.scenario('16QAM', [100, 300, 500], 2.7, -60)
    noma.scenario('64QAM', [100, 500], 2.7, -60)
};
powers = -20:10:30;
results = cell(size(scenarios));
rows = cell(0, 11);
for k = 1:numel(scenarios)
    config = scenarios{k};
    result = noma.compare_detectors(config, powers, frames, seed + k - 1);
    results{k} = result;
    for p = 1:numel(powers)
        rows(end + 1, :) = {config.modulation, config.users, powers(p), ...
            result.errors(1, p), result.errors(2, p), result.total_bits, ...
            result.ml(p), result.sic(p), frames, seed + k - 1, config.noise_dbm}; %#ok<AGROW>
    end
end
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
columns = {'modulation', 'users', 'tx_dbm', 'ml_errors', 'sic_errors', ...
    'bits_tested', 'ml_ber', 'sic_ber', 'frames', 'seed', 'noise_dbm'};
writetable(cell2table(rows, 'VariableNames', columns), ...
    fullfile(output_dir, 'classical_baselines.csv'));
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [100, 100, 1000, 700]);
cleanup = onCleanup(@() close(fig));
for k = 1:numel(scenarios)
    ax = subplot(2, 2, k, 'Parent', fig);
    ml = results{k}.ml;
    sic = results{k}.sic;
    % Zero-error points remain zero in the CSV and have no log-scale ordinate.
    ml(ml == 0) = NaN;
    sic(sic == 0) = NaN;
    semilogy(ax, powers, ml, 'o-', 'Color', [0.07, 0.24, 0.41], 'LineWidth', 1.2);
    hold(ax, 'on');
    semilogy(ax, powers, sic, 's--', 'Color', [0.75, 0.35, 0.15], 'LineWidth', 1.2);
    grid(ax, 'on');
    ylim(ax, [1 / results{k}.total_bits, 1]);
    title(ax, sprintf('%s | %d users', scenarios{k}.modulation, scenarios{k}.users));
    xlabel(ax, 'Transmit power per user (dBm)');
    ylabel(ax, 'Bit error rate');
    if k == 1
        legend(ax, 'Exhaustive ML', 'Hard-decision SIC', 'Location', 'best');
    end
end
sgtitle(fig, 'Uplink NOMA: MATLAB classical reference');
print(fig, fullfile(output_dir, 'classical_baselines.png'), '-dpng', '-r170');
fprintf('Wrote %s\n', fullfile(output_dir, 'classical_baselines.csv'));
fprintf('Wrote %s\n', fullfile(output_dir, 'classical_baselines.png'));
end
