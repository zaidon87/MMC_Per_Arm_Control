%% export_all_results.m (v2)  -  writes ALL numeric results of the three cases into ONE file: three_cases_results.xlsx
%  Run it after run_three_cases.m (uses R from the workspace; otherwise loads three_cases_results.mat).
%  Sheets:  settings          - what each case is and the parameters used
%           metrics           - every number printed by run_three_cases.m, with its expected value
%           case1_timeseries  - all Overview signals + spreads, resampled every 1 ms (2000 rows)
%           case2_timeseries  - idem
%           case3_timeseries  - idem + P_ref, P_conv / P_load / P_grid (20 ms averages) (3200 rows)
if ~exist('R', 'var'), load('three_cases_results.mat', 'R'); end
xlsx = 'three_cases_results.xlsx';
if exist(xlsx, 'file'), delete(xlsx); end
dt  = 1e-3;                                             % resampling step of the time-series sheets (s)
rs  = @(ts, tq) interp1(ts.Time, ts.Data, tq);          % resample a timeseries (matrix data handled column-wise)
spr = @(V) max(V, [], 2) - min(V, [], 2);
Vpk = 230*sqrt(2);

%% ---------------------------------------------------------------- settings sheet
S = { ...
 'case 1', 'MMC_Per_arm_outer_v5_G2_case1_kv0',       'k_v = 0 in the 16 SM controllers; P* fixed 1500 W; no PCC load; 2 s'; ...
 'case 2', 'MMC_Per_arm_outer_v5_G2_case2_imbalance', 'HB_u3 = 110 V, HB_u6 = 90 V at t = 0; k_v = 0.2; P* fixed 1500 W; no PCC load; 2 s'; ...
 'case 3', 'MMC_Per_arm_outer_v5_G2_case3_base',      'base: staircase 1500/1750/2000/2250/2500/1500 W at 0.6/1.0/1.4/1.8/2.2 s (ramped at 5 kW/s); loads 1 kW @2.4 s, +1 kW @2.7 s, -1 kW @3.0 s; 3.2 s'; ...
 'common', 'I_max',   '17 A (was 15)'; ...
 'common', 'P_max',   '2500 W (was 3000)'; ...
 'common', 'P_SLEW',  '5000 W/s (slew limit inside mmc_outer_ctrl, both arm leaders)'; ...
 'common', 'Vdc / N / Vc_nom / C', '800 V / 8 / 100 V / 2.2 mF'; ...
 'common', 'grid',    '230 V rms, 50 Hz, Lg = 2 mH, Rg = 0.1 ohm; Larm = 5 mH, Rarm = 0.5 ohm'; ...
 'common', 'rates',   'Ts = 10 us (plant, L3), Ts_ctrl = 100 us (L1, L2)'};
writetable(cell2table(S, 'VariableNames', {'scope', 'item', 'value'}), xlsx, 'Sheet', 'settings');

%% ---------------------------------------------------------------- metrics sheet (long format)
M = cell(0, 5);                                          % case | metric | value | unit | expected
for k = 1:3
    t = R(k).Vc_up.Time; s = spr(R(k).Vc_up.Data);
    for tt = [0.3 0.5 1.0 2.0]
        M(end+1, :) = {sprintf('case %d', k), sprintf('spread_up at %.1f s', tt), interp1(t, s, min(tt, t(end))), 'V', ''}; %#ok<*SAGROW>
    end
    M(end+1, :) = {sprintf('case %d', k), 'mean Vc_up at end', mean(R(k).Vc_up.Data(end, :)), 'V', '100'};
end
% case 1
t = R(1).Vc_up.Time; s = spr(R(1).Vc_up.Data); m = (t >= 0.5 & t <= 2); p = polyfit(t(m), s(m), 1);
M(end+1, :) = {'case 1', 'spread drift rate (fit 0.5-2 s)', p(1), 'V/s', '~5 (reduced model)'};
for j = 1:8, M(end+1, :) = {'case 1', sprintf('Vc_u%d at end', j), R(1).Vc_up.Data(end, j), 'V', '95..104'}; end
% case 2
t = R(2).Vc_up.Time; s = spr(R(2).Vc_up.Data);
for thr = [1 0.5]
    idx = find(s >= thr & t >= 0.17, 1, 'last');
    if isempty(idx), tc = 0.17; else, tc = t(min(idx+1, numel(t))); end
    M(end+1, :) = {'case 2', sprintf('time after which spread_up < %.1f V', thr), tc, 's', sprintf('%.2f', 0.26 + 0.02*(thr < 1))};
    M(end+1, :) = {'case 2', sprintf('  = delay after current start (0.17 s), spread < %.1f V', thr), (tc - 0.17)*1e3, 'ms', '90..110'};
