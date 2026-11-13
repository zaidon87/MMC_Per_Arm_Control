%% run_aligned_cases.m  -  time-ALIGNED neighbour-link delay (own sample delayed by the same tau): the eq. (6) test
%  Same structure as run_followup_cases.m. Put this file in the same folder as the .slx files and run it (R2024a).
%    1. MMC_Per_arm_outer_v5_G2_case1b_delay1_aligned.slx        twin + 1 ms aligned delay     (counterpart of the unstable fresh-sample run)
%    2. MMC_Per_arm_outer_v5_G2_case1b_delay02_aligned.slx       twin + 0.2 ms aligned delay   (counterpart of the 21 % THD run)      (optional)
%    3. MMC_Per_arm_outer_v5_G2_case2_clip_delay1p4_aligned.slx  case 2 clip + 1.4 ms aligned  (eq. (6): tau*kappa = 0.40 < pi/4)   (optional)
%    4. MMC_Per_arm_outer_v5_G2_case2_clip_delay5p5_aligned.slx  case 2 clip + 5.5 ms aligned  (eq. (6): tau*kappa = 1.56 > pi/4)   (optional)
%  Models 2-4 are skipped if their file is not in the folder.
%  References (optional): followup_results.mat from run_followup_cases.m -> R(1) case 2 clip, R(2) twin, R(3) 0.2 ms fresh, R(4) 1 ms fresh.
%  Outputs: aligned_metrics.txt, aligned_results.mat (struct R, same 13 fields + name + grid),
%           fig1_delay_fresh_vs_aligned.png, fig2_eq6_test.png, grid_<case>.png, grid_all_aligned.png
clear; clc; close all;
diary('aligned_metrics.txt'); diary on;

cases = {'MMC_Per_arm_outer_v5_G2_case1b_delay1_aligned', 'Twin + 1 ms aligned delay', 'grid_case1b_delay1_aligned'};
opt = { 'MMC_Per_arm_outer_v5_G2_case1b_delay02_aligned',      'Twin + 0.2 ms aligned delay',              'grid_case1b_delay02_aligned'; ...
        'MMC_Per_arm_outer_v5_G2_case2_clip_delay1p4_aligned', 'Case 2 clip + 1.4 ms aligned (below (6))', 'grid_case2_clip_delay1p4_aligned'; ...
        'MMC_Per_arm_outer_v5_G2_case2_clip_delay5p5_aligned', 'Case 2 clip + 5.5 ms aligned (above (6))', 'grid_case2_clip_delay5p5_aligned'};
for j = 1:size(opt,1)
    if isfile([opt{j,1} '.slx']), cases(end+1,:) = opt(j,:); end %#ok<SAGROW>
end
nc = size(cases,1);
tags = {'Vc_up','10'; 'Vc_low','10'; 'P_UP','1'; 'Q_UP','1'; 'Pstar_ref','1'; ...
        'v_ac','10'; 'i_ac','10'; 'i_u','10'; 'i_l','10'; 'm_up','10'; 'm_low','10'; 'i_load','10'; 'i_grid','10'};

R = struct();
for k = 1:nc
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
        R(k).(tags{j,1}) = out.get(tags{j,1});
    end
    R(k).name = cases{k,2};  R(k).grid = cases{k,3};
    close_system(mdl, 0);
end
save('aligned_results.mat', 'R');

haveRef = isfile('followup_results.mat');
if haveRef
    S = load('followup_results.mat'); Rf = S.R;    % Rf(1) case 2 clip, Rf(2) twin, Rf(3) 0.2 ms fresh, Rf(4) 1 ms fresh
    fprintf('Reference followup_results.mat found (%d cases)\n', numel(Rf));
end

%% ------------------------------------------------------------------ definitions
spread = @(ts) max(ts.Data,[],2) - min(ts.Data,[],2);
imbal  = @(ts) max(movmean(ts.Data,200,1),[],2) - min(movmean(ts.Data,200,1),[],2);

