% Isolated runner for all three reproducible base cases.
repoRoot = fileparts(fileparts(mfilename('fullpath')));
modelDir = fullfile(repoRoot,'experiments','base','models');
scriptDir = fullfile(repoRoot,'experiments','base','scripts');
outDir = fullfile(tempdir,['mmc_base_' datestr(now,'yyyymmdd_HHMMSSFFF')]);
mkdir(outDir);
copyfile(fullfile(modelDir,'*.slx'),outDir);
copyfile(fullfile(scriptDir,'*.m'),outDir);
oldDir = pwd;
cleanupObj = onCleanup(@() cd(oldDir));
cd(outDir);
run('run_three_cases.m');
fprintf('Base simulation output: %s
',outDir);