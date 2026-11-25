% RUN_KV_SWEEP
% Source: 13 thadkv(3).zip. Local neighbor gain sensitivity and convergence.
% Model: MMC_Per_arm_outer_v5_G2_tests.slx (R2024a), 8 SM/arm, Vdc=800 V.
% Part A: identical and alternating +/-20% C, four gains, 8 runs.
% Part B: SM3=102 V, SM6=98 V initial condition, four gains, 4 runs.
% Outputs: kv_sweep_results.mat, kv_sweep_summary.csv, kv_sweep.png/fig.
src = 'MMC_Per_arm_outer_v5_G2_tests';
mdl = [src '_kv'];
Tstop = 2; Cnom = 2.2e-3; N = 8;
KV = [0.05 0.10 0.15 0.20]; t0 = 0.5;
VC0_PARAM = ''; DV0 = 2;
alt = repmat([1; -1], N/2, 1);
pat = struct('name', {'identical', 'alternating +/-20 %'}, ...
             'Cu', {Cnom*ones(N,1), Cnom*(1 + 0.20*alt)}, ...
             'Cl', {Cnom*ones(N,1), Cnom*(1 - 0.20*alt)});
if bdIsLoaded(mdl), close_system(mdl,0); end
load_system(src); save_system(src, mdl);
for i = 1:N
    set_param(sprintf('%s/HB_u%d',mdl,i),'C',sprintf('C_u(%d)',i));
    set_param(sprintf('%s/HB_l%d',mdl,i),'C',sprintf('C_l(%d)',i));
end
set_param([mdl '/P SELECT  up = staircase  down = fixed'],'sw','0');
charts = find(sfroot,'-isa','Stateflow.EMChart');
isLocal = arrayfun(@(c) startsWith(c.Path,[mdl '/']) && contains(c.Path,'Local Ctrl'),charts);
charts = charts(isLocal);
assert(numel(charts)==2*N,'Expected %d local controls.',2*N);
R = [];
for p = 1:numel(pat)
    assignin('base','C_u',pat(p).Cu);
    assignin('base','C_l',pat(p).Cl);
    for kv = KV
        fprintf('Part A: %s, k_v = %.2f\n',pat(p).name,kv);
        R = [R run_one(mdl,charts,kv,Tstop,t0,'A',pat(p).name)]; %#ok<AGROW>
    end
end
blk3 = [mdl '/HB_u3']; blk6 = [mdl '/HB_u6'];
dp = fieldnames(get_param(blk3,'DialogParameters'));
if isempty(VC0_PARAM)
    cand = dp(~cellfun(@isempty,regexpi(dp,'(vc.*0|v.*0$|init|ini$|^ic$|^x0$)','once')));
    cand = setdiff(cand,{'C'});
else
    cand = {VC0_PARAM};
end
if numel(cand)==1
    vp = cand{1};
    vnom = get_param(blk3,vp);
    fprintf('Part B voltage-init parameter: %s = %s\n',vp,vnom);
    set_param(blk3,vp,sprintf('(%s) + %g',vnom,DV0));
    set_param(blk6,vp,sprintf('(%s) - %g',get_param(blk6,vp),DV0));
    assignin('base','C_u',pat(1).Cu);
    assignin('base','C_l',pat(1).Cl);
    for kv = KV
        fprintf('Part B: upper SM3=102 V, SM6=98 V, k_v=%.2f\n',kv);
        R = [R run_one(mdl,charts,kv,Tstop,t0,'B', ...
            sprintf('identical, HB_u3 +%g V, HB_u6 -%g V',DV0,DV0))]; %#ok<AGROW>
    end
else
    fprintf('Part B skipped: ambiguous initial-voltage mask parameter.\n');
    for k=1:numel(dp)
        fprintf('  %-20s = %s\n',dp{k},get_param(blk3,dp{k}));
    end
    fprintf('Set VC0_PARAM at top of this script and rerun.\n');
end
close_system(mdl,0);
save('kv_sweep_results.mat','R','KV','DV0');
keep = {'part','case','kv','imb_u','imb_l','imb_worst','inst_worst', ...
    'ripple_min','ripple_max','Pmean','thd','h1','h3','h5', ...
    't_dev3_1V','t_dev3_05V','t_imb_05V','dev3_start'};
T = struct2table(rmfield(R,setdiff(fieldnames(R),keep)),'AsArray',true);
writetable(T,'kv_sweep_summary.csv');
disp(T);
A=R(strcmp({R.part},'A')); B=R(strcmp({R.part},'B'));
fig=figure('Color','w','Position',[100 100 1200 380]);
tiledlayout(1,3,'TileSpacing','compact');
nexttile; hold on; grid on;
for p=1:numel(pat)
    a=A(strcmp({A.case},pat(p).name));
    plot([a.kv],[a.imb_worst],'o-','LineWidth',1.2,'DisplayName',pat(p).name);
