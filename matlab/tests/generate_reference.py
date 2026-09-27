"""Refresh fixed MATLAB test cases from the repository's Python implementation."""

import json
from pathlib import Path
import sys

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "src"))
from noma_detection import (candidate_bits, constellation, decode_ml, decode_sic,
                            qubo_from_frame, symbols_from_bits)


def main():
    H = np.array([0.8 + 0.2j, -0.35 + 0.7j])
    y = -0.11 + 0.23j
    cases = []
    for modulation in ("BPSK", "QPSK", "16QAM", "64QAM"):
        candidates = candidate_bits(2, modulation)
        symbols = symbols_from_bits(candidates, modulation)
        labels, points = constellation(modulation)
        coefficients, offset = qubo_from_frame(y, H, modulation)
        Q = np.zeros((candidates.shape[1], candidates.shape[1]))
        for (i, j), value in coefficients.items():
            Q[i, j] = value
        cases.append({
            "modulation": modulation,
            "H_real": H.real.tolist(), "H_imag": H.imag.tolist(),
            "y_real": y.real, "y_imag": y.imag,
            "ml_bits": decode_ml(y, H, candidates, symbols).tolist(),
            "sic_bits": decode_sic(y, H, modulation).tolist(),
            "Q": Q.tolist(), "offset": offset,
            "constellation_bits": labels.tolist(),
            "constellation_real": points.real.tolist(),
            "constellation_imag": points.imag.tolist(),
        })
    target = Path(__file__).with_name("python_reference.json")
    target.write_text(json.dumps({"cases": cases}, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {target.name}")


if __name__ == "__main__":
    main()
