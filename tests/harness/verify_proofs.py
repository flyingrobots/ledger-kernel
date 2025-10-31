#!/usr/bin/env python3
"""
Minimal proof verifier skeleton for the Ledger‑Kernel compliance harness.

CLI:
  verify_proofs.py --proof-dir <dir> --case <yaml> --mode <branch|notes|private>

Current behavior:
  - Validates that the proof directory exists (or is empty if not provided).
  - Prints a short summary and exits 0. No deep checks yet.

Follow‑ups will add:
  - JSON Schema validation for append/attest/policy/replay proofs
  - Deterministic replay digest recomputation and comparison
  - Invariant checks (append‑only, FF‑only, temporal monotonicity, etc.)
"""

from __future__ import annotations
import argparse
import os
import sys


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Ledger‑Kernel proof verifier (skeleton)")
    p.add_argument("--proof-dir", default="", help="Directory containing emitted proofs")
    p.add_argument("--case", required=True, help="Path to the test case YAML")
    p.add_argument("--mode", default="branch", choices=["branch", "notes", "private"], help="Ledger mode")
    return p.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    proof_dir_arg = args.__dict__["proof_dir"]
    if proof_dir_arg:
        if not os.path.isdir(proof_dir_arg):
            print(f"ERROR: proof dir not found: {proof_dir_arg}", file=sys.stderr)
            return 2
        proof_dir = proof_dir_arg
    else:
        proof_dir = None

    print("verify_proofs: (skeleton)")
    print(f"- case: {args.case}")
    print(f"- mode: {args.mode}")
    print(f"- proof_dir: {proof_dir or '(none provided)'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

