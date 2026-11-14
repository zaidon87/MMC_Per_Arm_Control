% EXPORT_CTOL_RESULTS
% Writes the numerical results of run_capacitance_tolerance.m to files.
% Run it in the folder that contains ctol_results.mat (run_capacitance_tolerance first).
%
% Files written:
%   ctol_summary.csv        one row per run: all metrics
%   ctol_capacitances.csv   capacitance of each submodule in each case (mF)
%   ctol_final_voltages.csv 20 ms mean voltage of each capacitor at the end of each run (V)
%   ctol_timeseries.csv     imbalance against time for every run (one point per ms)
%   ctol_report.txt         the same summary as a readable table, with the comparison per case
%   ctol_results.xlsx       all of the above, one sheet each

assert(isfile('ctol_results.mat'), 'ctol_results.mat not found: run run_capacitance_tolerance first.');
S = load('ctol_results.mat');  R = S.R;  cases = S.cases;
N = numel(R(1).Cu);  names = {cases.name};

% ---------------- 1. summary: one row per run ----------------
T = table();
T.case            = string({R.case}).';
T.k_v             = [R.kv].';
T.imb_upper_V     = [R.imb_u].';
T.imb_lower_V     = [R.imb_l].';
T.imb_worst_V     = max(T.imb_upper_V, T.imb_lower_V);
T.inst_upper_V    = [R.inst_u].';
T.inst_lower_V    = [R.inst_l].';
T.ripple_min_V    = [R.ripple_min].';
T.ripple_max_V    = [R.ripple_max].';
T.P_mean_W        = [R.Pmean].';
T.THD_iac_percent = [R.thd].';
T.imb_end_upper_V = arrayfun(@(r) r.imb_u_t(end), R).';
T.imb_end_lower_V = arrayfun(@(r) r.imb_l_t(end), R).';

% ---------------- 2. comparison per case: without / with the neighbour term ----------------
Cmp = table();
for c = 1:numel(names)
    a = T(T.case == names{c} & T.k_v == 0, :);
    b = T(T.case == names{c} & T.k_v ~= 0, :);
    row = table(string(names{c}), a.imb_worst_V, b.imb_worst_V, a.imb_worst_V/b.imb_worst_V, ...
                max(a.inst_upper_V, a.inst_lower_V), max(b.inst_upper_V, b.inst_lower_V), ...
                a.THD_iac_percent, b.THD_iac_percent, ...
                'VariableNames', {'case', 'imb_kv0_V', 'imb_kv02_V', 'ratio', ...
                                  'inst_kv0_V', 'inst_kv02_V', 'THD_kv0_percent', 'THD_kv02_percent'});
    Cmp = [Cmp; row]; %#ok<AGROW>
end

% ---------------- 3. capacitances (mF) ----------------
smU = compose('C_u%d_mF', 1:N);  smL = compose('C_l%d_mF', 1:N);
Cap = array2table(1e3*[horzcat(cases.Cu).', horzcat(cases.Cl).'], 'VariableNames', [smU smL]);
Cap = addvars(Cap, string(names).', 'Before', 1, 'NewVariableNames', 'case');
Cap.Cu_min_percent = 100*(min(horzcat(cases.Cu)).'/2.2e-3 - 1);
Cap.Cu_max_percent = 100*(max(horzcat(cases.Cu)).'/2.2e-3 - 1);
Cap.Cl_min_percent = 100*(min(horzcat(cases.Cl)).'/2.2e-3 - 1);
Cap.Cl_max_percent = 100*(max(horzcat(cases.Cl)).'/2.2e-3 - 1);

% ---------------- 4. final 20 ms mean voltage of each capacitor (V) ----------------
Vend = zeros(numel(R), 2*N);
for k = 1:numel(R), Vend(k,:) = [R(k).Vm_u(end,:), R(k).Vm_l(end,:)]; end
Fin = array2table(Vend, 'VariableNames', [compose('vc_u%d_V', 1:N) compose('vc_l%d_V', 1:N)]);
Fin = addvars(Fin, T.case, T.k_v, 'Before', 1, 'NewVariableNames', {'case', 'k_v'});

% ---------------- 5. imbalance against time ----------------
TS = table(R(1).t(:), 'VariableNames', {'t_s'});
for k = 1:numel(R)
    tag = matlab.lang.makeValidName(sprintf('%s_kv%g', R(k).case, R(k).kv));
    TS.([tag '_up_V'])  = R(k).imb_u_t(:);
    TS.([tag '_low_V']) = R(k).imb_l_t(:);
end

% ---------------- write CSV ----------------
writetable(T,   'ctol_summary.csv');
writetable(Cap, 'ctol_capacitances.csv');
writetable(Fin, 'ctol_final_voltages.csv');
writetable(TS,  'ctol_timeseries.csv');

% ---------------- write Excel (one sheet each) ----------------
xl = 'ctol_results.xlsx';
if isfile(xl), delete(xl); end
writetable(T,   xl, 'Sheet', 'summary');
writetable(Cmp, xl, 'Sheet', 'comparison');
writetable(Cap, xl, 'Sheet', 'capacitances');
writetable(Fin, xl, 'Sheet', 'final_voltages');
writetable(TS,  xl, 'Sheet', 'imbalance_vs_time');

% ---------------- write text report ----------------
fid = fopen('ctol_report.txt', 'w');
fprintf(fid, 'Capacitance-tolerance test, P* = 1.5 kW, balanced start, N = %d per arm\n', N);
fprintf(fid, 'imb  = largest difference between the 20 ms means of the capacitor voltages of an arm (measurement window)\n');
fprintf(fid, 'inst = largest instantaneous difference in the same window\n\n');
fprintf(fid, '%-22s %5s | %8s %8s | %8s %8s | %13s | %8s | %6s\n', 'case', 'k_v', ...
        'imb up', 'imb low', 'inst up', 'inst low', 'ripple min-max', 'P (W)', 'THD %');
for k = 1:height(T)
    fprintf(fid, '%-22s %5.1f | %6.3f V %6.3f V | %6.2f V %6.2f V | %5.2f-%5.2f V | %8.1f | %6.2f\n', ...
        T.case(k), T.k_v(k), T.imb_upper_V(k), T.imb_lower_V(k), T.inst_upper_V(k), T.inst_lower_V(k), ...
        T.ripple_min_V(k), T.ripple_max_V(k), T.P_mean_W(k), T.THD_iac_percent(k));
end
fprintf(fid, '\nComparison (worst arm)\n');
fprintf(fid, '%-22s | %10s %10s %7s | %10s %10s\n', 'case', 'imb kv=0', 'imb kv=0.2', 'ratio', 'inst kv=0', 'inst kv=0.2');
for c = 1:height(Cmp)
    fprintf(fid, '%-22s | %8.3f V %8.3f V %7.1f | %8.2f V %8.2f V\n', Cmp.case(c), ...
        Cmp.imb_kv0_V(c), Cmp.imb_kv02_V(c), Cmp.ratio(c), Cmp.inst_kv0_V(c), Cmp.inst_kv02_V(c));
end
fprintf(fid, '\nCapacitances (mF), upper arm then lower arm\n');
for c = 1:numel(cases)
    fprintf(fid, '%-22s | %s | %s\n', names{c}, sprintf('%.3f ', 1e3*cases(c).Cu), sprintf('%.3f ', 1e3*cases(c).Cl));
end
fclose(fid);

type('ctol_report.txt');
fprintf('\nFiles written: ctol_summary.csv, ctol_capacitances.csv, ctol_final_voltages.csv, ctol_timeseries.csv, ctol_report.txt, %s\n', xl);
