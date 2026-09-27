function bits = decode_sic(y, H, modulation)
%DECODE_SIC Slice and cancel users in descending effective channel magnitude.
validateattributes(y, {'numeric'}, {'scalar', 'finite'}, mfilename, 'y');
validateattributes(H, {'numeric'}, {'vector', 'nonempty', 'finite'}, mfilename, 'H');
H = H(:).';
[options, symbols] = noma.constellation(modulation);
count = noma.bits_per_symbol(modulation);
bits = zeros(1, numel(H) * count);
[~, order] = sort(abs(H), 'descend');
residual = y;
for k = order
    [~, choice] = min(abs(residual - H(k) * symbols).^2);
    columns = (k - 1) * count + (1:count);
    bits(columns) = options(choice, :);
    residual = residual - H(k) * symbols(choice);
end
end
