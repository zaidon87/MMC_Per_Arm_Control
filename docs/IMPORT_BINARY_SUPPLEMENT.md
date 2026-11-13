# Import supplementary MATLAB/Simulink binary files

**Already published on GitHub:** 27 original PNG figures, full experiment gallery and figure catalog, validation documentation and integrity-check scripts. The original v5 model, MATLAB Function snapshots, MIT license and presentation remain intact.

**Still to import from the downloaded `MMC_Per_Arm_Control_Complete_Update.zip` supplement:** the new `.slx` experiment variants, archived `.mat` datasets, base-case Excel export, MATLAB experiment runners and source notes.

1. Clone `zaidon87/MMC_Per_Arm_Control` in GitHub Desktop.
2. Extract the supplemental ZIP and merge its **contents** (not the containing folder) into the local clone. Do not delete the existing `LICENSE`, `README.md`, `model/`, `src/`, `docs/`, or `results/` directories.
3. GitHub Desktop > Changes: verify files, commit the binary research supplement and **Push origin**.
4. In MATLAB, run `scripts/verify_repository_data.m`. For a lightweight structural check using SciPy, run `python scripts/check_repository_structure.py`.

**Integrity:** the figures uploaded in this round are the original PNG bytes. Figure gallery annotations do not modify the figures. The archived results were not rerun or re-derived. Follow-up standalone model variants were not provided by the original archive, so full recreation of the follow-up case group is not claimed.
