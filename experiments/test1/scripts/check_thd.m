% CHECK_THD
% Two checks on the grid-current THD, on MMC_Per_arm_outer_v5_G2_tests.slx (R2024a):
%   1. Method: THD of the same run computed over several windows (is 3.2 % vs 3.6 % a window effect?)
%   2. Cause of 7.3 % with alternating +/-20 % capacitances:
%        - which harmonics rise (table and spectrum),
%        - whether the rise follows k_v (runs at k_v = 0, 0.05, 0.1, 0.2),
%        - whether it is steady or an oscillation (THD per window of 0.2 s against time).
% Works on a copy of the model (<name>_thd.slx). 5 runs of 2 s at P* = 1.5 kW, balanced start.
% Files written: thd_check_report.txt, thd_check_results.mat, thd_check_spectrum.png, thd_check_vs_time.png

src = 'MMC_Per_arm_outer_v5_G2_tests';  mdl = [src '_thd'];
Tstop = 2;  Cnom = 2.2e-3;  N = 8;  f0 = 50;  H = 2:20;
alt = repmat([1; -1], N/2, 1);
runs = struct('name', {'identical, k_v = 0.2', 'alternating, k_v = 0', 'alternating, k_v = 0.05', ...
                       'alternating, k_v = 0.1', 'alternating, k_v = 0.2'}, ...
              'kv',   {0.2, 0, 0.05, 0.1, 0.2}, ...
              'Cu',   {Cnom*ones(N,1), Cnom*(1+0.2*alt), Cnom*(1+0.2*alt), Cnom*(1+0.2*alt), Cnom*(1+0.2*alt)}, ...
              'Cl',   {Cnom*ones(N,1), Cnom*(1-0.2*alt), Cnom*(1-0.2*alt), Cnom*(1-0.2*alt), Cnom*(1-0.2*alt)});
windows = [1.8 2.0; 1.0 2.0; 0.5 2.0; 0.3 1.98];      % s; the last one is the window quoted in the earlier notes

% ---------------- working copy ----------------
if bdIsLoaded(mdl), close_system(mdl, 0); end
load_system(src);  save_system(src, mdl);
for i = 1:N
    set_param(sprintf('%s/HB_u%d', mdl, i), 'C', sprintf('C_u(%d)', i));
    set_param(sprintf('%s/HB_l%d', mdl, i), 'C', sprintf('C_l(%d)', i));
end
set_param([mdl '/P SELECT  up = staircase  down = fixed'], 'sw', '0');
charts = find(sfroot, '-isa', 'Stateflow.EMChart');
charts = charts(arrayfun(@(c) startsWith(c.Path, [mdl '/']) && contains(c.Path, 'Local Ctrl'), charts));
assert(numel(charts) == 2*N);

% ---------------- runs ----------------
for r = 1:numel(runs)
    assignin('base', 'C_u', runs(r).Cu);  assignin('base', 'C_l', runs(r).Cl);
    for k = 1:numel(charts)
        charts(k).Script = regexprep(charts(k).Script, 'k_v\s*=\s*[\d.eE+-]+;', sprintf('k_v    = %g;', runs(r).kv), 'once');
    end
    fprintf('Running: %s ...\n', runs(r).name);
    out = sim(mdl, 'StopTime', num2str(Tstop));
    ts  = out.logsout.get('i_ac').Values;
    t = ts.Time(:);  x = squeeze(ts.Data);  x = x(:);
    runs(r).t = t;  runs(r).iac = x;
    % (1) THD over each window
    runs(r).thd_win = arrayfun(@(k) thd_of(t, x, windows(k,1), windows(k,2), f0, H), 1:size(windows,1));
    % (2a) harmonic amplitudes over the last 0.2 s
    [~, a] = thd_of(t, x, Tstop-0.2, Tstop, f0, H);
    runs(r).I1 = a(1);  runs(r).Ih = a(2:end);
    % interharmonic content: FFT of 0.5 s to 2 s (resolution 2/3 Hz), largest line outside the harmonics
    w = t >= 0.5 & t < 2.0;  xs = x(w);  n = numel(xs);  dt = median(diff(t));
    X = abs(fft(xs - mean(xs)))*2/n;  f = (0:n-1).'/(n*dt);
    keep = f > 5 & f < 1000 & abs(f - f0*round(f/f0)) > 3;
    [runs(r).inter_A, j] = max(X .* keep);  runs(r).inter_f = f(j);
    runs(r).f = f(f < 1100);  runs(r).X = X(f < 1100);
    % (2c) THD per window of 0.2 s
    edges = 0.4:0.2:Tstop;
    runs(r).t_slide = edges(1:end-1) + 0.1;
    runs(r).thd_slide = arrayfun(@(k) thd_of(t, x, edges(k), edges(k+1), f0, H), 1:numel(edges)-1);