%% ------------------------------------------------------------------ 1. stability and distortion, every case
fprintf('\n==== STABILITY / DISTORTION (compare with the fresh-own-sample runs) ====\n');
for k = 1:nc
    t = R(k).Vc_up.Time; m = t > 0.45; w = t > 0.3 & t < 1.98;
    fprintf('%s\n', R(k).name);
    fprintf('   all 16 Vc in [%.2f, %.2f] V (whole run) | i_u in [%.2f, %.2f] A, i_grid in [%.2f, %.2f] A (whole run) | m_up in [%.3f, %.3f] for t > 0.45\n', ...
            min([min(R(k).Vc_up.Data(:)), min(R(k).Vc_low.Data(:))]), max([max(R(k).Vc_up.Data(:)), max(R(k).Vc_low.Data(:))]), ...
            min(R(k).i_u.Data), max(R(k).i_u.Data), min(R(k).i_grid.Data), max(R(k).i_grid.Data), min(R(k).m_up.Data(m)), max(R(k).m_up.Data(m)));
    [f, A] = spec(R(k).i_ac, 1.5, 2.0);
    fprintf('   i_ac 1.5-2 s: 50 Hz %.3f A, 150 Hz %.3f A, 250 Hz %.3f A, THD(2-20) %.2f %%\n', harm(f,A,50), harm(f,A,150), harm(f,A,250), thd_pct(R(k).i_ac, 1.5, 2.0));
    iu = imbal(R(k).Vc_up); il = imbal(R(k).Vc_low);
    fprintf('   imbalance max 0.3-1.98 s: upper %.3f V, lower %.3f V | spread max 0.3-1.98 s: %.2f / %.2f V | ripple pk-pk 1.5-2 s: %.2f V\n', ...
            max(iu(w)), max(il(w)), max(spread(R(k).Vc_up) .* w), max(spread(R(k).Vc_low) .* w), ripple_pp(t, mean(R(k).Vc_up.Data,2), 1.5, 2));
    fprintf('   P mean (t > 0.45 s) %.1f W, Q mean %.1f var | i_u before 0.15 s in [%.2f, %.2f] A\n', ...
            mean(R(k).P_UP.Data(R(k).P_UP.Time > 0.45)), mean(R(k).Q_UP.Data(R(k).Q_UP.Time > 0.45)), min(R(k).i_u.Data(t < 0.15)), max(R(k).i_u.Data(t < 0.15)));
end
if haveRef
    fprintf('--- references (fresh own sample):\n');
    for k = [2 3 4]
        if k > numel(Rf), continue; end
        [f, A] = spec(Rf(k).i_ac, 1.5, 2.0);
        fprintf('   %-32s i_u in [%.1f, %.1f] A | i_ac 150 Hz %.3f A, THD %.2f %% | Vc max %.0f V\n', Rf(k).name, min(Rf(k).i_u.Data), max(Rf(k).i_u.Data), ...
                harm(f,A,150), thd_pct(Rf(k).i_ac, 1.5, 2.0), max(Rf(k).Vc_up.Data(:)));
    end
end

