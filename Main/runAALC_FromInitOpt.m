function best = runAALC_FromInitOpt()
%RUNAALC_FROMINITOPT AALC optimization from IPC K_I = 1, TEF K_P = 1 and wind speed sweep
%   best = runAALC_FromInitOpt optimizes the IPC [K_P, K_I] and the TEF K_P
%   together (Vars "IPC_TEF_KP", 8 deg/s, IPC/TEF fade-in, 18 m/s, NTM
%   class A, optimization set) as reproduceIPC_FadeInOpt, but starting from
%   the initial gains of the paper (IPC K_P = 0, K_I = 1, TEF K_P = 1)
%   instead of the optimized IPC gains: fminsearch first, then fmincon
%   (tower DEL <= baseline) from its result. Afterwards the new AALC gains
%   and the AALC gains started from the IPC gains (best.RL08_IPC_TEF_KP_fmincon)
%   are evaluated on the test set (TurbKlasseAnewSeed, 12-25 m/s) with
%   checkIPC_WindSpeeds, to see whether the AALC needs a gain scheduling.
%
%   Results: Main/Post_processing/AALCinit_<optimizer> (full), copies of
%   History, Results and Summary in Results_IPC_PI_RateLimitOpt/FadeIn/
%   RL08_IPC_TEF_KP_init11_<optimizer>, the gains as best.RL08_IPC_TEF_KP_init11_
%   <optimizer> in FadeIn/best.mat, and the sweeps in FadeIn/WindSpeedCheck.
%   Finished steps are skipped when the function is started again.
%   Start from the Main folder.

pp = fullfile(pwd, 'Post_processing');
fadeIn = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn');
fBest = fullfile(fadeIn, 'best.mat');
B = load(fBest, 'best');
best = B.best;

x0 = [0 1 1];
for opt = ["fminsearch", "fmincon"]
    key = "RL08_IPC_TEF_KP_init11_" + opt;
    folder = fullfile(pp, char("AALCinit_" + opt));
    if ~isfile(fullfile(folder, 'Results.mat'))
        o = struct('RateLimits', 8, 'Vars', "IPC_TEF_KP", 'Optimizer', opt, 'x0', x0, ...
            'MaxFunEvals', 90, 'ResultsFolder', folder);
        if opt == "fminsearch"
            o.InitialStep = [0.2 0.1 0.1];
        else
            o.lb = [0 0 0]; o.ub = [2 2 4]; o.FiniteDiffStep = 0.05;      % noisy cost: larger finite difference steps
        end
        fprintf('\n##### START %s %s, x0 = %s\n', key, datestr(now), mat2str(x0, 4)); %#ok<TNOW1,DATST>
        optimizeIPC_PI_RateLimits(o);
    end
    R = load(fullfile(folder, 'Results.mat'), 'Results');
    x = [R.Results.K_P, R.Results.K_I, R.Results.TEF_K_P];
    fprintf('##### %s: x = %s, cost = %.4f, tower %+.2f %%\n', key, mat2str(x, 5), ...
        R.Results.Cost, 100*R.Results.RelChange.TwrBsMyt);
    best.(key) = x;
    out = fullfile(fadeIn, char(key));
    if ~isfolder(out), mkdir(out); end
    for f = ["History_RL08.csv", "Results.mat", "Summary.csv"]
        copyfile(fullfile(folder, f), fullfile(out, f));
    end
    x0 = x;                                                                % fmincon starts from the fminsearch result
end
save(fBest, 'best');

% Wind speed sweep on the test set: new AALC gains and AALC from the IPC gains
sweeps = {"AALCinit11_RL08_TurbKlasseAnewSeed", best.RL08_IPC_TEF_KP_init11_fmincon;
          "AALCfromIPC_RL08_TurbKlasseAnewSeed", best.RL08_IPC_TEF_KP_fmincon};
for k = 1:size(sweeps, 1)
    checkIPC_WindSpeeds(struct('Vars', "IPC_TEF_KP", 'Gains', sweeps{k, 2}, 'Name', sweeps{k, 1}));
end
fprintf('##### ALL DONE %s\n', datestr(now)); %#ok<TNOW1,DATST>
end
