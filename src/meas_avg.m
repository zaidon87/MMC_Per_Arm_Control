function [v_ac_f, i_ac_f, i_u_f, i_l_f] = meas_avg(v_ac, i_ac, i_u, i_l)
%#codegen
% =========================================================================
% MEAS_AVG  -  Measurement filter: 10-sample moving average
% -------------------------------------------------------------------------
% Block     : "Meas Filter MA10" (root level)
% Rate      : Ts = 10 us (switching-layer rate)
% Instances : 1
% Purpose   : average the last 10 samples (= one period of the 10 kHz PWM
%             ripple) so the ripple is removed BEFORE the Rate Transition
%             blocks slow the signals down to Ts_ctrl = 100 us (no aliasing).
% Inputs    : v_ac  PCC voltage (V)        i_ac  grid current (A)
%             i_u   upper-arm current (A)  i_l   lower-arm current (A)
% Outputs   : the same four signals, filtered
% =========================================================================

%% ---------------- PARAMETERS ----------------
M = 10;                                  % window length (samples): 10 x 10 us = 100 us = one 10 kHz ripple period

%% ---------------- PERSISTENT STATES ----------------
persistent buf idx                       % buf: last M samples (M x 4 matrix); idx: next row to overwrite
if isempty(buf)                          % first call only
    buf = zeros(M, 4);                   % start with an all-zero window
    idx = 1;                             % write pointer on row 1
end

%% ---------------- 1. store the new samples ----------------
buf(idx, :) = [v_ac, i_ac, i_u, i_l];   % overwrite the oldest row with the four new samples
idx = idx + 1;                           % move the write pointer forward
if idx > M                               % past the last row?
    idx = 1;                             % wrap around (circular buffer)
end

%% ---------------- 2. average over the window ----------------
y = sum(buf, 1) / M;                     % column-wise mean -> 1 x 4 vector of averages

%% ---------------- 3. outputs ----------------
v_ac_f = y(1);                           % filtered PCC voltage
i_ac_f = y(2);                           % filtered grid current
i_u_f  = y(3);                           % filtered upper-arm current
i_l_f  = y(4);                           % filtered lower-arm current
end
