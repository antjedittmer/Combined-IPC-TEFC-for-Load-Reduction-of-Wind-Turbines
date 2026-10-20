function best = reproduceIPC_FadeInOpt()
%REPRODUCEIPC_FADEINOPT Re-optimization of the PI-IPC with the IPC/TEF fade-in
%   best = reproduceIPC_FadeInOpt runs, one after another, the PI-IPC
%   optimization for 4, 8 and 13 deg/s and the joint IPC + TEF (K_P)
%   optimization for 8 deg/s: fminsearch first, then fmincon (with the
%   tower constraint) from its result. The joint run starts from the
%   8 deg/s IPC result and TEF K_P = 0.24.
%
%   Results are written to Main/Post_processing/IPCfade_<run> and can be
%   compared with Main/Results_IPC_PI_RateLimitOpt/FadeIn/<run>.
%   Start from the Main folder. See Results_IPC_PI_RateLimitOpt/README.md.

pp = fullfile(pwd, 'Post_processing');
starts = containers.Map({'4','8','13'}, {[0.75 0.22], [0.8 0.3], [0.8 0.3]});
best = struct();
runs = {4, "IPC"; 8, "IPC"; 8, "IPC_TEF_KP"; 13, "IPC"};
for k = 1:size(runs, 1)
    rl = runs{k,1}; vars = runs{k,2};
    if vars == "IPC"
        x0 = starts(num2str(rl)); step = [0.2 0.1]; lb = [0 0]; ub = [2 2]; nEval = 60;
    else
        x0 = [best.RL08_IPC_fmincon, 0.24]; step = [0.2 0.1 0.1]; lb = [0 0 0]; ub = [2 2 4]; nEval = 90;
    end
    for opt = ["fminsearch", "fmincon"]
        name = sprintf('IPCfade_RL%02d_%s_%s', rl, vars, opt);
        o = struct('RateLimits', rl, 'Vars', vars, 'Optimizer', opt, 'x0', x0, ...
            'MaxFunEvals', nEval, 'ResultsFolder', fullfile(pp, name));
        if opt == "fminsearch"
            o.InitialStep = step;
        else
            o.lb = lb; o.ub = ub; o.FiniteDiffStep = 0.05; % noisy cost: larger finite difference steps
        end
        fprintf('\n##### START %s %s, x0 = %s\n', name, datestr(now), mat2str(x0, 4));
        try
            R = optimizeIPC_PI_RateLimits(o);
            if vars == "IPC", x = [R.K_P R.K_I]; else, x = [R.K_P R.K_I R.TEF_K_P]; end
            best.(sprintf('RL%02d_%s_%s', rl, vars, opt)) = x;
            fprintf('##### DONE %s %s: x = %s, cost = %.4f, tower %+.1f %%\n', name, datestr(now), ...
                mat2str(x, 5), R.Cost, 100*R.RelChange.TwrBsMyt);
            x0 = x; % fmincon starts from the fminsearch result
        catch ME
            fprintf('##### FAILED %s: %s\n', name, ME.message);
        end
    end
end
save(fullfile(pp, 'IPCfade_best.mat'), 'best');
fprintf('##### ALL DONE %s\n', datestr(now));
end
