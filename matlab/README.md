# MATLAB classical receivers

The `+noma` package implements the uplink signal model, binary constellation mappings, exhaustive maximum-likelihood detection, hard-decision successive interference cancellation, and QUBO coefficients. It follows [`src/noma_detection.py`](../src/noma_detection.py) and the [derivation](../docs/QUBO_DERIVATION.md). MATLAB R2018b or newer is required; no additional toolboxes are needed.

## Run the reference experiment

From the repository root in MATLAB:

```matlab
addpath('matlab');
results = reproduce();
```

The default run uses 1,000 frames per power point and seed 2024. For a shorter run:

```matlab
results = reproduce(100, 2024);
```

The script writes `results/matlab/classical_baselines.csv` and `classical_baselines.png`. Each CSV row includes the receiver error counts, tested-bit denominator, BER, frame count, seed, and noise power. Zero-error points are retained as zero in the CSV and omitted from the logarithmic plot.

The scenarios and powers match [`scripts/reproduce.py`](../scripts/reproduce.py): 10 BPSK users, 5 QPSK users, 3 16-QAM users, and 2 64-QAM users; powers from -20 to 30 dBm in 10 dB steps; path-loss exponent 2.7; and total complex noise power -60 dBm. Both detectors receive the same frame at each trial. MATLAB uses a local Mersenne Twister stream and does not change the global random state. Python uses NumPy's default generator, so equal seeds do not produce identical random frames across languages. Fixed-frame parity is checked separately below.

## Detect one frame

```matlab
addpath('matlab');
config = noma.scenario('QPSK', [100, 250, 400], 2.7, -60);
stream = RandStream('mt19937ar', 'Seed', 12);
[y, H, sent] = noma.draw_frame(config, 10, stream);
candidates = noma.candidate_bits(config.users, config.modulation);
symbols = noma.symbols_from_bits(candidates, config.modulation);
ml = noma.decode_ml(y, H, candidates, symbols);
sic = noma.decode_sic(y, H, config.modulation);
[Q, offset] = noma.qubo_from_frame(y, H, config.modulation);
energy = noma.qubo_energy(ml, Q, offset);
disp([sent; ml; sic]);
```

Rows contain user-major bits. For each QAM user, real-axis bits come before imaginary-axis bits, ordered from largest to smallest weight. `H` already includes transmit power and channel attenuation. Signal products use a nonconjugating transpose: `y = H * symbols.' + noise`. Candidate matrices contain one possible joint bit or symbol vector per row.

ML minimizes `abs(candidate_symbols * H(:) - y).^2` over all candidates. Enumeration is capped at 16 total bits to bound memory and runtime. SIC orders users by descending `abs(H)`, selects the nearest scaled constellation point, cancels that user's reconstructed contribution, and returns the bits in their original user order. It uses hard decisions without a coding or soft-information stage. Equal candidate scores choose the first enumerated candidate; equal channel magnitudes preserve user order.

## Channel and modulation conventions

Independent fading coefficients have real and imaginary components with variance 1/2 before path loss. Their amplitudes are Rayleigh distributed. Channel amplitude is divided by `distance^(path_loss_exponent/2)`, then multiplied by the square root of transmit power in watts. Complex AWGN is added once at the receiver; its real and imaginary components each carry half the specified total noise power. `noma.scenario` defaults to exponent 2.7 and noise power -30 dBm; `reproduce` explicitly uses -60 dBm.

![Peak-normalized BPSK, QPSK, 16-QAM, and 64-QAM constellations](../assets/constellations.png)

The diagram's BPSK endpoints and QAM outer corners have unit magnitude. Its constants are `b = 1/(3*sqrt(2))` for 16-QAM and `a = 1/(7*sqrt(2))` for 64-QAM. Mean energies under uniform labels are 1, 1, 5/9, and 3/7 for BPSK, QPSK, 16-QAM, and 64-QAM. The labels are binary amplitude labels, not Gray labels. These conventions preserve the thesis mappings rather than MATLAB toolbox defaults.

The QUBO matrix is upper triangular, with one stored coefficient per unordered pair. `noma.qubo_energy(bits, Q, offset)` evaluates `offset + bits*Q*bits.'` for each row. The offset restores the original squared residual but does not change the minimizing vector. This package supplies the classical receivers and formulation; live D-Wave submission remains in the Python notebook.

## Verification

```matlab
addpath('matlab', 'matlab/tests');
test_detection;
```

The checks compare both receiver decisions, constellation labels, and QUBO coefficients with [`python_reference.json`](tests/python_reference.json), generated from the Python implementation. They enumerate the two-user residual objective for all four modulations, check noiseless single-user recovery, verify SIC ordering and cancellation, and check reproducibility, BER accounting, and channel/noise power. The tests require no live QPU access.

To refresh the fixed reference after an intentional Python model change:

```bash
python matlab/tests/generate_reference.py
```
