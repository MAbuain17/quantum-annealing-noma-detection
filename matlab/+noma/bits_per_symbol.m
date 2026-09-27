function count = bits_per_symbol(modulation)
%BITS_PER_SYMBOL Number of binary labels in one constellation symbol.
switch char(modulation)
    case 'BPSK'
        count = 1;
    case 'QPSK'
        count = 2;
    case '16QAM'
        count = 4;
    case '64QAM'
        count = 6;
    otherwise
        error('noma:UnsupportedModulation', ...
            'Modulation must be BPSK, QPSK, 16QAM, or 64QAM.');
end
end
