# Stored MATLAB dataset schema

Each `*_results.mat` contains MATLAB variable `R`, a struct array of cases. Members are MATLAB timeseries unless marked otherwise.

| Field | Meaning |
| --- | --- |
| `Vc_up`, `Vc_low` | 8 capacitor voltages per upper/lower arm, V |
| `P_UP`, `Q_UP` | active/reactive power measurements in W / var |
| `Pstar_ref` | active-power setpoint, W |
| `v_ac` | PCC/grid-side converter AC voltage, V |
| `i_ac` | AC converter current, A |
| `i_u`, `i_l` | upper/lower arm currents, A |
| `m_up`, `m_low` | arm modulation references |
| `i_load`, `i_grid` | load and grid currents, A |
| `name` | case label (text) |
| `grid` | saved grid plot identifier (text) |

**MATLAB `timeseries`:** use `.Time` and `.Data`. Do not confuse the first capacitor dimension with time when exporting arrays; the scripts assume `Vc_*.Data` contains N time samples by 8 submodules.

The original scripts specify `SampleTime='-1'` (inherit) and a decimation factor of 10 for fast signals, such that archived `R` generally records a 100 µs interval. Power/control signals are logged without the same decimation. Always inspect `diff(R(1).i_ac.Time)` before applying an FFT.