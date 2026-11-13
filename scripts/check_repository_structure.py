#!/usr/bin/env python3
"""Structural check of supplemental Matlab files (not a MATLAB simulation)."""
from pathlib import Path
from zipfile import ZipFile
try:
    from scipy.io import whosmat
except ImportError as exc:
    raise SystemExit("Install SciPy: python -m pip install scipy") from exc

root=Path(__file__).resolve().parents[1]
models=[
"model/MMC_Per_arm_outer_v5_G2_tests.slx",
"experiments/base/models/MMC_Per_arm_outer_v5_G2_case1_kv0.slx",
"experiments/base/models/MMC_Per_arm_outer_v5_G2_case2_imbalance.slx",
"experiments/base/models/MMC_Per_arm_outer_v5_G2_case3_base.slx",
"experiments/aligned/models/MMC_Per_arm_outer_v5_G2_case1b_delay02_aligned.slx",
"experiments/aligned/models/MMC_Per_arm_outer_v5_G2_case1b_delay1_aligned.slx",
"experiments/aligned/models/MMC_Per_arm_outer_v5_G2_case2_clip_delay1p4_aligned.slx",
"experiments/aligned/models/MMC_Per_arm_outer_v5_G2_case2_clip_delay5p5_aligned.slx",
]
datasets={
"experiments/base/data/three_cases_results.mat":3,
"experiments/followup/data/followup_results.mat":4,
"experiments/aligned/data/aligned_results.mat":4
}
for rel in models:
    f=root/rel
    assert f.exists(),f"Missing {rel}"
    with ZipFile(f) as z:
        assert any("blockdiagram.xml" in x for x in z.namelist()),f"Invalid SLX {rel}"
    print("OK SLX",rel)
for rel,expected in datasets.items():
    f=root/rel
    assert f.exists(),f"Missing {rel}"
    variables={n:shape for n,shape,_ in whosmat(f)}
    assert variables.get("R") in ((1,expected),(expected,1)),(rel,variables.get("R"))
    print("OK MAT",rel,expected,"cases")
print("PASS: 8 Simulink models and 11 recorded cases. This is not a simulation test.")