end
xlabel('k_v (V^{-1})'); ylabel('20 ms mean spread, worst arm (V)');
title('Filtered voltage imbalance'); legend('Location','best'); xticks(KV);
nexttile; hold on; grid on;
for p=1:numel(pat)
    a=A(strcmp({A.case},pat(p).name));
    plot([a.kv],[a.thd],'s-','LineWidth',1.2,'DisplayName',pat(p).name);
end
xlabel('k_v (V^{-1})'); ylabel('THD, harmonics 2–20 (%)');
title('Grid-current THD'); legend('Location','best'); xticks(KV);
nexttile; hold on; grid on;
for k=1:numel(B)
    plot(B(k).t,B(k).dev3,'LineWidth',1.2, ...
        'DisplayName',sprintf('k_v = %.2f',B(k).kv));
end
xlabel('Time (s)'); ylabel('HB_u3 - arm mean (V)');
title('Convergence from +/-2 V');
if ~isempty(B),legend('Location','northeast');end
xlim([0 1]);
exportgraphics(fig,'kv_sweep.png','Resolution',300); savefig(fig,'kv_sweep.fig');
function r=run_one(mdl,charts,kv,Tstop,t0,part,name)
    for k=1:numel(charts)
        s=charts(k).Script;
        assert(~isempty(regexp(s,'k_v\s*=\s*[\d.eE+-]+;','once')),'k_v not found.');
        charts(k).Script=regexprep(s,'k_v\s*=\s*[\d.eE+-]+;',sprintf('k_v = %g;',kv),'once');
    end
    out=sim(mdl,'StopTime',num2str(Tstop)); L=out.logsout;
    Vu=L.get('Vc_up').Values; Vl=L.get('Vc_low').Values;
    iac=L.get('i_ac').Values; P=L.get('P_UPPER').Values;
    [imb_u,inst_u,t,imb_u_t,rip_u,Vm_u]=arm_metrics(Vu,t0);
    [imb_l,inst_l,~,imb_l_t,rip_l,Vm_l]=arm_metrics(Vl,t0);
    [thd,a]=thd_2_20(iac,Tstop-0.2,Tstop);
    dev3=Vm_u(:,3)-mean(Vm_u,2);
    r.part=part; r.case=name; r.kv=kv;
    r.imb_u=imb_u; r.imb_l=imb_l; r.imb_worst=max(imb_u,imb_l);
    r.inst_worst=max(inst_u,inst_l);
    r.ripple_min=min([rip_u rip_l]); r.ripple_max=max([rip_u rip_l]);
    r.Pmean=mean(P.Data(P.Time>=Tstop-0.2));
    r.thd=thd; r.h1=a(1); r.h3=a(3); r.h5=a(5);
    r.t_dev3_1V=NaN; r.t_dev3_05V=NaN; r.t_imb_05V=NaN; r.dev3_start=NaN;
    if part=='B'
        r.t_dev3_1V=last_above(t,abs(dev3),1.0);
        r.t_dev3_05V=last_above(t,abs(dev3),0.5);
        r.t_imb_05V=last_above(t,imb_u_t,0.5);
        k0=find(~isnan(dev3),1,'first'); r.dev3_start=dev3(k0);
    end
    r.t=t; r.imb_u_t=imb_u_t; r.imb_l_t=imb_l_t;
    r.Vm_u=Vm_u; r.Vm_l=Vm_l; r.dev3=dev3;
end
function ts=last_above(t,x,thr)
    k=find(x>=thr,1,'last');
    if isempty(k),ts=NaN;elseif k==numel(x),ts=Inf;else,ts=t(k+1);end
end
function [imb,inst,t,imb_t,ripple,Vm]=arm_metrics(ts,t0)
    V=squeeze(ts.Data);if size(V,1)~=numel(ts.Time),V=V.';end
    t=ts.Time;dt=median(diff(t));n=round(0.02/dt);
    Vm=filter(ones(n,1)/n,1,V);
    imb_t=max(Vm,[],2)-min(Vm,[],2);
    imb_t(1:n)=NaN;Vm(1:n,:)=NaN;
    w=t>=t0;imb=max(imb_t(w));
    inst=max(max(V(w,:),[],2)-min(V(w,:),[],2));
    last=t>=t(end)-0.02;
    ripple=max(V(last,:),[],1)-min(V(last,:),[],1);
    q=max(1,round(1e-3/dt));
    t=t(1:q:end);imb_t=imb_t(1:q:end);Vm=Vm(1:q:end,:);
end
function [d,a]=thd_2_20(ts,t1,t2)
    w=ts.Time>=t1 & ts.Time<t2;
    x=squeeze(ts.Data(w));t=ts.Time(w);x=x(:);t=t(:);
    a=zeros(20,1);
    for h=1:20
        a(h)=abs(2*mean(x.*exp(-1j*2*pi*50*h*t)));
    end
    d=100*sqrt(sum(a(2:20).^2))/a(1);
end
