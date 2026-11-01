function [Vc_i, Vc_prev, Vc_next] = get_neighbors(Vc_arm, i)
%#codegen
% =========================================================================
% GET_NEIGHBORS  -  Ring-link emulation for submodule number i
% -------------------------------------------------------------------------
% Block     : "Neighbors" inside every SM_ux / SM_lx subsystem
% Rate      : Ts = 10 us
% Instances : 16 (one per submodule)
% Purpose   : in simulation the whole capacitor-voltage vector of the arm is
%             available, but a real submodule only knows its OWN voltage and
%             the voltages of its two ring neighbours. This block hides
%             everything else, so the local controller stays truly local.
% Inputs    : Vc_arm  N x 1 vector of capacitor voltages of the arm (V)
%             i       own submodule index, 1..N
% Outputs   : Vc_i    own capacitor voltage (V)
%             Vc_prev voltage of the previous ring neighbour (V)
%             Vc_next voltage of the next ring neighbour (V)
% =========================================================================

%% ---------------- PARAMETERS ----------------
N = 8;                                   % submodules per arm (= length of Vc_arm, the Mux of the 8 HB voltages)

%% ---------------- 1. own index, made safe ----------------
k = min(max(round(i), 1), N);            % round to an integer and clamp to [1, N] (protects against a bad sm_id)

%% ---------------- 2. own voltage ----------------
Vc_i = Vc_arm(k);                        % own capacitor voltage

%% ---------------- 3. ring neighbours (circular: SM1 and SMN are neighbours) ----------------
if k == 1                                % first submodule of the ring
    Vc_prev = Vc_arm(N);                 % previous neighbour wraps around to the last submodule
    Vc_next = Vc_arm(2);                 % next neighbour is SM2
elseif k == N                            % last submodule of the ring
    Vc_prev = Vc_arm(N - 1);             % previous neighbour is SM(N-1)
    Vc_next = Vc_arm(1);                 % next neighbour wraps around to SM1
else                                     % any submodule in the middle
    Vc_prev = Vc_arm(k - 1);             % previous neighbour
    Vc_next = Vc_arm(k + 1);             % next neighbour
end
end
