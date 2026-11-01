function i_circ_ref = mmc_energy_balancing(Wo, Wx, W_nom, P_meas, Vdc, V_amp, theta, IsUpper)
%#codegen
% =========================================================================
% MMC_ENERGY_BALANCING  -  Block B2: total and differential arm-energy control
% -------------------------------------------------------------------------
% Block     : "B2 Energy Balancing Control" inside Inner Loop and Energy Balancing
% Rate      : Ts_ctrl = 100 us
% Instances : 2 (one per arm leader)
% Purpose   : keep the TOTAL energy of the two arms at its nominal value and
%             the DIFFERENCE between the arms at zero, by shaping the
%             circulating-current reference:
%               total energy error       -> DC component     i_dc_ref
%               differential energy error -> 50 Hz component I_dif*cos(theta)
% Inputs    : Wo       filtered own-arm energy (J)
%             Wx       filtered other-arm energy (J)
%             W_nom    nominal arm energy (J)
%             P_meas   measured active power (W), used as feed-forward
%             Vdc      DC-link voltage (V)
%             V_amp    PCC voltage amplitude (V)
%             theta    grid angle (rad)
%             IsUpper  1 for the upper arm, 0 for the lower arm
% Outputs   : i_circ_ref  circulating-current reference (A)
% =========================================================================

%% ---------------- PARAMETERS: timing ----------------
Ts = 1e-4;                               % execution period (s) = Ts_ctrl

%% ---------------- PARAMETERS: total (sum) energy loop -> DC circulating current ----------------
Kp_s     = 0.03;                         % proportional gain (A/J)
Ki_s     = 0.3;                          % integral gain (A/(J*s))
xi_s_max = 3;                            % (A) integrator limit
i_dc_max = 5;                            % (A) DC circulating-current limit

%% ---------------- PARAMETERS: differential energy loop -> 50 Hz circulating current ----------------
Kp_d      = 25;                          % proportional gain (V/J)
Ki_d      = 150;                         % integral gain (V/(J*s))
xi_d_max  = 300;                         % (V) integrator limit
I_dif_max = 3;                           % (A) amplitude limit of the 50 Hz component
V_min     = 50;                          % (V) lower bound of V_amp in the division (guard)

%% ---------------- PERSISTENT STATES ----------------
persistent xi_s xi_d                     % integrators of the sum loop (A) and of the differential loop (V)
if isempty(xi_s)                         % first call only
    xi_s = 0;                            % sum-loop integrator starts at zero
    xi_d = 0;                            % differential-loop integrator starts at zero
end

%% ---------------- 1. arm sign ----------------
if IsUpper > 0.5                         % upper arm?
    s = 1;                               % +1: the upper arm corrects in one direction...
else                                     % lower arm
    s = -1;                              % -1: ...and the lower arm in the opposite direction
end

%% ---------------- 2. total energy -> DC circulating-current component ----------------
e_sum   = 2*W_nom - (Wo + Wx);           % total energy error: nominal of both arms - (own + other) (> 0: arms need charging)
i_dc_un = P_meas/Vdc + Kp_s*e_sum + xi_s;                          % feed-forward P/Vdc (DC current the converter must draw) + PI
if abs(i_dc_un) < i_dc_max                                         % integrate only when NOT saturated (anti-windup)
    xi_s = min(max(xi_s + Ki_s*Ts*e_sum, -xi_s_max), xi_s_max);    % integrator update, clamped
end
i_dc_ref = min(max(i_dc_un, -i_dc_max), i_dc_max);                 % final clamp of the DC component

%% ---------------- 3. differential energy -> 50 Hz circulating-current component ----------------
e_dif    = Wo - Wx;                                                % energy difference own - other (J)
u_dif    = Kp_d*e_dif + xi_d;                                      % PI output as a "voltage" (V)
I_dif_un = s*u_dif/max(V_amp, V_min);                              % to a current amplitude: energy moves between arms through a 50 Hz current acting on v_ac
if abs(I_dif_un) < I_dif_max                                       % anti-windup rule
    xi_d = min(max(xi_d + Ki_d*Ts*e_dif, -xi_d_max), xi_d_max);    % integrator update, clamped
end
I_dif = min(max(I_dif_un, -I_dif_max), I_dif_max);                 % final clamp of the 50 Hz amplitude

%% ---------------- 4. circulating-current reference ----------------
i_circ_ref = i_dc_ref + I_dif*cos(theta);                          % DC component + 50 Hz component in phase with v_ac
end
