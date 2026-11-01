function [i_ref, v_pi] = mmc_inner_current(i_ac_ref, i_circ_ref, i_arm, IsUpper)
%#codegen
% =========================================================================
% MMC_INNER_CURRENT  -  Block B3: arm-current controller (PI + resonant)
% -------------------------------------------------------------------------
% Block     : "B3 Inner Current Control" inside Inner Loop and Energy Balancing
% Rate      : Ts_ctrl = 100 us
% Instances : 2 (one per arm leader)
% Purpose   : build the arm-current reference (half of the grid current +
%             the circulating current) and track it with:
%               PI            -> DC and slow components
%               resonant 50 Hz -> zero error at the grid frequency
%               resonant 100 Hz (CCSC) -> suppresses the natural 2nd-harmonic
%                                         circulating current of the MMC
% Inputs    : i_ac_ref    grid-current reference (A)
%             i_circ_ref  circulating-current reference (A)
%             i_arm       measured arm current (A)
%             IsUpper     1 for the upper arm, 0 for the lower arm
% Outputs   : i_ref       arm-current reference (A), for monitoring
%             v_pi        controller output voltage (V)
% =========================================================================

%% ---------------- PARAMETERS: timing and grid ----------------
Ts = 1e-4;                               % execution period (s) = Ts_ctrl
w0 = 2*pi*50;                            % grid angular frequency (rad/s)

%% ---------------- PARAMETERS: PI + resonant 50 Hz ----------------
Kp_i     = 12;                           % proportional gain (V/A)
Ki_i     = 1200;                         % integral gain (V/(A*s))
Kr_i     = 300;                          % resonant gain at 50 Hz (V/(A*s))
xi_i_max = 300;                          % (V) integrator limit
xr_max   = 200;                          % (V) limit of the 50 Hz resonant state
v_pi_max = 400;                          % (V) controller output limit

%% ---------------- PARAMETERS: CCSC resonant 100 Hz ----------------
USE_CCSC = true;                         % true: enable the 2nd-harmonic circulating-current suppressor
Kr_2     = 300;                          % resonant gain at 100 Hz (V/(A*s))
xr2_max  = 150;                          % (V) limit of the 100 Hz resonant state

%% ---------------- PERSISTENT STATES ----------------
persistent xi_i xr1 xr2 xc1 xc2          % integrator, 50 Hz resonator (2 states), 100 Hz resonator (2 states)
if isempty(xi_i)                         % first call only
    xi_i = 0;                            % integrator (V)
    xr1  = 0;                            % 50 Hz resonator, output state (V)
    xr2  = 0;                            % 50 Hz resonator, internal state (V)
    xc1  = 0;                            % 100 Hz resonator, output state (V)
    xc2  = 0;                            % 100 Hz resonator, internal state (V)
end

%% ---------------- 1. arm sign ----------------
if IsUpper > 0.5                         % upper arm?
    s = 1;                               % upper arm carries +i_ac/2
else                                     % lower arm
    s = -1;                              % lower arm carries -i_ac/2
end

%% ---------------- 2. arm-current reference and error ----------------
i_ref = s*0.5*i_ac_ref + i_circ_ref;     % each arm carries half the grid current (opposite signs) + the same circulating current
err_i = i_ref - i_arm;                   % current error (A)

%% ---------------- 3. integral term ----------------
xi_i = min(max(xi_i + Ki_i*Ts*err_i, -xi_i_max), xi_i_max);        % integrator update, clamped

%% ---------------- 4. resonant term at 50 Hz (symplectic Euler) ----------------
xr1 = xr1 + Ts*(Kr_i*err_i - w0*xr2);    % oscillator driven by the error -> very high gain at exactly 50 Hz
xr2 = xr2 + Ts*w0*xr1;                   % second oscillator state
xr1 = min(max(xr1, -xr_max), xr_max);    % safety clamp of the resonant output

%% ---------------- 5. resonant term at 100 Hz (CCSC) ----------------
if USE_CCSC                              % suppressor enabled?
    xc1 = xc1 + Ts*(Kr_2*err_i - 2*w0*xc2);                        % oscillator at 2*w0 driven by the error
    xc2 = xc2 + Ts*2*w0*xc1;                                       % second oscillator state
    xc1 = min(max(xc1, -xr2_max), xr2_max);                        % safety clamp
end                                      % when disabled the states simply stay at zero

%% ---------------- 6. controller output ----------------
v_pi = min(max(Kp_i*err_i + xi_i + xr1 + xc1, -v_pi_max), v_pi_max);   % P + I + R50 + R100, clamped to +/- v_pi_max
end