%% ------------------------------------------------------------------ 2. eq. (6) test: convergence / oscillation of the consensus from +/-10 V
kappa = 0.2 * 3.11 / 2.2e-3;                            % k_v * i_bar / C at 1.5 kW (1/s)
fprintf('\n==== EQ. (6) TEST: kappa = %.0f 1/s at 1.5 kW -> bound tau < pi/(4 kappa) = %.2f ms ====\n', kappa, 1e3 * pi / (4 * kappa));
for k = 1:nc
    if ~contains(cases{k,1}, 'case2_clip'), continue; end
    t = R(k).Vc_up.Time; s = spread(R(k).Vc_up);
    fprintf('%s\n', R(k).name);
    for thr = [5 2 1 0.5]
        i = find(s >= thr, 1, 'last');
        if isempty(i), fprintf('   spread_up < %.1f V from t = 0\n', thr);
        elseif i >= numel(t) - 1, fprintf('   spread_up never settles below %.1f V (last >= at %.3f s)\n', thr, t(i));
        else, fprintf('   spread_up < %.1f V from %.1f ms on\n', thr, t(i+1)*1e3); end
    end
    % amplitude of the inter-SM deviation in successive windows after the power ramp: growth = instability of the delayed consensus
    dev = R(k).Vc_up.Data - mean(R(k).Vc_up.Data, 2);
    fprintf('   rms inter-SM deviation (upper arm): 0.4-0.6 s %.3f | 0.8-1.0 s %.3f | 1.2-1.4 s %.3f | 1.8-2.0 s %.3f V\n', ...
            rmsall(dev(t>0.4&t<0.6,:)), rmsall(dev(t>0.8&t<1.0,:)), rmsall(dev(t>1.2&t<1.4,:)), rmsall(dev(t>1.8&t<2.0,:)));
    % dominant frequency of the HB_u3 deviation in 1-2 s (consensus oscillation would appear here; 50/100 Hz are the normal ripple)
    ts3 = timeseries(dev(:,3), t); [f, A] = spec(ts3, 1.0, 2.0); A(f < 2) = 0; A(abs(f-50) < 3 | abs(f-100) < 3 | abs(f-150) < 3 | abs(f-200) < 3) = 0;
    if contains(cases{k,1}, '1p4'), tau = 1.4e-3; else, tau = 5.5e-3; end
    [amax, i] = max(A); fprintf('   HB_u3 deviation 1-2 s: largest non-ripple component %.3f V at %.1f Hz (a delayed-consensus mode would sit between %.0f and %.0f Hz for tau = %.1f ms)\n', ...
            amax, f(i), 1/(4*tau), 2*kappa/(2*pi), tau*1e3);
    fprintf('   imbalance max t > 0.5 s: upper %.3f V, lower %.3f V | i_u in [%.2f, %.2f] A for t > 0.45 s\n', ...
            max(imbal(R(k).Vc_up) .* (t > 0.5)), max(imbal(R(k).Vc_low) .* (t > 0.5)), min(R(k).i_u.Data(t > 0.45)), max(R(k).i_u.Data(t > 0.45)));
end
if haveRef
    t = Rf(1).Vc_up.Time; s = spread(Rf(1).Vc_up); dev = Rf(1).Vc_up.Data - mean(Rf(1).Vc_up.Data, 2);
    fprintf('--- reference case 2 clip, no delay: spread_up < 1 V from %.1f ms | rms deviation 0.4-0.6 s %.3f, 1.8-2.0 s %.3f V\n', ...
            t(find(s >= 1, 1, 'last')+1)*1e3, rmsall(dev(t>0.4&t<0.6,:)), rmsall(dev(t>1.8&t<2.0,:)));
end
diary off;

