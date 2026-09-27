function [c, weights] = symbol_affine(modulation)
%SYMBOL_AFFINE Constant and weights for symbol = c + bits * weights.'
count = noma.bits_per_symbol(modulation);
if count == 1
    c = -1;
    weights = 2;
    return
end
bits_axis = count / 2;
level = 2^bits_axis - 1;
scale = 1 / (level * sqrt(2));
axis_weights = 2.^(bits_axis:-1:1) * scale;
c = -level * scale * (1 + 1i);
weights = [axis_weights, 1i * axis_weights];
end
