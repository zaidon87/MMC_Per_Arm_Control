function [W_arm, Wo, Wx, W_nom] = mmc_energy_estimation(Vc_arm, W_other, Vc_nom)
%#codegen
% =========================================================================
% MMC_ENERGY_ESTIMATION  -  Block B1: arm energy estimation and filtering
% -------------------------------------------------------------------------
% Block     : "B1 Arm Energy Estimation" inside Inner Loop and Energy Balancing
% Rate      : Ts_ctrl = 100 us
% Instances : 2 (one per arm leader)
% Purpose   : compute the energy stored in the own arm, average it and the
%             energy received from the other arm over one grid period, and
%             give the nominal arm energy used as the balancing target.
% Inputs    : Vc_arm   N x 1 capacitor voltages of the own arm (V)
%             W_other  raw energy received from the other arm leader (J)
%             Vc_nom   nominal capacitor voltage (V)
% Outputs   : W_arm    raw own energy (J)  -> sent to the other arm leader
%             Wo       filtered own energy (J)
%             Wx       filtered other-arm energy (J)
%             W_nom    nominal arm energy (J)
% =========================================================================

%% ---------------- PARAMETERS ----------------
C   = 2.2e-3;                            % submodule capacitance (F)
N   = 8;                                 % submodules per arm
NMA = 200;                               % moving-average length: 200 x 100 us = 20 ms = one grid period

%% ---------------- 1. nominal arm energy (balancing target) ----------------
W_nom = 0.5*C*N*Vc_nom^2;                % energy if all N capacitors sit exactly at Vc_nom

%% ---------------- PERSISTENT STATES ----------------
persistent bufO bufX idx                 % bufO: own-energy buffer; bufX: other-arm buffer; idx: write pointer
if isempty(idx)                          % first call only
    bufO = W_nom*ones(NMA, 1);           % pre-fill with the nominal energy (avoids a false start-up error)
    bufX = W_nom*ones(NMA, 1);           % same for the other arm
    idx  = 1;                            % write pointer on row 1
end

%% ---------------- 2. raw arm energy ----------------
W_arm = 0.5*C*sum(Vc_arm.^2);            % actual stored energy = sum over the N capacitors of 0.5*C*Vc^2

%% ---------------- 3. moving average of both energies ----------------
bufO(idx) = W_arm;                       % store the new own energy
bufX(idx) = W_other;                     % store the new other-arm energy
idx = idx + 1;                           % advance the write pointer
if idx > NMA                             % past the end of the buffer?
    idx = 1;                             % wrap around
end
Wo = sum(bufO)/NMA;                      % filtered own energy (50 / 100 Hz ripple removed)
Wx = sum(bufX)/NMA;                      % filtered other-arm energy
end
