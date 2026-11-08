function best = runTEF_KPKI_FadeIn()
%RUNTEF_KPKI_FADEIN Joint optimization of the TEF K_P and K_I with the fade-in
%   best = runTEF_KPKI_FadeIn checks whether an integral gain of the TEF
%   controller pays off: K_P and K_I of the TEF are optimized jointly
%   (Vars "TEF_KPKI", TEF K_D = 0, 8 deg/s, 18 m/s, NTM class A,
%   optimization set) with the IPC fixed at the gains of the joint IPC + TEF
%   fade-in optimization (best.RL08_IPC_TEF_KP_fmincon), as in
%   reproduceIPC_FadeInOpt: fminsearch first, then fmincon (tower DEL <=
%   baseline) from its result. Start: TEF K_P of that optimization, K_I = 0.
%
%   Results: Main/Post_processing/IPCfade_RL08_TEF_KPKI_<optimizer> (full),
%   copies of History, Results and Summary in Results_IPC_PI_RateLimitOpt/
%   FadeIn/RL08_TEF_KPKI_<optimizer>, the gains [IPC K_P, IPC K_I, TEF K_P,
%   TEF K_I] as best.RL08_TEF_KPKI_<optimizer> in FadeIn/best.mat. Finished
%   steps are skipped when the function is started again. Start from the
%   Main folder.

pp = fullfile(pwd, 'Post_processing');
fadeIn = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn');
fBest = fullfile(fadeIn, 'best.mat');
B = load(fBest, 'best');
best = B.best;

ipcGains = best.RL08_IPC_TEF_KP_fmincon(1:2);
x0 = [best.RL08_IPC_TEF_KP_fmincon(3), 0];
for opt = ["fminsearch", "fmincon"]
    key = "RL08_TEF_KPKI_" + opt;
    folder = fullfile(pp, char("IPCfade_RL08_TEF_KPKI_" + opt));
    if ~isfile(fullfile(folder, 'Results.mat'))
        o = struct('RateLimits', 8, 'Vars', "TEF_KPKI", 'IPCGains', ipcGains, ...
            'Optimizer', opt, 'x0', x0, 'MaxFunEvals', 60, 'ResultsFolder', folder);
        if opt == "fminsearch"
            o.InitialStep = [0.2 0.1];
        else
            o.lb = [0 0]; o.ub = [4 4]; o.FiniteDiffStep = 0.05;     % noisy cost: larger finite difference steps
        end
        fprintf('\n##### START %s %s, IPC = %s, x0 = %s\n', key, datestr(now), ...
            mat2str(ipcGains, 4), mat2str(x0, 4)); %#ok<TNOW1,DATST>
        optimizeIPC_PI_RateLimits(o);
    end
    R = load(fullfile(folder, 'Results.mat'), 'Results');
    x = [R.Results.TEF_K_P, R.Results.TEF_K_I];
    fprintf('##### %s: TEF K_P, K_I = %s, cost = %.4f, tower %+.2f %%\n', key, mat2str(x, 5), ...
        R.Results.Cost, 100*R.Results.RelChange.TwrBsMyt);
    best.(key) = [ipcGains, x];
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
