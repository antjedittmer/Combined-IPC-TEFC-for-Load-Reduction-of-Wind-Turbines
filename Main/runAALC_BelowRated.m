function best = runAALC_BelowRated(windSpeeds)
%RUNAALC_BELOWRATED AALC optimizations below rated wind speed and cross check
%   best = runAALC_BelowRated optimizes the IPC [K_P, K_I] and the TEF K_P
%   together (Vars "IPC_TEF_KP", 8 deg/s, IPC/TEF fade-in, NTM class A,
%   optimization set) at 4, 6 and 8 m/s with fminsearch from IPC K_P = 0,
%   K_I = 1, TEF K_P = 1. No fmincon run follows, since the tower DEL drops
%   below rated anyway. The power is not constrained (it is reported as
%   RelPower).
%   Afterwards every gain set (the three below rated fminsearch optima and the AALC
%   gains of 18 m/s, best.RL08_IPC_TEF_KP_fmincon) is evaluated on the test
%   set (TurbKlasseAnewSeed) at 4, 6 and 8 m/s with checkIPC_WindSpeeds, to
%   see whether the AALC needs a gain scheduling below rated.
%   best = runAALC_BelowRated(windSpeeds) uses other wind speeds (m/s).
%
%   Results: Main/Post_processing/AALCbelow_<ws>mps_<optimizer> (full),
%   copies of History, Results and Summary in Results_IPC_PI_RateLimitOpt/
%   FadeIn/RL08_IPC_TEF_KP_<ws>mps_<optimizer>, the gains as
%   best.RL08_IPC_TEF_KP_<ws>mps_<optimizer> in FadeIn/best.mat, and the
%   cross check in FadeIn/WindSpeedCheck/AALCbelow_<gains>_TurbKlasseAnewSeed.
%   Finished steps are skipped when the function is started again.
%   Start from the Main folder.

arguments
    windSpeeds (1,:) double = [4 6 8]
end

pp = fullfile(pwd, 'Post_processing');
fadeIn = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn');
fBest = fullfile(fadeIn, 'best.mat');
B = load(fBest, 'best');
best = B.best;

for ws = windSpeeds
    x0 = [0 1 1];
    for opt = "fminsearch"
        key = sprintf("RL08_IPC_TEF_KP_%02dmps_", ws) + opt;
        folder = fullfile(pp, char(sprintf("AALCbelow_%02dmps_", ws) + opt));
        if ~isfile(fullfile(folder, 'Results.mat'))
            o = struct('RateLimits', 8, 'Vars', "IPC_TEF_KP", 'Optimizer', opt, 'x0', x0, ...
                'MaxFunEvals', 90, 'ResultsFolder', folder, ...
                'WindFile', fullfile("WindData", "Eigene_Wind_Dateien", "TurbKlasseA", sprintf("%dmps.bts", ws)));
            if opt == "fminsearch"
                o.InitialStep = [0.2 0.1 0.1];
            else
                o.lb = [0 0 0]; o.ub = [2 2 4]; o.FiniteDiffStep = 0.05;  % noisy cost: larger finite difference steps
            end
            fprintf('\n##### START %s %s, x0 = %s\n', key, datestr(now), mat2str(x0, 4)); %#ok<TNOW1,DATST>
            optimizeIPC_PI_RateLimits(o);
        end
        R = load(fullfile(folder, 'Results.mat'), 'Results');
        x = [R.Results.K_P, R.Results.K_I, R.Results.TEF_K_P];
        fprintf('##### %s: x = %s, cost = %.4f, tower %+.2f %%, power %+.2f %%\n', key, mat2str(x, 5), ...
            R.Results.Cost, 100*R.Results.RelChange.TwrBsMyt, 100*R.Results.RelChange.Power);
        best.(key) = x;
        out = fullfile(fadeIn, char(key));
        if ~isfolder(out), mkdir(out); end
        for f = ["History_RL08.csv", "Results.mat", "Summary.csv"]
            copyfile(fullfile(folder, f), fullfile(out, f));
        end
    end
    save(fBest, 'best');
end

% Cross check on the test set: every gain set at every below rated wind speed
gainSets = [arrayfun(@(ws) sprintf("%02dmps", ws), windSpeeds), "18mps"];
for g = gainSets
    if g == "18mps"
        x = best.RL08_IPC_TEF_KP_fmincon;
    else
        x = best.("RL08_IPC_TEF_KP_" + g + "_fminsearch");
    end
    checkIPC_WindSpeeds(struct('Vars', "IPC_TEF_KP", 'Gains', x, 'WindSpeeds', windSpeeds, ...
        'Name', "AALCbelow_" + g + "_TurbKlasseAnewSeed"));
end
fprintf('##### ALL DONE %s\n', datestr(now)); %#ok<TNOW1,DATST>
end
