# Import the complete binary research supplement

The existing repository's MIT license, 2026-11-01 original model, source snapshots and presentation are preserved. To add the new 8 model files, 11 recorded cases, original figures, MATLAB scripts, source notes and results:

1. Download **MMC_Per_Arm_Control_Complete_Update.zip** from the project's research handoff.
2. In GitHub Desktop, clone `zaidon87/MMC_Per_Arm_Control` onto a Windows machine.
3. **Extract the ZIP and copy its contents, not its containing directory**, into the clone. Merge existing directories. Do not delete old `src`, `model`, `docs`, `results`, `LICENSE`.
4. Inspect the diff, then commit `Add MMC per-arm research validation datasets and models` and **Push origin**.
5. In MATLAB run `scripts/verify_repository_data.m`. Or with Python 3 and SciPy: `python scripts/check_repository_structure.py`.

## What is currently online?

The November 2026 experiment/communication study documentation is available. The MATLAB binary models and MAT datasets are **not considered on GitHub until they appear in the repository tree**. GitHub Desktop can push each original dataset file; there is no need to unpack MATLAB .mat content. Neither the models nor recorded outputs were changed during packaging.

## Why is the archive substantial?

It includes 8 real Simulink source archives, 3 original binary MAT datasets (~13–14 MB each), an Excel export, 27 original PNG figures and associated MATLAB test scripts. Cached `slprj/` and `*.slxc` files were intentionally excluded.

The follow-up dataset includes four recorded trials but the original follow-up .slx variants were not provided; do not claim that particular subset is fully simulation reproducible.
