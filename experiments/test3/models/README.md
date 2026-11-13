# Base test source archive: additional binaries pending import

The source `test(3).zip` is identical to the previously supplied `test.zip`; its three .slx variants and MAT files therefore correspond to the base experiments in `experiments/base/`, **not new cases**.

Extract the user-supplied ZIP and place the following files in this folder to enable exact reruns:

- `MMC_Per_arm_outer_v5_G2_case1_kv0.slx`
- `MMC_Per_arm_outer_v5_G2_case2_imbalance.slx`
- `MMC_Per_arm_outer_v5_G2_case3_base.slx`

Place `three_cases_results.mat`, `three_cases_results.xlsx` under `../data/` if numerical analyses are required. `ripplecase3.fig` may be stored under figures once imported. These files were **not added** by the text/image GitHub synchronization because they are larger binary assets. MATLAB cache files (`*.slxc`, `slprj/`) should remain excluded.

To run: keep `../scripts/run_three_cases.m` and the three .slx variants in the same MATLAB working directory (or adjust the MATLAB path), then run `run_three_cases`. The archived metrics are recorded outputs, not a guarantee of repeatability under other releases or libraries.
