function [i_ac_ref, theta, V_amp, P_meas, Q_meas] = mmc_outer_ctrl(v_ac, i_ac, Pstar, Qstar, t)
%#codegen
% =========================================================================
% MMC_OUTER_CTRL  -  Outer loop: grid synchronisation (SOGI-PLL) + P/Q control
% -------------------------------------------------------------------------
% Block     : "Outer Loop" inside Arm Leader UPPER and Arm Leader LOWER
% Rate      : Ts_ctrl = 100 us
% Instances : 2 (one per arm leader)
% Purpose   : build the grid-current reference i_ac_ref from the power
%             set-points. Both arm leaders run this identical code on the
%             same measurements, so they obtain the SAME i_ac_ref without
%             exchanging any data.
%   1. SOGI on v_ac and i_ac   -> orthogonal (alpha, beta) components
%   2. SOGI-PLL                -> theta locked on v_ac  (v_alpha = V_amp*cos(theta))
%   3. P = 0.5*(va*ia + vb*ib),  Q = 0.5*(va*ib - vb*ia)   (Q > 0: current LEADS voltage)
%   4. P/Q PI loops + feed-forward -> current components Ip, Iq
%   5. i_ac_ref = Ip*cos(theta) - Iq*sin(theta)
% Inputs    : v_ac   PCC voltage (V)          i_ac   grid current (A)
%             Pstar  active-power set-point (W)   Qstar  reactive-power set-point (var)
%             t      simulation time (s), used for the soft start
% Outputs   : i_ac_ref (A), theta (rad), V_amp (V), P_meas (W), Q_meas (var)
% =========================================================================

%% ---------------- PARAMETERS: timing and grid ----------------
Ts      = 1e-4;                          % execution period (s) = Ts_ctrl
f0      = 50;                            % grid frequency (Hz)
w0      = 2*pi*f0;                       % grid angular frequency (rad/s)
USE_PLL = true;                          % true: PLL locked on v_ac (grid-connected); false: free-running 50 Hz angle (standalone tests)
NMA     = 200;                           % moving-average length for P and Q: 200 x 100 us = 20 ms = one grid period

%% ---------------- PARAMETERS: soft start ----------------
T_START = 0.15;                          % (s) references held at zero until the PLL has locked
PQ_RAMP = 10000;                         % (W/s and var/s) reference ramp rate after T_START

%% ---------------- PARAMETERS: SOGI and PLL ----------------
k_sogi = 1.41;                           % SOGI gain -> bandwidth ~ k*f0/2 = 35 Hz
Kp_pll = 50;                             % PLL proportional gain (rad/s per p.u. of vq)
Ki_pll = 1000;                           % PLL integral gain -> wn = 32 rad/s (5 Hz), zeta = 0.79
dw_max = 2*pi*5;                         % PLL integrator limit (rad/s) = +/- 5 Hz around f0
V_min  = 20;                             % (V) lower bound of the measured amplitude (division guard)
V_init = 300;                            % (V) initial amplitude estimate (close to the 325 V grid peak)
tau_v  = 0.01;                           % (s) low-pass time constant on the amplitude

%% ---------------- PARAMETERS: P and Q loops ----------------
% plant: P = 0.5*V_amp*Ip  ~ 163 W/A at 325 V  ->  closed-loop bandwidth ~ 5 Hz
Kp_pq = 0.004;                           % proportional gain (A/W)
Ki_pq = 0.2;                             % integral gain (A/(W*s))
I_max = 15;                              % (A) amplitude limit of each current component Ip, Iq
P_max = 3000;                            % (W)   active-power reference limit
Q_max = 2000;                            % (var) reactive-power reference limit

%% ---------------- PERSISTENT STATES ----------------
persistent th pll_i v_alpha v_beta i_alpha i_beta Vf bufP bufQ idx xi_p xi_q
if isempty(th)                           % first call only
    th      = 0;                         % PLL angle (rad)
    pll_i   = 0;                         % PLL integrator (rad/s)
    v_alpha = 0;                         % SOGI in-phase state of the voltage (V)
    v_beta  = 0;                         % SOGI quadrature state of the voltage (V)
    i_alpha = 0;                         % SOGI in-phase state of the current (A)
    i_beta  = 0;                         % SOGI quadrature state of the current (A)
    Vf      = V_init;                    % filtered voltage amplitude (V)
    bufP    = zeros(NMA, 1);             % circular buffer of instantaneous P (W)
    bufQ    = zeros(NMA, 1);             % circular buffer of instantaneous Q (var)
    idx     = 1;                         % buffer write pointer
    xi_p    = 0;                         % integrator of the P loop (A)
    xi_q    = 0;                         % integrator of the Q loop (A)
