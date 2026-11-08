function T = checkIPC_KD_Seeds()
%CHECKIPC_KD_SEEDS PI and PID IPC gains (8 deg/s, fade-in) on the 18 m/s test seeds
%   T = checkIPC_KD_Seeds evaluates the PI gains (best.RL08_IPC_fmincon,
%   K_D = 0) and the PID gains (best.RL08_IPC_KD_fmincon, runIPC_KD_FadeIn)
%   without optimization (Optimizer "none", Vars "IPC_KD") on the 18 m/s
%   seeds B (Eigene_Wind_Dateien/18mps.bts) and C (TurbKlasseAnewSeed/
%   18mps.bts), each against a baseline with IPC off on the same seed.
%   Results: Main/Post_processing/IPCfade_RL08_IPC_KD_seed<B|C>, the table
%   in Results_IPC_PI_RateLimitOpt/FadeIn/RL08_IPC_KD_Seeds.csv. Start from
%   the Main folder.

B = load(fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'best.mat'), 'best');
gains = [B.best.RL08_IPC_fmincon, 0; B.best.RL08_IPC_KD_fmincon];
seeds = {'B', fullfile("WindData", "Eigene_Wind_Dateien", "18mps.bts"); ...
         'C', fullfile("WindData", "Eigene_Wind_Dateien", "TurbKlasseAnewSeed", "18mps.bts")};
T = table();
for s = 1:size(seeds, 1)
    folder = fullfile(pwd, 'Post_processing', ['IPCfade_RL08_IPC_KD_seed', seeds{s,1}]);
    if ~isfile(fullfile(folder, 'History_RL08.csv'))
        optimizeIPC_PI_RateLimits(struct('RateLimits', 8, 'Vars', "IPC_KD", 'Optimizer', "none", ...
            'x0', gains, 'WindFile', seeds{s,2}, 'ResultsFolder', folder));
    end
    H = readtable(fullfile(folder, 'History_RL08.csv'));
    H.Seed = repmat(string(seeds{s,1}), height(H), 1);
    T = [T; H(:, {'Seed', 'K_P', 'K_I', 'K_D', 'Cost', 'RelDEL_RootMyc1', 'RelDEL_RootMyc2', ...
        'RelDEL_RootMyc3', 'RelDEL_TwrBsMyt', 'RelADC', 'RelPower'})]; %#ok<AGROW>
end
writetable(T, fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'RL08_IPC_KD_Seeds.csv'));
disp(T)
end
