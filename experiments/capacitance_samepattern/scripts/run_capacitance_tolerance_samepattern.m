% RUN_CAPACITANCE_TOLERANCE_SAMEPATTERN
% Corrected source protocol corresponding to archive 12(3).zip.
% Random 10% and 20% use identical random vectors, with doubled deviations.
% Compare OFF/ON for fixed C and save all results with _samepattern suffix.
% Capacitance-tolerance test for MMC_Per_arm_outer_v5_G2_tests.slx (R2024a).
% For each tolerance case, the model is run twice with the same capacitances:
% k_v = 0 (no neighbour term) and k_v = 0.2 1/V. Fixed P* = 1.5 kW, 2 s, balanced start at 100 V.
%
% The script works on a copy of the model (<name>_Ctol.slx); the original file is not changed.
% How the model is driven:
%   - HB_u1..8 / HB_l1..8 : parameter C is set to C_u(i) / C_l(i). The InitFcn of the model
%     rewrites the scalar C at every start, so the vectors C_u, C_l are used instead.
%   - k_v is a literal inside the 16 "Local Ctrl" MATLAB Function blocks; it is rewritten there.
%   - "P SELECT" manual switch is set to the lower input (fixed P* = Pstar = 1500 W).
%   - The arm leaders keep C = 2.2 mF in their energy estimate (they do not know the real values).
% Signals read from logsout: Vc_up, Vc_low, i_ac, P_UPPER.

src = 'MMC_Per_arm_outer_v5_G2_tests';
mdl = [src '_Ctol'];
Tstop = 2;            % s
Cnom  = 2.2e-3;       % F
N     = 8;
KV    = [0 0.2];      % 1/V
t0    = 0.5;          % s, start of the measurement window (power reaches 1.5 kW at 0.30 s)

% ---------------- tolerance cases ----------------
rng(1);                                   % repeatable matched random vectors
U_u = 2*rand(N,1) - 1;  U_l = 2*rand(N,1) - 1;
alt = repmat([1; -1], N/2, 1);            % +tol, -tol, +tol, ... : every submodule differs from both neighbours
cases = struct('name', {}, 'Cu', {}, 'Cl', {});
cases(end+1) = struct('name', 'identical',          'Cu', Cnom*ones(N,1),                    'Cl', Cnom*ones(N,1));
cases(end+1) = struct('name', 'random +/-10 %',     'Cu', Cnom*(1 + 0.10*U_u),              'Cl', Cnom*(1 + 0.10*U_l));
cases(end+1) = struct('name', 'random +/-20 %',     'Cu', Cnom*(1 + 0.20*U_u),              'Cl', Cnom*(1 + 0.20*U_l));
cases(end+1) = struct('name', 'alternating +/-20 %','Cu', Cnom*(1 + 0.20*alt),               'Cl', Cnom*(1 - 0.20*alt));

% Mandatory consistency: the +/-20% deviations are precisely twice +/-10%.
d10 = [cases(2).Cu; cases(2).Cl] / Cnom - 1;
d20 = [cases(3).Cu; cases(3).Cl] / Cnom - 1;
assert(max(abs(d20 - 2*d10)) < 1e-12, 'Random 20% was not scaled from random 10%.');


% ---------------- working copy of the model ----------------
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(src);
save_system(src, mdl);                    % writes <mdl>.slx next to the original and switches to it
for i = 1:N
    set_param(sprintf('%s/HB_u%d', mdl, i), 'C', sprintf('C_u(%d)', i));
    set_param(sprintf('%s/HB_l%d', mdl, i), 'C', sprintf('C_l(%d)', i));
end
set_param([mdl '/P SELECT  up = staircase  down = fixed'], 'sw', '0');   % fixed P* = Pstar

charts = find(sfroot, '-isa', 'Stateflow.EMChart');
isLocal = arrayfun(@(c) startsWith(c.Path, [mdl '/']) && contains(c.Path, 'Local Ctrl'), charts);
charts = charts(isLocal);
assert(numel(charts) == 2*N, 'Expected %d Local Ctrl blocks, found %d.', 2*N, numel(charts));

% ---------------- runs ----------------
R = struct('case', {}, 'kv', {}, 'Cu', {}, 'Cl', {}, 'imb_u', {}, 'imb_l', {}, 'inst_u', {}, 'inst_l', {}, ...
           'ripple_min', {}, 'ripple_max', {}, 'Pmean', {}, 'thd', {}, 't', {}, 'imb_u_t', {}, 'imb_l_t', {}, ...
           'Vm_u', {}, 'Vm_l', {});
