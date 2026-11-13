%% run_three_cases.m  (v2)  -  runs the three research cases, prints metrics, saves figures and OVERVIEW GRIDS
%  v2: models built directly from the working MMC_Per_arm_outer_v5_G2_tests.slx with NO added blocks;
%      the logging blocks below inherit the signal's own sample time (no forced rates).
%  Put this file in the same folder as the three .slx files and run it from there (R2024a).
%  Case 1 : k_v = 0           (local balancing disabled)            -> expect spread to grow ~5 V/s
%  Case 2 : HB_u3 = 110 V, HB_u6 = 90 V at t = 0                    -> expect < 1 V within ~0.1 s after current starts
%  Case 3 : base case, I_max = 17 A, P_max = 2500 W, P_SLEW = 5 kW/s (inside mmc_outer_ctrl), staircase 1500..2500 W + PCC load test
%  Outputs: three_cases_metrics.txt, three_cases_results.mat, fig1..fig5 PNG,
%           grid_case1_kv0.png / grid_case2_imbalance.png / grid_case3_base.png  (same 3x2 layout as the model's
%           "Overview" scope, one per case) and grid_all_cases.png (6 rows x 3 cases, side by side).
%  Logging blocks are added to each model in memory only (nothing is saved back to the .slx files).
clear; clc; close all;
diary('three_cases_metrics.txt'); diary on;

cases = { ...
  'MMC_Per_arm_outer_v5_G2_case1_kv0',       'Case 1: k_v = 0 (no local balancing)',                      'grid_case1_kv0'; ...
  'MMC_Per_arm_outer_v5_G2_case2_imbalance', 'Case 2: initial imbalance HB_u3 = 110 V, HB_u6 = 90 V',     'grid_case2_imbalance'; ...
  'MMC_Per_arm_outer_v5_G2_case3_base',      'Case 3: base, I_max = 17 A, P_max = 2500 W, P_SLEW = 5 kW/s', 'grid_case3_base'};
% tag, decimation of the logger (sample time is INHERITED from the signal: Ts-rate signals decimated by 10 -> 100 us)
tags = {'Vc_up','10'; 'Vc_low','10'; 'P_UP','1'; 'Q_UP','1'; 'Pstar_ref','1'; ...
        'v_ac','10'; 'i_ac','10'; 'i_u','10'; 'i_l','10'; 'm_up','10'; 'm_low','10'; 'i_load','10'; 'i_grid','10'};

R = struct();
for k = 1:size(cases,1)
    mdl = cases{k,1};
    load_system(mdl);
    for j = 1:size(tags,1)
        tg = tags{j,1};
        add_block('simulink/Signal Routing/From', [mdl '/LOG_From_' tg], 'GotoTag', tg, ...
                  'Position', [2400 100+40*j 2470 126+40*j]);
        add_block('simulink/Sinks/To Workspace', [mdl '/LOG_To_' tg], 'VariableName', tg, ...
                  'SaveFormat', 'Timeseries', 'SampleTime', '-1', 'Decimation', tags{j,2}, 'Position', [2520 100+40*j 2600 126+40*j]);
        add_line(mdl, ['LOG_From_' tg '/1'], ['LOG_To_' tg '/1']);
    end
    fprintf('Running %s ...\n', mdl); tic;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    fprintf('  done in %.0f s\n', toc);
    for j = 1:size(tags,1)
        R(k).(tags{j,1}) = out.get(tags{j,1});     % timeseries objects
    end
    R(k).name = cases{k,2};  R(k).grid = cases{k,3};
    close_system(mdl, 0);                          % discard the temporary logging blocks
end

%% ------------------------------------------------------------------ metrics: capacitor-voltage spread
spread = @(ts) max(ts.Data,[],2) - min(ts.Data,[],2);
fprintf('\n==== CAPACITOR-VOLTAGE SPREAD  max(Vc) - min(Vc), upper arm ====\n');
for k = 1:3
    t = R(k).Vc_up.Time; s = spread(R(k).Vc_up);
    at = @(tt) interp1(t, s, min(tt, t(end)));
    fprintf('%-62s 0.3 s: %5.2f V | 0.5 s: %5.2f V | 1.0 s: %5.2f V | 2.0 s: %5.2f V\n', ...
            R(k).name, at(0.3), at(0.5), at(1.0), at(2.0));
end
t = R(1).Vc_up.Time; s = spread(R(1).Vc_up); m = (t >= 0.5 & t <= 2); p = polyfit(t(m), s(m), 1);
fprintf('Case 1 drift rate of the spread (fit 0.5-2 s): %.2f V/s   (reduced model predicted ~5 V/s)\n', p(1));
fprintf('Case 1 end of run: per-SM Vc_up = %s V\n', mat2str(round(R(1).Vc_up.Data(end,:), 2)));

t = R(2).Vc_up.Time; s = spread(R(2).Vc_up);
for thr = [1 0.5]
    idx = find(s >= thr & t >= 0.17, 1, 'last');
    if isempty(idx), tc = 0.17; else, tc = t(min(idx+1, numel(t))); end
    fprintf('Case 2 convergence (spread < %.1f V from then on): t = %.3f s  (%.0f ms after the current starts at ~0.17 s)\n', ...
            thr, tc, (tc-0.17)*1e3);
