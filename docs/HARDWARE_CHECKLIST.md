# TWIST / HIL implementation checklist

The uploaded simulations do not constitute a verified embedded hardware implementation.

- [ ] Current and voltage sensor calibration, independent overcurrent/overvoltage protection
- [ ] Gate dead time, half-bridge interlocks and deterministic power-stage shutdown
- [ ] Per-SM voltage timestamp and ring-neighbor packet format (SM ID, timestamp, sequence, CRC)
- [ ] Buffer local readings to the same timestamp as delayed neighbors
- [ ] Test packet drops, stale readings, jitter and communication failure modes
- [ ] Test capacitor tolerance, voltage imbalance and long-duration drift
- [ ] Check clipping/saturation/deadband effects at all current signs
- [ ] Check arm energy, circulating current DC/100 Hz and grid-current THD
- [ ] For full switching harmonics, log high-rate currents with anti-aliasing
- [ ] Confirm real-time controller worst-case cycle costs before power-up
- [ ] Separately qualify an OPAL-RT/HIL implementation before any live hardware test

The simplified 2.78 ms bound for the aligned ring-consensus model is not a universal hardware network budget.
