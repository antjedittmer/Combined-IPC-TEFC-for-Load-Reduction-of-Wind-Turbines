function best = runIPC_KD_FadeIn()
%RUNIPC_KD_FADEIN Joint optimization of the IPC K_P, K_I and K_D with the fade-in
%   best = runIPC_KD_FadeIn checks whether a derivative gain of the IPC
%   pays off with the IPC/TEF fade-in: K_P, K_I and K_D of the IPC are
%   optimized jointly (Vars "IPC_KD", 8 deg/s, TEF off, 18 m/s, NTM class A,
%   optimization set) as in reproduceIPC_FadeInOpt: fminsearch first, then
%   fmincon (tower DEL <= baseline) from its result. Start: the 8 deg/s
%   fade-in IPC gains (best.RL08_IPC_fmincon) and K_D = 0.
%
%   Results: Main/Post_processing/IPCfade_RL08_IPC_KD_<optimizer> (full),
%   copies of History, Results and Summary in Results_IPC_PI_RateLimitOpt/
%   FadeIn/RL08_IPC_KD_<optimizer>, the gains [K_P, K_I, K_D] as
%   best.RL08_IPC_KD_<optimizer> in FadeIn/best.mat. Finished steps are
%   skipped when the function is started again. Start from the Main folder.

pp = fullfile(pwd, 'Post_processing');
fadeIn = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn');
fBest = fullfile(fadeIn, 'best.mat');
B = load(fBest, 'best');
best = B.best;

x0 = [best.RL08_IPC_fmincon, 0];
for opt = ["fminsearch", "fmincon"]
    key = "RL08_IPC_KD_" + opt;
    folder = fullfile(pp, char("IPCfade_RL08_IPC_KD_" + opt));
    if ~isfile(fullfile(folder, 'Results.mat'))
        o = struct('RateLimits', 8, 'Vars', "IPC_KD", 'Optimizer', opt, 'x0', x0, ...
            'MaxFunEvals', 90, 'ResultsFolder', folder);
        if opt == "fminsearch"
            o.InitialStep = [0.2 0.1 0.1];
        else
            o.lb = [0 0 -2]; o.ub = [2 2 2]; o.FiniteDiffStep = 0.05;     % noisy cost: larger finite difference steps
        end
        fprintf('\n##### START %s %s, x0 = %s\n', key, datestr(now), mat2str(x0, 4)); %#ok<TNOW1,DATST>
        optimizeIPC_PI_RateLimits(o);
    end
    R = load(fullfile(folder, 'Results.mat'), 'Results');
    x = [R.Results.K_P, R.Results.K_I, R.Results.K_D];
    fprintf('##### %s: x = %s, cost = %.4f, tower %+.2f %%\n', key, mat2str(x, 5), ...
        R.Results.Cost, 100*R.Results.RelChange.TwrBsMyt);
    best.(key) = x;
    out = fullfile(fadeIn, char(key));
    if ~isfolder(out), mkdir(out); end
    for f = ["History_RL08.csv", "Results.mat", "Summary.csv"]
        copyfile(fullfile(folder, f), fullfile(out, f));
    end
    x0 = x; % fmincon starts from the fminsearch result
end
save(fBest, 'best');
fprintf('##### ALL DONE %s\n', datestr(now)); %#ok<TNOW1,DATST>
end
