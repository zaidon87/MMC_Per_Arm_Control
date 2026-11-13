% Read-only verification of archived MMC MAT datasets (MATLAB).
% Requires importing the complete supplemental ZIP into this repository.
root = fileparts(fileparts(mfilename('fullpath')));
matrix = {
'experiments/base/data/three_cases_results.mat', 3;
'experiments/followup/data/followup_results.mat', 4;
'experiments/aligned/data/aligned_results.mat', 4
};
required = {'Vc_up','Vc_low','P_UP','Q_UP','Pstar_ref','v_ac','i_ac', ...
 'i_u','i_l','m_up','m_low','i_load','i_grid','name','grid'};
for a=1:size(matrix,1)
  f = fullfile(root,strrep(matrix{a,1},'/',filesep));
  assert(isfile(f),'Missing uploaded data: %s',f);
  S=load(f,'R');
  assert(numel(S.R)==matrix{a,2},'Wrong case count for %s',f);
  for k=1:numel(S.R)
    assert(all(isfield(S.R(k),required)),'Missing field in case %d',k);
    assert(size(S.R(k).Vc_up.Data,2)==8,'Unexpected upper SM count');
    assert(size(S.R(k).Vc_low.Data,2)==8,'Unexpected lower SM count');
    t=S.R(k).Vc_up.Time;
    U=S.R(k).Vc_up.Data;
    spread=max(U,[],2)-min(U,[],2);
    steady=t>=min(0.5,t(end));
    fprintf('%s | case %d: %s | samples=%d | peak upper spread after 0.5 s=%.3f V\n', ...
       matrix{a,1},k,S.R(k).name,numel(t),max(spread(steady)));
  end
end
disp('PASS: 11 datasets identified, with 8 SM voltages per arm.');