%% ------------------------------------------------------------------ figures
cols = [0 0.45 0.74; 0.47 0.67 0.19; 0.93 0.69 0.13; 0.49 0.18 0.56; 0.85 0.33 0.10];
f1 = figure('Name', 'fig1_delay_fresh_vs_aligned', 'Position', [50 50 1100 700]);
subplot(2,2,1); hold on; grid on;
if haveRef && numel(Rf) >= 4, plot(Rf(4).i_l.Time*1e3, Rf(4).i_l.Data, 'Color', cols(5,:), 'LineWidth', 1.2, 'DisplayName', '1 ms, own sample fresh'); end
plot(R(1).i_l.Time*1e3, R(1).i_l.Data, 'Color', cols(1,:), 'LineWidth', 1.2, 'DisplayName', '1 ms, time-aligned');
if haveRef, plot(Rf(2).i_l.Time*1e3, Rf(2).i_l.Data, 'k--', 'LineWidth', 0.8, 'DisplayName', 'no delay'); end
xlim([0 40]); ylim([-10 80]); xlabel('t (ms)'); ylabel('i_l (A)'); legend('Location', 'northwest'); title('Lower-arm current, first 40 ms');
subplot(2,2,2); hold on; grid on;
plot(R(1).Vc_up.Time*1e3, mean(R(1).Vc_up.Data,2), 'Color', cols(1,:), 'LineWidth', 1.2, 'DisplayName', 'upper-arm mean, aligned');
plot(R(1).Vc_low.Time*1e3, mean(R(1).Vc_low.Data,2), 'Color', cols(2,:), 'LineWidth', 1.2, 'DisplayName', 'lower-arm mean, aligned');
if haveRef && numel(Rf) >= 4, plot(Rf(4).Vc_low.Time*1e3, mean(Rf(4).Vc_low.Data,2), 'Color', cols(5,:), 'LineWidth', 1.0, 'DisplayName', 'lower-arm mean, fresh'); end
xlim([0 60]); ylim([80 200]); xlabel('t (ms)'); ylabel('V_c (V)'); legend('Location', 'northwest'); title('Arm-average voltages, 1 ms delay');
subplot(2,2,3); hold on; grid on;
if haveRef, plot((Rf(2).i_ac.Time-1.9)*1e3, Rf(2).i_ac.Data, 'k', 'LineWidth', 1.0, 'DisplayName', 'no delay'); end
if haveRef && numel(Rf) >= 3, plot((Rf(3).i_ac.Time-1.9)*1e3, Rf(3).i_ac.Data, 'Color', cols(5,:), 'LineWidth', 1.0, 'DisplayName', '0.2 ms fresh'); end
plot((R(1).i_ac.Time-1.9)*1e3, R(1).i_ac.Data, 'Color', cols(1,:), 'LineWidth', 1.2, 'DisplayName', '1 ms aligned');
k2 = find(contains(cases(:,1), 'delay02_aligned'), 1);
if ~isempty(k2), plot((R(k2).i_ac.Time-1.9)*1e3, R(k2).i_ac.Data, 'Color', cols(2,:), 'LineWidth', 1.2, 'DisplayName', '0.2 ms aligned'); end
xlim([0 40]); xlabel('t (ms), two periods at 1.5 kW'); ylabel('i_ac (A)'); legend('Location', 'northeast'); title('Grid current waveform');
subplot(2,2,4); hold on; grid on;
names = {}; vals = [];
if haveRef, names{end+1} = 'no delay'; vals(end+1) = thd_pct(Rf(2).i_ac, 1.5, 2.0); end
if haveRef && numel(Rf) >= 3, names{end+1} = '0.2 ms fresh'; vals(end+1) = thd_pct(Rf(3).i_ac, 1.5, 2.0); end
if ~isempty(k2), names{end+1} = '0.2 ms aligned'; vals(end+1) = thd_pct(R(k2).i_ac, 1.5, 2.0); end
names{end+1} = '1 ms aligned'; vals(end+1) = thd_pct(R(1).i_ac, 1.5, 2.0);
bar(vals, 'FaceColor', [0.3 0.3 0.3]); set(gca, 'XTick', 1:numel(vals), 'XTickLabel', names); ylabel('i_ac THD (%)'); title('THD of the grid current, 1.5-2 s');
for i = 1:numel(vals), text(i, vals(i) + 0.5, sprintf('%.1f', vals(i)), 'HorizontalAlignment', 'center'); end
exportgraphics(f1, 'fig1_delay_fresh_vs_aligned.png', 'Resolution', 150);

