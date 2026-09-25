import unittest

import numpy as np

from noma_detection import (Scenario, candidate_bits, compare_detectors,
                            decode_ml, draw_frame, qubo_energy, qubo_from_frame,
                            symbols_from_bits)


class DetectionTests(unittest.TestCase):
    def test_qubo_matches_signal_residual_for_all_modulations(self):
        rng = np.random.default_rng(7)
        for modulation in ("BPSK", "QPSK", "16QAM", "64QAM"):
            with self.subTest(modulation=modulation):
                H = np.array([0.32 + 0.17j, -0.21 + 0.44j])
                y = 0.12 - 0.35j
                Q, offset = qubo_from_frame(y, H, modulation)
                for _ in range(30):
                    bits = rng.integers(0, 2, size={"BPSK": 2, "QPSK": 4,
                                                      "16QAM": 8, "64QAM": 12}[modulation])
                    residual = abs(y - H @ symbols_from_bits(bits, modulation)) ** 2
                    self.assertAlmostEqual(qubo_energy(bits, Q, offset), residual, places=11)

    def test_ml_minimizes_the_same_objective_as_qubo(self):
        H = np.array([0.8 + 0.2j, -0.35 + 0.7j])
        y = -0.11 + 0.23j
        for modulation in ("BPSK", "QPSK", "16QAM", "64QAM"):
            with self.subTest(modulation=modulation):
                bits = candidate_bits(2, modulation)
                symbols = symbols_from_bits(bits, modulation)
                chosen = decode_ml(y, H, bits, symbols)
                Q, offset = qubo_from_frame(y, H, modulation)
                self.assertLessEqual(qubo_energy(chosen, Q, offset),
                                     min(qubo_energy(b, Q, offset) for b in bits) + 1e-11)

    def test_comparison_has_shared_bit_denominator_and_valid_rates(self):
        scenario = Scenario("QPSK", (100, 250, 400))
        result = compare_detectors(scenario, [-10, 0, 10], frames=25, seed=19)
        self.assertEqual(result["total_bits"], 25 * 3 * 2)
        np.testing.assert_allclose(result["errors"] / result["total_bits"],
                                   [result["ml"], result["sic"]])
        self.assertTrue(np.all((result["ml"] >= 0) & (result["ml"] <= 1)))
        self.assertTrue(np.all((result["sic"] >= 0) & (result["sic"] <= 1)))

    def test_frame_is_reproducible(self):
        scenario = Scenario("BPSK", (100, 500))
        a = draw_frame(scenario, 5, np.random.default_rng(12))
        b = draw_frame(scenario, 5, np.random.default_rng(12))
        self.assertEqual(a[0], b[0])
        np.testing.assert_array_equal(a[1], b[1])
        np.testing.assert_array_equal(a[2], b[2])


if __name__ == "__main__":
    unittest.main()