for c = 1:numel(cases)
    assignin('base', 'C_u', cases(c).Cu);
    assignin('base', 'C_l', cases(c).Cl);
    for kv = KV
        for k = 1:numel(charts)
            s = charts(k).Script;
            s2 = regexprep(s, 'k_v\s*=\s*[\d.eE+-]+;', sprintf('k_v    = %g;', kv), 'once');
            assert(~strcmp(s, s2) || kv == 0.2, 'k_v line not found in %s', charts(k).Path);
            charts(k).Script = s2;
        end
        fprintf('Running: %-22s k_v = %.1f ...\n', cases(c).name, kv);
        out = sim(mdl, 'StopTime', num2str(Tstop));
        L   = out.logsout;
        Vu  = L.get('Vc_up').Values;   Vl = L.get('Vc_low').Values;
        iac = L.get('i_ac').Values;    P  = L.get('P_UPPER').Values;

        r.case = cases(c).name;  r.kv = kv;  r.Cu = cases(c).Cu;  r.Cl = cases(c).Cl;
        [r.imb_u, r.inst_u, r.t, r.imb_u_t, rip_u, r.Vm_u] = arm_metrics(Vu, t0);
        [r.imb_l, r.inst_l, ~,   r.imb_l_t, rip_l, r.Vm_l] = arm_metrics(Vl, t0);
        r.ripple_min = min([rip_u rip_l]);  r.ripple_max = max([rip_u rip_l]);
        r.Pmean = mean(P.Data(P.Time >= Tstop - 0.2));
        r.thd   = thd_2_20(iac, Tstop - 0.2, Tstop);
        R(end+1) = r; %#ok<SAGROW>
    end
end
close_system(mdl, 0);                     % discard the edits of the working copy
save('ctol_results_samepattern.mat', 'R', 'cases', 'U_u', 'U_l');

% ---------------- table ----------------
fprintf('\n%-22s %5s | %9s %9s | %9s %9s | %13s | %7s | %6s\n', 'case', 'k_v', ...
        'imb up', 'imb low', 'inst up', 'inst low', 'ripple min-max', 'P (W)', 'THD %');
for k = 1:numel(R)
    fprintf('%-22s %5.1f | %7.3f V %7.3f V | %7.2f V %7.2f V | %5.2f-%5.2f V | %7.1f | %6.2f\n', ...
        R(k).case, R(k).kv, R(k).imb_u, R(k).imb_l, R(k).inst_u, R(k).inst_l, ...
        R(k).ripple_min, R(k).ripple_max, R(k).Pmean, R(k).thd);
end
fprintf(['\nimb  = largest difference between the 20 ms means of the capacitor voltages of an arm, %.1f s to %g s\n' ...
         'inst = largest instantaneous difference in the same window\n'], t0, Tstop);

% ---------------- figures (each one is also saved as a 300 dpi PNG) ----------------
names = {cases.name};  nc = numel(cases);
get1  = @(f, kv) arrayfun(@(c) R(strcmp({R.case}, names{c}) & [R.kv] == kv).(f), 1:nc);
imb0  = max(get1('imb_u', 0),   get1('imb_l', 0));      % worst arm, without the neighbour term
imb1  = max(get1('imb_u', 0.2), get1('imb_l', 0.2));    % worst arm, with it
ins0  = max(get1('inst_u', 0),   get1('inst_l', 0));
ins1  = max(get1('inst_u', 0.2), get1('inst_l', 0.2));