kk = find(contains(cases(:,1), 'case2_clip'));
if ~isempty(kk)
    f2 = figure('Name', 'fig2_eq6_test', 'Position', [50 50 1100 700]);
    subplot(2,1,1); hold on; grid on;
    if haveRef, plot(Rf(1).Vc_up.Time, spread(Rf(1).Vc_up), 'k', 'LineWidth', 1.0, 'DisplayName', 'case 2 clip, no delay'); end
    for j = 1:numel(kk)
        plot(R(kk(j)).Vc_up.Time, spread(R(kk(j)).Vc_up), 'Color', cols(j+2,:), 'LineWidth', 1.2, 'DisplayName', R(kk(j)).name);
    end
    set(gca, 'YScale', 'log'); ylim([0.05 30]); xlabel('t (s)'); ylabel('spread of V_c, upper arm (V)'); legend('Location', 'northeast', 'Interpreter', 'none');
    title(sprintf('Eq. (6) test: time-aligned delay below / above the bound of %.2f ms at 1.5 kW', 1e3*pi/(4*kappa)));
    subplot(2,1,2); hold on; grid on;
    for j = 1:numel(kk)
        plot(R(kk(j)).Vc_up.Time, R(kk(j)).Vc_up.Data(:,3) - mean(R(kk(j)).Vc_up.Data,2), 'Color', cols(j+2,:), 'LineWidth', 1.0, 'DisplayName', [R(kk(j)).name ' - HB_u3 minus arm mean']);
    end
    xlim([0.3 2]); xlabel('t (s)'); ylabel('V_{c,u3} - mean (V)'); legend('Location', 'northeast', 'Interpreter', 'none');
    exportgraphics(f2, 'fig2_eq6_test.png', 'Resolution', 150);
end

for k = 1:nc
    fg = overview_grid(R(k), R(k).name);
    exportgraphics(fg, [R(k).grid '.png'], 'Resolution', 150);
end
fa = figure('Name', 'grid_all_aligned', 'Position', [50 50 650*nc 1400]);
rows = {'v_ac (V), 20*i_ac (A)', 'i_u, i_l (A)', 'Vc upper (8 SM)', 'Vc lower (8 SM)', 'P (W), Q (var)', 'm_up, m_low'};
for k = 1:nc
    for r = 1:6
        subplot(6, nc, (r-1)*nc + k); overview_panel(R(k), r); grid on;
        if r == 1, title(R(k).name, 'Interpreter', 'none', 'FontSize', 9); end
        if k == 1, ylabel(rows{r}, 'Interpreter', 'none'); end
        if r == 6, xlabel('t (s)'); end
    end
end
exportgraphics(fa, 'grid_all_aligned.png', 'Resolution', 120);
fprintf('\nSaved: aligned_metrics.txt, aligned_results.mat, fig1_delay_fresh_vs_aligned.png, fig2_eq6_test.png, grid_*.png\n');

%% ================================================================== local functions
function r = ripple_pp(t, v, a, b)
    r = []; s = a;
    while s + 0.02 <= b
        m = t >= s & t < s + 0.02; r(end+1) = max(v(m)) - min(v(m)); s = s + 0.02; %#ok<AGROW>
    end
    r = mean(r);
end

function fg = overview_grid(Rk, ttl)
    fg = figure('Name', ttl, 'Position', [50 50 1900 950]);
    order = [1 4 2 5 3 6];
    for p = 1:6
        subplot(3, 2, p); overview_panel(Rk, order(p)); grid on;
        if p >= 5, xlabel('t (s)'); end
    end
    sgtitle(ttl, 'Interpreter', 'none');
end

function overview_panel(Rk, which)
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

function [f, A] = spec(ts, a, b)
% amplitude spectrum (Hann window, no toolbox) of a column signal between a and b
    m = ts.Time >= a & ts.Time < b; x = ts.Data(m); n = numel(x); w = 0.5 * (1 - cos(2*pi*(0:n-1)'/(n-1)));
    A = abs(fft(x(:).*w)) * 2 / sum(w); A = A(1:floor(n/2)); f = (0:floor(n/2)-1)' / (n * (ts.Time(2) - ts.Time(1)));
end

function h = harm(f, A, fr)
    [~, i] = min(abs(f - fr)); h = A(i);
end

function thd = thd_pct(ts, a, b)
    [f, A] = spec(ts, a, b); h1 = harm(f, A, 50); s = 0;
    for n = 2:20, s = s + harm(f, A, 50*n)^2; end
    thd = 100 * sqrt(s) / h1;
end

function r = rmsall(x)
    r = sqrt(mean(x(:).^2));
end