end
fprintf('Case 2 mean Vc_up at end: %.2f V | residual spread at 1 s: %.2f V\n', mean(R(2).Vc_up.Data(end,:)), interp1(t, s, 1.0));

%% ------------------------------------------------------------------ metrics: case 3 staircase
t = R(3).P_UP.Time; P = R(3).P_UP.Data;
levels = [1500 1750 2000 2250 2500 1500];
win    = [0.5 0.6; 0.9 1.0; 1.3 1.4; 1.7 1.8; 2.1 2.2; 2.3 2.4];
steps  = [0.6 1.0 1.4 1.8 2.2];
Vpk    = 230*sqrt(2);
fprintf('\n==== CASE 3: P* staircase tracking (P_meas of the UPPER arm leader, 20 ms average) ====\n');
ia = R(3).i_ac.Data; ti = R(3).i_ac.Time;
for i = 1:6
    m = (t >= win(i,1) & t <= win(i,2)); Pm = mean(P(m));
    mi = (ti >= win(i,1) & ti <= win(i,2)); Ipk = max(abs(ia(mi)));
    fprintf('level %4d W  [%.1f-%.1f s]  P_meas = %6.0f W  err = %+5.0f W (%+.1f %%)  i_ac peak = %5.2f A (2P/V = %5.2f A)\n', ...
            levels(i), win(i,1), win(i,2), Pm, Pm-levels(i), 100*(Pm-levels(i))/levels(i), Ipk, 2*levels(i)/Vpk);
end
for i = 1:5
    m = (t >= steps(i) & t <= steps(i)+0.25);
    if i < 5, ov = max(P(m)) - levels(i+1); else, ov = levels(i+1) - min(P(m)); end
    fprintf('step at %.1f s: over/undershoot = %+5.0f W (%.0f %% of the %d W step)\n', steps(i), ov, 100*ov/abs(levels(i+1)-levels(i)), abs(levels(i+1)-levels(i)));
end
mu = R(3).m_up.Data; fprintf('Case 3 max modulation index: m_up = %.3f, m_low = %.3f (must stay < 1)\n', max(mu), max(R(3).m_low.Data));

%% ------------------------------------------------------------------ metrics: case 3 PCC load test
v = R(3).v_ac.Data; tv = R(3).v_ac.Time; Tsim = tv(2)-tv(1); Nma = round(0.02/Tsim);
ma = @(x) filter(ones(1,Nma)/Nma, 1, x);
Pc = ma(v.*R(3).i_ac.Data); Pl = ma(v.*R(3).i_load.Data); Pg = ma(v.*R(3).i_grid.Data);
wins = [2.3 2.4; 2.6 2.7; 2.9 3.0; 3.1 3.2]; lab = {'no load','1 kW','2 kW','1 kW again'};
fprintf('\n==== CASE 3: PCC load test (v_ac x i, 20 ms moving average) ====\n');
for i = 1:4
    m = (tv >= wins(i,1) & tv <= wins(i,2));
    fprintf('%-12s P_conv = %5.0f W  P_load = %5.0f W  P_grid = %+5.0f W  | P_conv - P_load - P_grid = %+4.0f W  | i_grid peak = %5.2f A\n', ...
            lab{i}, mean(Pc(m)), mean(Pl(m)), mean(Pg(m)), mean(Pc(m)-Pl(m)-Pg(m)), max(abs(R(3).i_grid.Data(m))));
end
diary off;

%% ------------------------------------------------------------------ analysis figures
f1 = figure('Name','fig1_spread_kv_on_vs_off'); hold on; grid on;
for k = [3 1], plot(R(k).Vc_up.Time, spread(R(k).Vc_up), 'LineWidth', 1.2, 'DisplayName', R(k).name); end
xlim([0 2]); xlabel('t (s)'); ylabel('max(Vc_{up}) - min(Vc_{up})  (V)');
legend('Location','northwest'); title('Local balancing ON (case 3) vs OFF (case 1)');

f2 = figure('Name','fig2_case2_initial_imbalance');
subplot(2,1,1); plot(R(2).Vc_up.Time, R(2).Vc_up.Data); grid on; xlim([0 0.6]); ylabel('Vc_{up} (V)');
title(R(2).name); legend(compose('HB\\_u%d', 1:8), 'NumColumns', 4, 'Location', 'northeast');
subplot(2,1,2); plot(R(2).Vc_up.Time, spread(R(2).Vc_up), 'LineWidth', 1.2); grid on; xlim([0 0.6]);
xlabel('t (s)'); ylabel('spread (V)');

