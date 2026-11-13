# Reproduce and verify

## Prerequisites

- MATLAB/Simulink **R2024a** is the version previously recorded for the supplied model. Exact toolbox and library requirements must be checked in the target installation. Models use the block libraries referenced within their `.slx` files (Simscape Electrical/Specialized Power Systems may be required).
- **MATLAB files:** recorded `R` contains timeseries objects; `load()` and field access are most reliable inside MATLAB. Standard SciPy can identify the `R` struct but cannot automatically decode all serialized MATLAB `timeseries` objects.
- Run from a clean working folder to avoid stale `.slxc`, `slprj` and workspace variables. Simulation times in historical logs are not a benchmark.

## Method A — inspect existing measurements without simulation

```matlab
S = load('experiments/aligned/data/aligned_results.mat');
numel(S.R)             % Expected 4
S.R(1).name            % Twin + 1 ms aligned delay
t = S.R(1).Vc_up.Time;
spread = max(S.R(1).Vc_up.Data,[],2)-min(S.R(1).Vc_up.Data,[],2);
plot(t,spread); grid on;
xlabel('Time (s)'); ylabel('Upper-arm voltage spread (V)');
```

From the repository root, execute `scripts/verify_repository_data.m` (MATLAB), or `python scripts/check_repository_structure.py` (Python 3 + SciPy) to inspect file presence and dataset counts. They do **not** recompute Simulink outputs.

## Method B — rerun available cases

```matlab
run('scripts/run_base_cases.m');
run('scripts/run_aligned_cases_from_root.m');
```

These wrappers create an **isolated temporary run directory**, copy the original models and driver scripts there, then invoke the original research scripts. The original scripts add Goto/To Workspace logging blocks only to in-memory models; generated figures and `.mat` results are written to the temporary workdir, which is left in place and printed at the end. Carefully inspect these scripts before running them because `clear`, `close all`, Simulink callbacks and generated files may affect the session.

`run_aligned_cases.m` optionally compares against `followup_results.mat`, copied into the temporary work directory for reference. There is **no** independent fresh-own-delay model or original follow-up simulation driver in the uploaded inputs. That subset is only reproducible at the recorded-data analysis level.

## Validity / known limitations

1. **Core simulation**: model assembly and logging were not rerun in this environment. Prior case metrics are preserved from the user's experiments.
2. **Sampling**: To Workspace decimation places most fast signals at a 100 µs interval; a full switching-harmonic THD study needs **undecimated 10 µs** or suitably anti-aliased high-rate signals.
3. **Large MATLAB arrays**: Binary `.mat` files and `.slx` files are source-of-record. See `MANIFEST.csv` for SHA-256 verification.
4. **Delay**: The delay bound is derived for a simplified linearized consensus law with equal-time samples; clipping and deadband alter transients and residual errors.
5. **Hardware**: No proven physical RS-485/SM peer-to-peer communication, loss handling, synchronization, gate driver timings or protection test is supplied.
6. **Citation**: Numbers above are observations on specific simulated cases; do not describe them as universal performance specifications.