function reproduceIPC_PI_RateLimitOpt(runs)
%REPRODUCEIPC_PI_RATELIMITOPT Re-run the PI-IPC rate limit optimizations
%   reproduceIPC_PI_RateLimitOpt runs all optimizations stored in
%   Main/Results_IPC_PI_RateLimitOpt one after another (several hours each).
%   reproduceIPC_PI_RateLimitOpt("RL08") runs only the selected run(s).
%
%   Results are written to Main/Post_processing/IPC_PI_RateLimitOpt_<run>
%   and can be compared with Main/Results_IPC_PI_RateLimitOpt/<run>.
%   Start from the Main folder. See Results_IPC_PI_RateLimitOpt/README.md.

arguments
    runs string = ["RL08" "RL13" "RL04" "RL04_start1" "RL04_start2" "RL04_start3" "RL04_start4" ...
                   "RL04_refine" "RL08_refine" "RL13_refine" ...
                   "RL04_fmincon" "RL08_fmincon" "RL13_fmincon" "RL04_start5"]
end

% Run name, rate limit (deg/s), x0 = [K_P K_I], MaxFunEvals, optimizer
% (fmincon: blade root DEL with the constraint tower DEL change <= 0, TolX 1e-3)
cfg = {
    "RL04",        4,  [0.354 1.194213], 60, "fminsearch"
    "RL08",        8,  [0.354 1.194213], 60, "fminsearch"
    "RL13",        13, [0.354 1.194213], 60, "fminsearch"
    "RL04_start1", 4,  [0.1 0.05],       40, "fminsearch"
    "RL04_start2", 4,  [0.3 0.1],        40, "fminsearch"
    "RL04_start3", 4,  [0.1 0.3],        40, "fminsearch"
    "RL04_start4", 4,  [0.6227 0.3269],  40, "fminsearch"
    "RL04_refine", 4,  [0.732890625000002 0.217441406249995], 60, "fminsearch"
    "RL08_refine", 8,  [0.622698226547242 0.326937128775788], 60, "fminsearch"
    "RL13_refine", 13, [0.632336119079591 0.341532235317994], 60, "fminsearch"
    "RL04_fmincon", 4,  [0.745529118955138 0.216761570066209], 60, "fmincon"
    "RL08_fmincon", 8,  [0.622211743557752 0.316848053317473], 60, "fmincon"
    "RL13_fmincon", 13, [0.632336119079591 0.341532235317994], 60, "fmincon"
    "RL04_start5",  4,  [0 0.1],                               60, "fminsearch"
    };

for r = runs
    k = find([cfg{:,1}] == r);
    if isempty(k), error('Unknown run "%s".', r); end
    opts = struct('RateLimits', cfg{k,2}, 'x0', cfg{k,3}, 'MaxFunEvals', cfg{k,4}, ...
        'Optimizer', cfg{k,5}, ...
        'ResultsFolder', fullfile(pwd, 'Post_processing', char("IPC_PI_RateLimitOpt_" + r)));
    if cfg{k,5} == "fmincon", opts.TolX = 1e-3; end
    optimizeIPC_PI_RateLimits(opts);
end
end
