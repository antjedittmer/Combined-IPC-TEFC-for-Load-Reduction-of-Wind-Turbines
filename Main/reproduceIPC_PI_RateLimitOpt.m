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
    runs string = ["RL08" "RL13" "RL04" "RL04_start1" "RL04_start2" "RL04_start3" "RL04_start4"]
end

% Run name, rate limit (deg/s), x0 = [K_P K_I], MaxFunEvals
cfg = {
    "RL04",        4,  [0.354 1.194213], 60
    "RL08",        8,  [0.354 1.194213], 60
    "RL13",        13, [0.354 1.194213], 60
    "RL04_start1", 4,  [0.1 0.05],       40
    "RL04_start2", 4,  [0.3 0.1],        40
    "RL04_start3", 4,  [0.1 0.3],        40
    "RL04_start4", 4,  [0.6227 0.3269],  40
    };

for r = runs
    k = find([cfg{:,1}] == r);
    if isempty(k), error('Unknown run "%s".', r); end
    opts = struct('RateLimits', cfg{k,2}, 'x0', cfg{k,3}, 'MaxFunEvals', cfg{k,4}, ...
        'ResultsFolder', fullfile(pwd, 'Post_processing', char("IPC_PI_RateLimitOpt_" + r)));
    optimizeIPC_PI_RateLimits(opts);
end
end