end
M(end+1, :) = {'case 2', 'residual spread_up at 1 s', interp1(t, s, 1.0), 'V', '< 0.3'};
% case 3 staircase
t = R(3).P_UP.Time; P = R(3).P_UP.Data; ia = R(3).i_ac.Data; ti = R(3).i_ac.Time;
levels = [1500 1750 2000 2250 2500 1500]; win = [0.5 0.6; 0.9 1.0; 1.3 1.4; 1.7 1.8; 2.1 2.2; 2.3 2.4]; steps = [0.6 1.0 1.4 1.8 2.2];
tv1 = R(3).Vc_up.Time; V1 = R(3).Vc_up.Data(:, 1);
for i = 1:6
    m = (t >= win(i, 1) & t <= win(i, 2)); Pm = mean(P(m));
    mi = (ti >= win(i, 1) & ti <= win(i, 2));
    mv = (tv1 >= win(i, 1) & tv1 <= win(i, 2));
    tag = sprintf('level %d W [%.1f-%.1f s]', levels(i), win(i, 1), win(i, 2));
    M(end+1, :) = {'case 3', [tag ' P_meas'],              Pm,                        'W', num2str(levels(i))};
    M(end+1, :) = {'case 3', [tag ' P error'],             100*(Pm - levels(i))/levels(i), '%', '< 1'};
    M(end+1, :) = {'case 3', [tag ' i_ac peak'],           max(abs(ia(mi))),          'A', sprintf('%.2f', 2*levels(i)/Vpk)};
    M(end+1, :) = {'case 3', [tag ' Vc_u1 ripple pk-pk'],  max(V1(mv)) - min(V1(mv)), 'V', sprintf('%.1f', 5.1*levels(i)/1500)};
end
for i = 1:5
    m = (t >= steps(i) & t <= steps(i) + 0.25);
    if i < 5, ov = max(P(m)) - levels(i+1); else, ov = levels(i+1) - min(P(m)); end
    M(end+1, :) = {'case 3', sprintf('over/undershoot after step at %.1f s', steps(i)), ov, 'W', '< 25'};
end
M(end+1, :) = {'case 3', 'max m_up',  max(R(3).m_up.Data),  '-', '~0.96 at 2500 W'};
M(end+1, :) = {'case 3', 'max m_low', max(R(3).m_low.Data), '-', '~0.96 at 2500 W'};
% case 3 load test
v = R(3).v_ac.Data; tv = R(3).v_ac.Time; Nma = round(0.02/(tv(2) - tv(1)));
ma = @(x) filter(ones(1, Nma)/Nma, 1, x);
Pc = ma(v.*R(3).i_ac.Data); Pl = ma(v.*R(3).i_load.Data); Pg = ma(v.*R(3).i_grid.Data);
wins = [2.3 2.4; 2.6 2.7; 2.9 3.0; 3.1 3.2]; lab = {'no load', '1 kW', '2 kW', '1 kW again'}; expg = {'+1500', '+500', '-500', '+500'};
for i = 1:4
    m = (tv >= wins(i, 1) & tv <= wins(i, 2));
    M(end+1, :) = {'case 3', ['load test ' lab{i} ' P_conv'], mean(Pc(m)), 'W', '1500'};
    M(end+1, :) = {'case 3', ['load test ' lab{i} ' P_load'], mean(Pl(m)), 'W', ''};
    M(end+1, :) = {'case 3', ['load test ' lab{i} ' P_grid'], mean(Pg(m)), 'W', expg{i}};
    M(end+1, :) = {'case 3', ['load test ' lab{i} ' balance P_conv-P_load-P_grid'], mean(Pc(m) - Pl(m) - Pg(m)), 'W', '0 +/- 30'};
    M(end+1, :) = {'case 3', ['load test ' lab{i} ' i_grid peak'], max(abs(R(3).i_grid.Data(m))), 'A', ''};
end
writetable(cell2table(M, 'VariableNames', {'case', 'metric', 'value', 'unit', 'expected'}), xlsx, 'Sheet', 'metrics');

%% ---------------------------------------------------------------- time-series sheets (1 ms)
for k = 1:3
    tq = (0:dt:R(k).v_ac.Time(end))';
    T = table(tq, 'VariableNames', {'t_s'});
    T.v_ac_V = rs(R(k).v_ac, tq);   T.i_ac_A = rs(R(k).i_ac, tq);
    T.i_u_A  = rs(R(k).i_u, tq);    T.i_l_A  = rs(R(k).i_l, tq);
    Vu = rs(R(k).Vc_up, tq);        Vl = rs(R(k).Vc_low, tq);
    for j = 1:8, T.(sprintf('Vc_u%d_V', j)) = Vu(:, j); end
    for j = 1:8, T.(sprintf('Vc_l%d_V', j)) = Vl(:, j); end
    T.spread_up_V = spr(Vu);        T.spread_low_V = spr(Vl);
    T.P_ref_W  = rs(R(k).Pstar_ref, tq);
    T.P_meas_W = rs(R(k).P_UP, tq); T.Q_meas_var = rs(R(k).Q_UP, tq);
    T.m_up = rs(R(k).m_up, tq);     T.m_low = rs(R(k).m_low, tq);
    T.i_load_A = rs(R(k).i_load, tq); T.i_grid_A = rs(R(k).i_grid, tq);
    if k == 3
        T.P_conv_W = interp1(tv, Pc, tq); T.P_load_W = interp1(tv, Pl, tq); T.P_grid_W = interp1(tv, Pg, tq);
    end
    writetable(T, xlsx, 'Sheet', sprintf('case%d_timeseries', k));
end
fprintf('All results written to %s  (sheets: settings, metrics, case1/2/3_timeseries)\n', xlsx);