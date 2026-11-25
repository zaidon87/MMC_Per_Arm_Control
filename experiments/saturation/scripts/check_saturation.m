% CHECK_SATURATION
% Test of the hypothesis: with alternating +/-20 % capacitances and k_v = 0.2, the THD of 7.3 % comes
% from duty cycles clipped at 0 or 1 (the correction k_v*e_i is larger than the margin of m_arm).
% Model: MMC_Per_arm_outer_v5_G2_tests.slx (R2024a); works on a copy (<name>_sat.slx).
%
% Runs (2 s, P* = 1.5 kW, balanced start, k_v = 0.2):
%   1. alternating +/-20 %, correction not bounded        (the 7.3 % case)
%   2. alternating +/-20 %, |k_v e_i| <= 0.10             (the bound used in the paper)
%   3. alternating +/-20 %, |k_v e_i| <= 0.05
%   4. identical capacitors, |k_v e_i| <= 0.05            (does the bound cost balance in the nominal case?)
% The bound is added inside the 16 "Local Ctrl" blocks: dm = min(max(dm, -B), B).
%
% For each run: THD (harmonics 2-20, last 0.2 s), harmonics 3 and 5, imbalance, and the clipping
% rebuilt offline from the logged signals (Vc_up, m_up, i_u): share of samples in which at least one
% duty cycle of the upper arm is clipped, and the mean |sum(d_i) - N*m_arm|.
% Files written: sat_check_report.txt, sat_check_results.mat

src = 'MMC_Per_arm_outer_v5_G2_tests';  mdl = [src '_sat'];
Tstop = 2;  Cnom = 2.2e-3;  N = 8;  f0 = 50;  H = 2:20;  kv = 0.2;  dead = 0.1;  Iscale = 1;  t0 = 0.5;
alt = repmat([1; -1], N/2, 1);
Ca_u = Cnom*(1 + 0.2*alt);  Ca_l = Cnom*(1 - 0.2*alt);  Cid = Cnom*ones(N,1);
runs = struct('name', {'alternating, no bound', 'alternating, bound 0.10', 'alternating, bound 0.05', 'identical, bound 0.05'}, ...
              'B',    {Inf, 0.10, 0.05, 0.05}, ...
              'Cu',   {Ca_u, Ca_u, Ca_u, Cid}, 'Cl', {Ca_l, Ca_l, Ca_l, Cid});

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
assert(numel(charts) == 2*N, 'Expected %d Local Ctrl blocks.', 2*N);
orig = arrayfun(@(c) string(c.Script), charts);          % scripts as delivered, restored before every run
dmPat = 'dm\s*=\s*k_v\s*\*\s*err\s*\*\s*dirn;';
assert(all(~cellfun(@isempty, regexp(cellstr(orig), dmPat, 'once'))), 'Line "dm = k_v * err * dirn;" not found.');

% ---------------- runs ----------------
for r = 1:numel(runs)
    B = runs(r).B;
    assignin('base', 'C_u', runs(r).Cu);  assignin('base', 'C_l', runs(r).Cl);
    for k = 1:numel(charts)
        s = regexprep(char(orig(k)), 'k_v\s*=\s*[\d.eE+-]+;', sprintf('k_v    = %g;', kv), 'once');
        if isfinite(B)
            s = regexprep(s, dmPat, sprintf('dm   = k_v * err * dirn; dm = min(max(dm, -%g), %g);', B, B), 'once');
        end
        charts(k).Script = s;
    end
    fprintf('Running: %s ...\n', runs(r).name);
    out = sim(mdl, 'StopTime', num2str(Tstop));  L = out.logsout;
    [t, Vu] = sig(L, 'Vc_up');  [~, Vl] = sig(L, 'Vc_low');
    [ti, iac] = sig(L, 'i_ac');  [tm, m] = sig(L, 'm_up');  [tu, iu] = sig(L, 'i_u');

    % THD and harmonics, last 0.2 s
    [runs(r).thd, a] = thd_of(ti, iac, Tstop-0.2, Tstop, f0, H);
    runs(r).I1 = a(1);  runs(r).h3 = a(1 + find(H == 3));  runs(r).h5 = a(1 + find(H == 5));
    % imbalance of the 20 ms means and instantaneous spread, worst arm, t0 to Tstop
    [iu_, su_] = imb_of(t, Vu, t0);  [il_, sl_] = imb_of(t, Vl, t0);
    runs(r).imb = max(iu_, il_);  runs(r).inst = max(su_, sl_);
    % clipping of the upper arm, rebuilt from the logged signals (sample-and-hold onto the time base of Vc)
    mm = interp1(tm, m, t, 'previous', 'extrap');  ii = interp1(tu, iu, t, 'previous', 'extrap');
    e  = 0.5*(circshift(Vu, 1, 2) + circshift(Vu, -1, 2)) - Vu;       % ring neighbours
    e(abs(e) < dead) = 0;
    dm = kv * e .* tanh(ii/Iscale);
    if isfinite(B), dm = min(max(dm, -B), B); end
    d  = mm + dm;  dc = min(max(d, 0), 1);
    w  = t >= t0;
    runs(r).dm_max    = max(abs(dm(w,:)), [], 'all');
    runs(r).clip_pct  = 100*mean(any(d(w,:) < 0 | d(w,:) > 1, 2));
    runs(r).sum_err   = mean(abs(sum(dc(w,:), 2) - N*mm(w)));           % in units of duty cycle (1 = one submodule)
    runs(r).m_min = min(mm(w));  runs(r).m_max = max(mm(w));