end
close_system(mdl, 0);
S = rmfield(runs, {'t', 'iac'});  save('thd_check_results.mat', 'S', 'windows');

% ---------------- report ----------------
fid = fopen('thd_check_report.txt', 'w');
fprintf(fid, 'THD check, P* = 1.5 kW, harmonics %d to %d of %d Hz\n\n', H(1), H(end), f0);
fprintf(fid, '1. THD (%%) of each run over several windows\n%-26s', 'run');
fprintf(fid, ' | %4.1f-%4.2f s', windows.');  fprintf(fid, '\n');
for r = 1:numel(runs)
    fprintf(fid, '%-26s', runs(r).name);  fprintf(fid, ' | %11.2f', runs(r).thd_win);  fprintf(fid, '\n');
end
fprintf(fid, '\n2a. Harmonic amplitudes (A), last 0.2 s\n%-26s | %6s |', 'run', 'I1');
fprintf(fid, ' h%-4d', H);  fprintf(fid, '\n');
for r = 1:numel(runs)
    fprintf(fid, '%-26s | %6.3f |', runs(r).name, runs(r).I1);  fprintf(fid, ' %5.3f', runs(r).Ih);  fprintf(fid, '\n');
end
fprintf(fid, '\n2b. THD against k_v (alternating +/-20 %%), last 0.2 s\n');
for r = 2:numel(runs)
    fprintf(fid, '   k_v = %-5g  THD = %5.2f %%   largest harmonic: h%d = %.3f A\n', runs(r).kv, ...
            runs(r).thd_win(1), H(runs(r).Ih == max(runs(r).Ih)), max(runs(r).Ih));
end
fprintf(fid, '\n2c. THD (%%) per window of 0.2 s (centre of the window in s)\n%-26s', 'run');
fprintf(fid, ' | %5.1f', runs(1).t_slide);  fprintf(fid, '\n');
for r = 1:numel(runs)
    fprintf(fid, '%-26s', runs(r).name);  fprintf(fid, ' | %5.2f', runs(r).thd_slide);  fprintf(fid, '\n');
end
fprintf(fid, '\n2d. Largest line that is not a harmonic of %d Hz (FFT of 0.5 s to 2 s)\n', f0);
for r = 1:numel(runs)
    fprintf(fid, '%-26s | %.3f A at %.1f Hz\n', runs(r).name, runs(r).inter_A, runs(r).inter_f);
end
fclose(fid);  type('thd_check_report.txt');

% ---------------- figures ----------------
f1 = figure('Color', 'w', 'Position', [100 100 1100 420]);
bar(H, vertcat(runs.Ih).');  grid on;  xlabel('Harmonic order');  ylabel('Amplitude (A)');
legend({runs.name}, 'Location', 'northeast');  title('Harmonics of the grid current, last 0.2 s');
exportgraphics(f1, 'thd_check_spectrum.png', 'Resolution', 300);
f2 = figure('Color', 'w', 'Position', [100 100 800 380]);  hold on;  grid on;
for r = 1:numel(runs), plot(runs(r).t_slide, runs(r).thd_slide, '-o', 'DisplayName', runs(r).name); end
xlabel('Time (s)');  ylabel('THD over 0.2 s (%)');  legend('Location', 'best');
exportgraphics(f2, 'thd_check_vs_time.png', 'Resolution', 300);

% =====================================================================================
function [d, a] = thd_of(t, x, t1, t2, f0, H)
% THD of harmonics H over [t1, t2), trimmed to a whole number of periods of f0. a = [I1, I_H] (A).
    T = floor((t2 - t1)*f0 + 1e-9)/f0;
    w = t >= t2 - T & t < t2;
    tt = t(w);  xx = x(w);
    amp = @(h) abs(2*mean(xx .* exp(-1j*2*pi*f0*h*tt)));
    a = [amp(1), arrayfun(amp, H)];
    d = 100*sqrt(sum(a(2:end).^2))/a(1);
end
