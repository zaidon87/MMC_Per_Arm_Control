% Isolated runner for the four reproducible aligned-delay cases.
repoRoot = fileparts(fileparts(mfilename('fullpath')));
modelDir = fullfile(repoRoot,'experiments','aligned','models');
scriptDir = fullfile(repoRoot,'experiments','aligned','scripts');
ref = fullfile(repoRoot,'experiments','followup','data','followup_results.mat');
outDir = fullfile(tempdir,['mmc_aligned_' datestr(now,'yyyymmdd_HHMMSSFFF')]);
mkdir(outDir);
copyfile(fullfile(modelDir,'*.slx'),outDir);
copyfile(fullfile(scriptDir,'*.m'),outDir);
if isfile(ref), copyfile(ref,outDir); end
oldDir = pwd;
cleanupObj = onCleanup(@() cd(oldDir));
cd(outDir);
run('run_aligned_cases.m');
fprintf('Aligned simulation output: %s
',outDir);