end
for k = 1:numel(charts), charts(k).Script = char(orig(k)); end
close_system(mdl, 0);
save('sat_check_results.mat', 'runs');

% ---------------- report ----------------
fid = fopen('sat_check_report.txt', 'w');
fprintf(fid, 'Saturation check, P* = 1.5 kW, k_v = 0.2, balanced start\n\n');
fprintf(fid, '%-26s | %6s | %7s %7s | %8s %8s | %8s | %8s | %10s | %11s\n', 'run', 'THD %', 'h3 (A)', 'h5 (A)', ...
        'imb (V)', 'inst (V)', 'max |dm|', 'clip %', 'sum error', 'm_arm range');
for r = 1:numel(runs)
    fprintf(fid, '%-26s | %6.2f | %7.3f %7.3f | %8.3f %8.2f | %8.3f | %8.2f | %10.4f | %4.2f - %4.2f\n', runs(r).name, ...
        runs(r).thd, runs(r).h3, runs(r).h5, runs(r).imb, runs(r).inst, runs(r).dm_max, runs(r).clip_pct, ...
        runs(r).sum_err, runs(r).m_min, runs(r).m_max);
end
fprintf(fid, ['\nimb       = largest difference between the 20 ms means of an arm, worst arm, %.1f s to %g s\n' ...
              'inst      = largest instantaneous difference in the same window\n' ...
              'max |dm|  = largest correction k_v*e_i*tanh(i_arm/I_s) after the bound, upper arm\n' ...
              'clip %%    = share of samples with at least one duty cycle of the upper arm clipped at 0 or 1\n' ...
              'sum error = mean |sum(d_i) - N*m_arm| of the upper arm (0 when equation (4) holds)\n' ...
              'The last three columns are rebuilt offline from Vc_up, m_up and i_u.\n'], t0, Tstop);
fclose(fid);  type('sat_check_report.txt');

% =====================================================================================
function [t, x] = sig(L, name)
    ts = L.get(name).Values;  t = ts.Time(:);  x = squeeze(ts.Data);
    if isvector(x), x = x(:); elseif size(x, 1) ~= numel(t), x = x.'; end
end

function [imb, inst] = imb_of(t, V, t0)
    n = round(0.02/median(diff(t)));
    Vm = filter(ones(n,1)/n, 1, V);
    it = max(Vm, [], 2) - min(Vm, [], 2);  it(1:n) = NaN;
    w = t >= t0;
    imb = max(it(w));  inst = max(max(V(w,:), [], 2) - min(V(w,:), [], 2));
end

function [d, a] = thd_of(t, x, t1, t2, f0, H)
    T = floor((t2 - t1)*f0 + 1e-9)/f0;
    w = t >= t2 - T & t < t2;  tt = t(w);  xx = x(w);
    amp = @(h) abs(2*mean(xx .* exp(-1j*2*pi*f0*h*tt)));
    a = [amp(1), arrayfun(amp, H)];
    d = 100*sqrt(sum(a(2:end).^2))/a(1);
end
