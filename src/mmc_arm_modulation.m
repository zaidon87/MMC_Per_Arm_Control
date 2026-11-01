function [m_arm, dbg] = mmc_arm_modulation(v_ac, v_pi, IsUpper, Vdc, Vc_arm, Vc_nom, i_ref, i_circ_ref, Wo, Wx)
%#codegen
% =========================================================================
% MMC_ARM_MODULATION  -  Block B4: arm voltage reference -> modulation index
% -------------------------------------------------------------------------
% Block     : "B4 Arm Voltage Modulation" inside Inner Loop and Energy Balancing
% Rate      : Ts_ctrl = 100 us
% Instances : 2 (one per arm leader)
% Purpose   : convert the required arm voltage into the modulation index
%             m_arm in [0, 1] that is broadcast to the submodules.
%               upper arm: v_arm = Vdc/2 - v_ac - v_pi
%               lower arm: v_arm = Vdc/2 + v_ac - v_pi
% Inputs    : v_ac     PCC voltage (V)
%             v_pi     current-controller output (V)
%             IsUpper  1 for the upper arm, 0 for the lower arm
%             Vdc      DC-link voltage (V)
%             Vc_arm   N x 1 capacitor voltages of the arm (V)
%             Vc_nom   nominal capacitor voltage (V)
%             i_ref, i_circ_ref, Wo, Wx   pass-through signals, DEBUG ONLY
% Outputs   : m_arm    arm modulation index in [0, 1]
%             dbg      5 x 1 debug vector = [i_ref; i_circ_ref; v_arm_ref; Wo; Wx]
% =========================================================================

%% ---------------- PARAMETERS ----------------
N          = 8;                          % submodules per arm
stack_min  = 0.5;                        % lower bound of the available stack voltage, as a fraction of N*Vc_nom (division guard)

%% ---------------- 1. arm sign ----------------
if IsUpper > 0.5                         % upper arm?
    s = 1;                               % upper arm: subtract v_ac
else                                     % lower arm
    s = -1;                              % lower arm: add v_ac
end

%% ---------------- 2. required arm voltage ----------------
v_arm_ref = Vdc/2 - s*v_ac - v_pi;       % half the DC link, minus the grid voltage (with arm sign), minus the controller correction

%% ---------------- 3. available stack voltage ----------------
V_stack = max(sum(Vc_arm), stack_min*N*Vc_nom);                    % sum of the N capacitor voltages, floored to avoid dividing by a small number

%% ---------------- 4. modulation index ----------------
m_arm = min(max(v_arm_ref/V_stack, 0), 1);                         % required / available, clamped to [0, 1] -> sent to the submodules

%% ---------------- 5. debug vector (monitoring only) ----------------
dbg = [i_ref; i_circ_ref; v_arm_ref; Wo; Wx];                      % unpacked at the root level by "Demux dbg UP"
end
