"""Recreate the classical comparison used in the project notebook."""

import argparse
import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

from noma_detection import Scenario, compare_detectors


SCENARIOS = (
    Scenario("BPSK", (100, 150, 200, 250, 300, 350, 400, 450, 500, 550), noise_dbm=-60),
    Scenario("QPSK", (100, 200, 300, 400, 500), noise_dbm=-60),
    Scenario("16QAM", (100, 300, 500), noise_dbm=-60),
    Scenario("64QAM", (100, 500), noise_dbm=-60),
)
POWERS = (-20, -10, 0, 10, 20, 30)


def run(frames=1000, seed=2024, output=Path("results/reproduced")):
    output.mkdir(parents=True, exist_ok=True)
    results = [compare_detectors(s, POWERS, frames=frames, seed=seed + i)
               for i, s in enumerate(SCENARIOS)]

    with (output / "classical_baselines.csv").open("w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["modulation", "users", "tx_dbm", "ml_errors", "sic_errors",
                         "bits_tested", "ml_ber", "sic_ber", "frames", "seed", "noise_dbm"])
        for i, (scenario, result) in enumerate(zip(SCENARIOS, results)):
            for j, power in enumerate(POWERS):
                writer.writerow([scenario.modulation, scenario.users, power,
                                 int(result["errors"][0, j]), int(result["errors"][1, j]),
                                 result["total_bits"], f"{result['ml'][j]:.8f}",
                                 f"{result['sic'][j]:.8f}", frames, seed + i, scenario.noise_dbm])

    fig, axes = plt.subplots(2, 2, figsize=(10, 7), sharex=True, sharey=True)
    for ax, scenario, result in zip(axes.flat, SCENARIOS, results):
        ax.plot(POWERS, result["ml"], "o-", color="#123c69", label="Exhaustive ML")
        ax.plot(POWERS, result["sic"], "s--", color="#c05a27", label="Hard-decision SIC")
        ax.set_title(f"{scenario.modulation}  |  {scenario.users} users")
        ax.set_yscale("log")
        ax.grid(alpha=0.25, which="both")
        ax.set_ylim(0.015, 0.7)
    for ax in axes[1]:
        ax.set_xlabel("Transmit power per user (dBm)")
    for ax in axes[:, 0]:
        ax.set_ylabel("Bit error rate")
    axes[0, 0].legend(frameon=False)
    fig.suptitle("Uplink NOMA: reproducible classical reference", fontsize=13)
    fig.tight_layout()
    fig.savefig(output / "classical_baselines.png", dpi=170)
    plt.close(fig)
    return results


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--frames", type=int, default=1000)
    parser.add_argument("--seed", type=int, default=2024)
    parser.add_argument("--output", type=Path, default=Path("results/reproduced"))
    args = parser.parse_args()
    run(args.frames, args.seed, args.output)
    print(f"Wrote {args.output / 'classical_baselines.csv'} and classical_baselines.png")