end

%% ---------------- 1. SOGI filters (symplectic Euler: unity gain at w0) ----------------
v_alpha = v_alpha + Ts*(k_sogi*w0*(v_ac - v_alpha) - w0*v_beta);   % in-phase voltage component, band-passed at f0
v_beta  = v_beta  + Ts*w0*v_alpha;                                 % quadrature voltage component (lags by 90 deg)
i_alpha = i_alpha + Ts*(k_sogi*w0*(i_ac - i_alpha) - w0*i_beta);   % in-phase current component
i_beta  = i_beta  + Ts*w0*i_alpha;                                 % quadrature current component

%% ---------------- 2. voltage amplitude and PLL angle ----------------
Vn    = max(sqrt(v_alpha^2 + v_beta^2), V_min);                    % instantaneous amplitude, floored at V_min
Vf    = Vf + (Ts/(tau_v + Ts))*(Vn - Vf);                          % first-order low-pass filter (tau_v)
V_amp = Vf;                                                        % output: filtered amplitude
if USE_PLL                                                         % grid-connected mode
    vq    = (-sin(th)*v_alpha + cos(th)*v_beta)/Vn;                % normalised q-axis error (p.u.); zero when th is right
    pll_i = min(max(pll_i + Ki_pll*Ts*vq, -dw_max), dw_max);       % PI integrator, clamped to +/- dw_max
    th    = mod(th + (w0 + Kp_pll*vq + pll_i)*Ts, 2*pi);           % integrate the frequency, wrap to [0, 2*pi)
else                                                               % standalone mode
    th    = mod(w0*t, 2*pi);                                       % free-running angle at exactly f0
end
theta = th;                                                        % output: grid angle

%% ---------------- 3. measured P and Q (instantaneous, then 20 ms average) ----------------
bufP(idx) = 0.5*(v_alpha*i_alpha + v_beta*i_beta);                 % instantaneous active power (0.5: amplitudes, not RMS)
bufQ(idx) = 0.5*(v_alpha*i_beta  - v_beta*i_alpha);                % instantaneous reactive power (> 0: current leads)
idx = idx + 1;                                                     % advance the write pointer
if idx > NMA                                                       % past the end of the buffer?
    idx = 1;                                                       % wrap around
end
P_meas = sum(bufP)/NMA;                                            % 20 ms average -> removes 50 / 100 Hz residuals
Q_meas = sum(bufQ)/NMA;                                            % same for Q

%% ---------------- 4. soft-started references ----------------
if t < T_START                                                     % before the PLL has locked
    P_use = 0;                                                     % no active-power reference yet
    Q_use = 0;                                                     % no reactive-power reference yet
else                                                               % after T_START
    lim   = PQ_RAMP*(t - T_START);                                 % ramp envelope, grows linearly with time
    P_use = min(max(Pstar, -P_max), P_max);                        % clamp the set-point to +/- P_max
    P_use = min(max(P_use, -lim),   lim);                          % then clamp it to the ramp envelope
    Q_use = min(max(Qstar, -Q_max), Q_max);                        % same for Q with +/- Q_max
    Q_use = min(max(Q_use, -lim),   lim);                          % and the same ramp envelope
end

%% ---------------- 5. P and Q loops -> current components (feed-forward + PI, clamping anti-windup) ----------------
Ip_ff = 2*P_use/V_amp;                                             % feed-forward: P = 0.5*V*I  ->  I = 2P/V
Iq_ff = 2*Q_use/V_amp;                                             % same for Q
e_p   = P_use - P_meas;                                            % active-power error (W)
e_q   = Q_use - Q_meas;                                            % reactive-power error (var)
Ip_un = Ip_ff + Kp_pq*e_p + xi_p;                                  % unsaturated active current (A)
if abs(Ip_un) < I_max                                              % integrate only when NOT saturated (anti-windup)
    xi_p = min(max(xi_p + Ki_pq*Ts*e_p, -I_max), I_max);           % integrator update, clamped
end
Iq_un = Iq_ff + Kp_pq*e_q + xi_q;                                  % unsaturated reactive current (A)
if abs(Iq_un) < I_max                                              % same anti-windup rule
    xi_q = min(max(xi_q + Ki_pq*Ts*e_q, -I_max), I_max);           % integrator update, clamped
end
Ip = min(max(Ip_un, -I_max), I_max);                               % final clamp of the active current
Iq = min(max(Iq_un, -I_max), I_max);                               % final clamp of the reactive current

%% ---------------- 6. AC current reference ----------------
i_ac_ref = Ip*cos(theta) - Iq*sin(theta);                          % in-phase (P) + quadrature (Q) components
end
