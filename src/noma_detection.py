"""Uplink NOMA detection experiments for the EE599 project.

One receive antenna observes a sum of independently fading user signals. Binary
variables describe the real and imaginary PAM amplitudes of each constellation.
The resulting least-squares objective is expanded into a QUBO without relying
on private functions from the Ocean SDK.
"""

from dataclasses import dataclass
from itertools import product

import numpy as np


@dataclass(frozen=True)
class Scenario:
    modulation: str
    distances_m: tuple[float, ...]
    path_loss_exponent: float = 2.7
    noise_dbm: float = -30.0

    def __post_init__(self):
        if self.modulation not in {"BPSK", "QPSK", "16QAM", "64QAM"}:
            raise ValueError("Unsupported modulation")
        if not self.distances_m or any(d <= 0 for d in self.distances_m):
            raise ValueError("Distances must be positive")

    @property
    def users(self):
        return len(self.distances_m)


def bits_per_symbol(modulation):
    return {"BPSK": 1, "QPSK": 2, "16QAM": 4, "64QAM": 6}[modulation]


def symbol_affine(modulation):
    """Return c, weights with symbol = c + weights @ bits.

    The QAM convention matches the thesis: the outer corner is at
    (+/-1 +/- j)/sqrt(2), so 16/64-QAM use peak, not average, normalization.
    Binary amplitude labels are used; they are not Gray labels.
    """
    if modulation == "BPSK":
        return -1.0 + 0j, np.array([2.0 + 0j])
    bits_axis = bits_per_symbol(modulation) // 2
    level = 2**bits_axis - 1
    scale = 1.0 / (level * np.sqrt(2.0))
    weights = np.array([2 ** (bits_axis - i) * scale for i in range(bits_axis)])
    return complex(-level * scale, -level * scale), np.r_[weights, 1j * weights]


def symbols_from_bits(bits, modulation):
    bits = np.asarray(bits, dtype=np.int8)
    per_user = bits_per_symbol(modulation)
    if bits.shape[-1] % per_user:
        raise ValueError("Bit count is not divisible by bits per symbol")
    c, weights = symbol_affine(modulation)
    return c + bits.reshape(*bits.shape[:-1], -1, per_user) @ weights


def candidate_bits(users, modulation):
    n = users * bits_per_symbol(modulation)
    if n > 16:
        raise ValueError("Exhaustive ML demonstration is limited to 16 bits")
    indices = np.arange(1 << n, dtype=np.uint32)[:, None]
    return ((indices >> np.arange(n - 1, -1, -1)) & 1).astype(np.int8)


def constellation(modulation):
    bits = np.array(list(product((0, 1), repeat=bits_per_symbol(modulation))), dtype=np.int8)
    return bits, symbols_from_bits(bits, modulation).reshape(-1)


def draw_frame(scenario, tx_dbm, rng):
    """Draw one common received frame for all detectors.

    A complex Rayleigh coefficient has unit mean-square magnitude before path
    loss. noise_dbm denotes total complex noise power E[|n|^2].
    """
    n = scenario.users
    fading = (rng.normal(size=n) + 1j * rng.normal(size=n)) / np.sqrt(2)
    h = fading / np.asarray(scenario.distances_m) ** (scenario.path_loss_exponent / 2)
    tx_w = 10 ** ((tx_dbm - 30) / 10)
    H = np.sqrt(tx_w) * h
    bits = rng.integers(0, 2, size=n * bits_per_symbol(scenario.modulation), dtype=np.int8)
    symbols = symbols_from_bits(bits, scenario.modulation)
    noise_w = 10 ** ((scenario.noise_dbm - 30) / 10)
    noise = np.sqrt(noise_w / 2) * (rng.normal() + 1j * rng.normal())
    return complex(H @ symbols + noise), H, bits


def qubo_from_frame(y, H, modulation):
    """Return Q, offset such that |y-Hs(q)|^2 = offset + sum Qij qi qj."""
    H = np.asarray(H, dtype=np.complex128).ravel()
    c, weights = symbol_affine(modulation)
    A = np.repeat(H, len(weights)) * np.tile(weights, len(H))
    d = y - c * H.sum()
    Q = {(i, i): float(abs(A[i]) ** 2 - 2 * np.real(np.conj(d) * A[i]))
         for i in range(len(A))}
    Q.update({(i, j): float(2 * np.real(np.conj(A[i]) * A[j]))
              for i in range(len(A)) for j in range(i + 1, len(A))})
    return Q, float(abs(d) ** 2)


def qubo_energy(bits, Q, offset=0.0):
    bits = np.asarray(bits)
    return offset + sum(bias * bits[i] * bits[j] for (i, j), bias in Q.items())


def decode_ml(y, H, candidate_bit_vectors, candidate_symbol_vectors):
    scores = abs(candidate_symbol_vectors @ H - y) ** 2
    return candidate_bit_vectors[int(np.argmin(scores))]


def decode_sic(y, H, modulation):
    """Strongest received channel first, then hard slicing and cancellation."""
    H = np.asarray(H)
    options, symbols = constellation(modulation)
    out = np.empty((len(H), bits_per_symbol(modulation)), dtype=np.int8)
    residual = y
    for k in np.argsort(-abs(H)):
        choice = int(np.argmin(abs(residual - H[k] * symbols) ** 2))
        out[k] = options[choice]
        residual -= H[k] * symbols[choice]
    return out.ravel()


def compare_detectors(scenario, tx_dbm_values, frames=200, seed=2024):
    """Measure BER on identical frames for ML and SIC at each power."""
    if frames <= 0:
        raise ValueError("frames must be positive")
    rng = np.random.default_rng(seed)
    candidates = candidate_bits(scenario.users, scenario.modulation)
    symbols = symbols_from_bits(candidates, scenario.modulation)
    errors = np.zeros((2, len(tx_dbm_values)), dtype=np.int64)
    for p, power in enumerate(tx_dbm_values):
        for _ in range(frames):
            y, H, sent = draw_frame(scenario, power, rng)
            errors[0, p] += np.count_nonzero(decode_ml(y, H, candidates, symbols) != sent)
            errors[1, p] += np.count_nonzero(decode_sic(y, H, scenario.modulation) != sent)
    total_bits = frames * scenario.users * bits_per_symbol(scenario.modulation)
    return {"power_dbm": np.asarray(tx_dbm_values), "ml": errors[0] / total_bits,
            "sic": errors[1] / total_bits, "errors": errors, "total_bits": total_bits}


def sample_qpu(y, H, modulation, num_reads=100):
    """Submit one frame to D-Wave Leap; return best binary sample and metadata."""
    try:
        from dwave.system import DWaveSampler, EmbeddingComposite
    except ImportError as exc:
        raise RuntimeError("Install the optional QPU dependencies: pip install -e '.[qpu]'") from exc
    Q, offset = qubo_from_frame(y, H, modulation)
    qpu = DWaveSampler()
    sampleset = EmbeddingComposite(qpu).sample_qubo(
        Q, num_reads=num_reads, label="EE599 uplink NOMA detection"
    )
    sample = sampleset.first.sample
    bits = np.array([sample[i] for i in range(len(H) * bits_per_symbol(modulation))], dtype=np.int8)
    return bits, {"solver": qpu.solver.name, "reads": num_reads,
                  "energy_with_offset": float(sampleset.first.energy + offset),
                  "timing": sampleset.info.get("timing", {})}