% Fig. A: comparison bars
fA = figure('Color', 'w', 'Position', [100 100 1100 420]);
tiledlayout(1, 3, 'TileSpacing', 'compact');
nexttile; b = bar([imb0; imb1].'); grid on; set(gca, 'XTickLabel', names, 'YScale', 'log');
b(1).FaceColor = [.6 .6 .6]; b(2).FaceColor = [0 0 0];
ylabel('Imbalance of the 20 ms means (V)'); legend('k_v = 0', 'k_v = 0.2 V^{-1}', 'Location', 'northwest');
title('Imbalance (worst arm)'); label_bars(b);
nexttile; b = bar([ins0; ins1].'); grid on; set(gca, 'XTickLabel', names);
b(1).FaceColor = [.6 .6 .6]; b(2).FaceColor = [0 0 0];
ylabel('Largest instantaneous difference (V)'); title('Instantaneous spread (worst arm)'); label_bars(b);
nexttile; b = bar([get1('thd', 0); get1('thd', 0.2)].'); grid on; set(gca, 'XTickLabel', names);
b(1).FaceColor = [.6 .6 .6]; b(2).FaceColor = [0 0 0];
ylabel('THD of the grid current (%)'); title('Grid current THD'); label_bars(b);
exportgraphics(fA, 'ctol_A_comparison_samepattern.png', 'Resolution', 300);

% Fig. B: imbalance against time, one panel per case
fB = figure('Color', 'w', 'Position', [100 100 1100 380]);
tiledlayout(1, nc, 'TileSpacing', 'compact');
for c = 1:nc
    nexttile; hold on; grid on;
    for k = find(strcmp({R.case}, names{c}))
        col = [0 0 0]; if R(k).kv == 0, col = [.6 .6 .6]; end
        plot(R(k).t, R(k).imb_u_t, '-',  'Color', col, 'LineWidth', 1, 'DisplayName', sprintf('k_v = %.1f, upper', R(k).kv));
        plot(R(k).t, R(k).imb_l_t, '--', 'Color', col, 'LineWidth', 1, 'DisplayName', sprintf('k_v = %.1f, lower', R(k).kv));
    end
    title(names{c}); xlabel('Time (s)'); ylabel('Imbalance (V)'); xlim([0 Tstop]);
    if c == 1, legend('Location', 'northwest'); end
end
exportgraphics(fB, 'ctol_B_imbalance_vs_time_samepattern.png', 'Resolution', 300);

% Fig. C: 20 ms means of the eight capacitor voltages of the upper arm (top: k_v = 0, bottom: k_v = 0.2)
fC = figure('Color', 'w', 'Position', [100 100 1100 600]);
tl = tiledlayout(2, nc, 'TileSpacing', 'compact');  ax = gobjects(2, nc);
for row = 1:2
    for c = 1:nc
        k = find(strcmp({R.case}, names{c}) & [R.kv] == KV(row));
        ax(row, c) = nexttile(tl, (row-1)*nc + c);
        plot(R(k).t, R(k).Vm_u, 'LineWidth', 0.8); grid on; xlim([t0 Tstop]);
        title(sprintf('%s, k_v = %.1f', names{c}, KV(row)));
        if row == 2, xlabel('Time (s)'); end
        if c == 1, ylabel('Mean v_c, upper arm (V)'); end
    end
end
linkaxes(ax(:), 'y');
exportgraphics(fC, 'ctol_C_mean_voltages_upper_samepattern.png', 'Resolution', 300);

% Fig. D: capacitances used and mean voltage of each submodule at the end of the run (k_v = 0.2)
fD = figure('Color', 'w', 'Position', [100 100 1100 380]);
tiledlayout(1, nc, 'TileSpacing', 'compact');
for c = 1:nc
    k = find(strcmp({R.case}, names{c}) & [R.kv] == 0.2);
    nexttile; yyaxis left;  bar(1:N, 1e3*R(k).Cu, 'FaceColor', [.75 .75 .75]); ylabel('C (mF)'); ylim(1e3*Cnom*[0.7 1.3]);
    yyaxis right; plot(1:N, R(k).Vm_u(end,:), 'ko-', 'MarkerFaceColor', 'k'); ylabel('Mean v_c at 2 s (V)');
    xlabel('Submodule, upper arm'); title(names{c}); grid on;
end
exportgraphics(fD, 'ctol_D_capacitance_vs_voltage_samepattern.png', 'Resolution', 300);

% =====================================================================================
function [imb, inst, t, imb_t, ripple, Vm] = arm_metrics(ts, t0)
% ts: timeseries with the N capacitor voltages of one arm. Window: t >= t0.
    V = squeeze(ts.Data);  if size(V, 1) ~= numel(ts.Time), V = V.'; end
    t = ts.Time;  dt = median(diff(t));
    n = round(0.02/dt);                               % 20 ms = one grid period
    Vm = filter(ones(n,1)/n, 1, V);                   % trailing mean over 20 ms
    imb_t = max(Vm, [], 2) - min(Vm, [], 2);
    imb_t(1:n) = NaN;  Vm(1:n,:) = NaN;               % filter not yet filled
    w = t >= t0;
    imb  = max(imb_t(w));
    inst = max(max(V(w,:), [], 2) - min(V(w,:), [], 2));
    last = t >= t(end) - 0.02;                        % last grid period
    ripple = max(V(last,:), [], 1) - min(V(last,:), [], 1);   % peak-to-peak per submodule
    q = max(1, round(1e-3/dt));                       % keep one point per ms for the plots and the .mat file
    t = t(1:q:end);  imb_t = imb_t(1:q:end);  Vm = Vm(1:q:end,:);
end

function label_bars(b)
% Write the value above each bar.
    for k = 1:numel(b)
        text(b(k).XEndPoints, b(k).YEndPoints, compose('%.2f', b(k).YData), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);
    end
end

function d = thd_2_20(ts, t1, t2)
% THD of harmonics 2 to 20 of a 50 Hz signal over [t1, t2) (a whole number of periods).
    w = ts.Time >= t1 & ts.Time < t2;
    x = squeeze(ts.Data(w));  t = ts.Time(w);  x = x(:);  t = t(:);
    a = zeros(20, 1);
    for h = 1:20
        a(h) = abs(2*mean(x .* exp(-1j*2*pi*50*h*t)));
    end
    d = 100*sqrt(sum(a(2:20).^2))/a(1);
end
