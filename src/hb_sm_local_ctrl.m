function [S_top, S_bot] = hb_sm_local_ctrl(sm_id, m_arm, i_arm, Vc_i, Vc_prev, Vc_next, t)
%#codegen
% =========================================================================
% HB_SM_LOCAL_CTRL  -  Submodule local controller: neighbour balancing + PSC-PWM
% -------------------------------------------------------------------------
% Block     : "Local Ctrl" inside every SM_ux / SM_lx subsystem
% Rate      : Ts = 10 us
% Instances : 16 (one per half-bridge submodule)
% Purpose   : decide the two gate signals of ONE half-bridge submodule using
%             only local information: own capacitor voltage, the two ring
%             neighbours, the arm modulation index sent by the arm leader,
%             the arm-current direction and the time base.
%             No sorting and no access to the full capacitor-voltage vector.
% Inputs    : sm_id    own index 1..N (sets the carrier phase shift)
%             m_arm    arm modulation index from the arm leader, in [0, 1]
%             i_arm    arm current (A), only its direction is used
%             Vc_i     own capacitor voltage (V)
%             Vc_prev  previous ring neighbour voltage (V)
%             Vc_next  next ring neighbour voltage (V)
%             t        simulation time (s), carrier time base
% Outputs   : S_top    upper switch gate (1 = on)  -> capacitor INSERTED (+Vc)
%             S_bot    lower switch gate (1 = on)  -> capacitor BYPASSED (0 V)
% =========================================================================

%% ---------------- PARAMETERS ----------------
N      = 8;                              % submodules per arm -> carrier phase shift of SM k = (k-1)/N of a period
fsw    = 1250;                           % carrier frequency per submodule (Hz) -> N*fsw = 10 kHz apparent arm ripple
k_v    = 0.2;                            % balancing gain (1/V): modulation-index change per volt of error
dead   = 0.1;                            % dead-band (V): errors smaller than this are ignored (no chattering)
Iscale = 1.0;                            % current scale (A) of the smooth sign function tanh(i_arm/Iscale)

%% ---------------- 1. neighbour-average balancing correction ----------------
err  = 0.5*(Vc_prev + Vc_next) - Vc_i;   % error = neighbour average - own voltage (> 0: I am too low, I need charging)
if abs(err) < dead                       % error inside the dead-band?
    err = 0;                             % ignore it
end
dirn = tanh(i_arm / Iscale);             % smooth current direction in (-1, +1); > 0 means inserting CHARGES the capacitor
dm   = k_v * err * dirn;                 % correction: insert more if charging is needed AND the current charges, less otherwise
m_i  = min(max(m_arm + dm, 0), 1);       % own modulation index = arm index + correction, clamped to [0, 1]

%% ---------------- 2. phase-shifted triangular carrier (0 -> 1 -> 0) ----------------
tau = mod(t*fsw + (sm_id - 1)/N, 1);     % position inside the carrier period, in [0, 1), shifted by (sm_id-1)/N
car = 1 - abs(2*tau - 1);                % triangle: rises 0 -> 1 on the first half, falls 1 -> 0 on the second half

%% ---------------- 3. half-bridge gating ----------------
if m_i >= car                            % modulation index above the carrier?
    S_top = 1;                           % upper switch on  -> capacitor inserted (+Vc on the arm)
    S_bot = 0;                           % lower switch off
else                                     % modulation index below the carrier
    S_top = 0;                           % upper switch off
    S_bot = 1;                           % lower switch on  -> capacitor bypassed (0 V)
end
end