f3 = figure('Name','fig3_case3_staircase');
subplot(2,1,1); plot(R(3).Pstar_ref.Time, R(3).Pstar_ref.Data, 'k--', R(3).P_UP.Time, R(3).P_UP.Data, 'LineWidth', 1.1);
grid on; ylabel('P (W)'); legend('P^*', 'P_{meas}', 'Location', 'southeast'); title(R(3).name);
subplot(2,1,2); plot(R(3).i_ac.Time, R(3).i_ac.Data); grid on; ylabel('i_{ac} (A)'); xlabel('t (s)');

f4 = figure('Name','fig4_case3_load_test');
plot(tv, [Pc Pl Pg], 'LineWidth', 1.1); grid on; xlim([2.2 3.2]); xlabel('t (s)'); ylabel('W');
legend('P_{conv}', 'P_{load}', 'P_{grid}', 'Location', 'southwest'); title('PCC load test: power split (20 ms average)');

f5 = figure('Name','fig5_case3_Vc_ripple_vs_P');
plot(R(3).Vc_up.Time, R(3).Vc_up.Data); grid on; xlabel('t (s)'); ylabel('Vc_{up} (V)');
title('Capacitor voltages during the staircase (ripple grows with P)');

for f = [f1 f2 f3 f4 f5], exportgraphics(f, [get(f,'Name') '.png'], 'Resolution', 150); end

%% ------------------------------------------------------------------ OVERVIEW GRIDS (same 3x2 layout as the model's Overview scope)
for k = 1:3
    fg = overview_grid(R(k), R(k).name);
    exportgraphics(fg, [R(k).grid '.png'], 'Resolution', 150);
end
% one combined figure: 6 rows (the six Overview panels) x 3 columns (the three cases)
fa = figure('Name', 'grid_all_cases', 'Position', [50 50 1900 1400]);
rows = {'v_ac (V), 20*i_ac (A)', 'i_u, i_l (A)', 'Vc upper (8 SM)', 'Vc lower (8 SM)', 'P (W), Q (var)', 'm_up, m_low'};
for k = 1:3
    for r = 1:6
        subplot(6, 3, (r-1)*3 + k); overview_panel(R(k), r); grid on;
        if r == 1, title(R(k).name, 'Interpreter', 'none', 'FontSize', 9); end
        if k == 1, ylabel(rows{r}, 'Interpreter', 'none'); end
        if r == 6, xlabel('t (s)'); end
    end
end
exportgraphics(fa, 'grid_all_cases.png', 'Resolution', 120);
save('three_cases_results.mat', 'R');
fprintf('\nSaved: three_cases_metrics.txt, three_cases_results.mat, fig1..fig5, grid_case*.png, grid_all_cases.png\n');

%% ================================================================== local functions
function fg = overview_grid(Rk, ttl)
% Reproduces the model's "Overview" scope: left column v_ac/i_ac, i_u/i_l, Vc upper; right column Vc lower, P/Q, m.
    fg = figure('Name', ttl, 'Position', [50 50 1900 950]);
    order = [1 4 2 5 3 6];                      % panel index for subplot positions 1..6 (row-major 3x2)
    for p = 1:6
        subplot(3, 2, p); overview_panel(Rk, order(p)); grid on;
        if p >= 5, xlabel('t (s)'); end
    end
    sgtitle(ttl, 'Interpreter', 'none');
end

function overview_panel(Rk, which)
% which: 1 v_ac & 20*i_ac | 2 i_u, i_l | 3 Vc upper | 4 Vc lower | 5 P, Q | 6 m_up, m_low
    switch which
        case 1
            plot(Rk.v_ac.Time, Rk.v_ac.Data, Rk.i_ac.Time, 20*Rk.i_ac.Data);
            title('v_ac (V), 20*i_ac (A)', 'Interpreter', 'none'); legend('v_ac meas', '20 x i_ac', 'Interpreter', 'none');
        case 2
            plot(Rk.i_u.Time, Rk.i_u.Data, Rk.i_l.Time, Rk.i_l.Data);
            title('i_u, i_l (A)', 'Interpreter', 'none'); legend('i_u meas', 'i_l meas', 'Interpreter', 'none');
        case 3
            plot(Rk.Vc_up.Time, Rk.Vc_up.Data);
            title('Vc upper (8 SM)'); legend(compose('HB\\_u%d', 1:8), 'NumColumns', 4);
        case 4
            plot(Rk.Vc_low.Time, Rk.Vc_low.Data);
            title('Vc lower (8 SM)'); legend(compose('HB\\_l%d', 1:8), 'NumColumns', 4);
        case 5
            plot(Rk.P_UP.Time, Rk.P_UP.Data, Rk.Q_UP.Time, Rk.Q_UP.Data);
            title('P (W), Q (var)'); legend('P_{meas}', 'Q_{meas}');
            if isfield(Rk, 'Pstar_ref'), hold on; plot(Rk.Pstar_ref.Time, Rk.Pstar_ref.Data, 'k--'); legend('P_{meas}', 'Q_{meas}', 'P^*'); end
        case 6
            plot(Rk.m_up.Time, Rk.m_up.Data, Rk.m_low.Time, Rk.m_low.Data);
            title('m_up, m_low', 'Interpreter', 'none'); legend('m_up', 'm_low', 'Interpreter', 'none');
    end
end