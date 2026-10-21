function Summary = checkIPC_WindSpeeds(opts)
%CHECKIPC_WINDSPEEDS Fixed IPC gains at other wind speeds (test set)
%   Summary = checkIPC_WindSpeeds evaluates the PI-IPC with the fixed gains
%   optimized for 8 deg/s at 18 m/s (fmincon, IPC/TEF fade-in, K_P = 1.2219,
%   K_I = 0.3702) on the wind fields of a test set, without optimization:
%   for every wind speed a baseline (IPC off) and an IPC simulation with
%   the rate limit 8 deg/s (optimizeIPC_PI_RateLimits, Optimizer "none").
%   It shows whether the gains tuned at 18 m/s also work at the other
%   wind speeds of Region III, i.e. whether a gain scheduling is needed.
%   The wind speeds are run one after another (about 3 min each). Wind
%   speeds whose Results.mat exists are not simulated again.
%
%   Options (struct):
%     WindSet        folder in WindData/Eigene_Wind_Dateien (default
%                    "TurbKlasseAnewSeed": verification set, class A, new
%                    seed; "" for the verification set with class B)
%     WindSpeeds     mean wind speeds in m/s (default 12:2:24 and 25)
%     Gains          IPC [K_P, K_I] (default fade-in fmincon, 8 deg/s)
%     RateLimit      pitch rate limit in deg/s (default 8)
%     GainScheduling IPC gain scheduling (see optimizeIPC_PI_RateLimits),
%                    default [] (none)
%     Name           name of the run (default "fixedRL08_" + WindSet)
%
%   Results: simulations in Main/Post_processing/IPCcheck_<Name>/<ws>mps
%   (git-ignored, with time series), summary in
%   Results_IPC_PI_RateLimitOpt/FadeIn/WindSpeedCheck/<Name>.csv/.mat and
%   the figure <Name>.png. Start from the Main folder.

arguments
    opts struct = struct()
end

B = load(fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'best.mat'), 'best');
def.WindSet        = "TurbKlasseAnewSeed";
def.WindSpeeds     = [12 14 16 18 20 22 24 25];
def.Gains          = B.best.RL08_IPC_fmincon;
def.RateLimit      = 8;
def.GainScheduling = [];
def.Name           = "";
fn = fieldnames(def);
for k = 1:numel(fn)
    if ~isfield(opts, fn{k}), opts.(fn{k}) = def.(fn{k}); end
end
if opts.Name == ""
    setName = opts.WindSet;
    if setName == "", setName = "KlasseB"; end
    opts.Name = sprintf("fixedRL%02d_", opts.RateLimit) + setName;
end
simDir = fullfile(pwd, 'Post_processing', char("IPCcheck_" + opts.Name));
sumDir = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'WindSpeedCheck');
if ~isfolder(sumDir), mkdir(sumDir); end

nW = numel(opts.WindSpeeds);
v = nan(nW, 1);
S = table(opts.WindSpeeds(:), v, v, v, v, v, v, v, v, v, v, ...
    'VariableNames', {'WindSpeed_mps', 'MeanPitch_deg', 'RelDEL_RootMyc1', 'RelDEL_RootMyc2', ...
    'RelDEL_RootMyc3', 'RelDEL_RootMycMax', 'RelDEL_TwrBsMyt', 'RelADC', 'RelPower', 'MaxPitchRate_degps', 'MaxPitchRateFAST_degps'});
for w = 1:nW
    ws = opts.WindSpeeds(w);
    folder = fullfile(simDir, sprintf('%02dmps', ws));
    fRes = fullfile(folder, 'Results.mat');
    if ~isfile(fRes)
        fprintf('\n##### %s: %g m/s, IPC K_P = %.4f, K_I = %.4f, %g deg/s\n', ...
            opts.Name, ws, opts.Gains(1), opts.Gains(2), opts.RateLimit);
        optimizeIPC_PI_RateLimits(struct('RateLimits', opts.RateLimit, 'Optimizer', "none", ...
            'x0', opts.Gains, 'WindFile', fullfile("WindData", "Eigene_Wind_Dateien", opts.WindSet, sprintf("%dmps.bts", ws)), ...
            'GainScheduling', opts.GainScheduling, 'SaveTimeSeries', true, 'ResultsFolder', folder));
    end
    R = load(fRes, 'Results');
    r = R.Results(1);
    S.MeanPitch_deg(w)      = r.Baseline.MeanPitch;
    S{w, {'RelDEL_RootMyc1', 'RelDEL_RootMyc2', 'RelDEL_RootMyc3'}} = r.RelChange.RootMyc;
    S.RelDEL_RootMycMax(w)  = max(r.RelChange.RootMyc);
    S.RelDEL_TwrBsMyt(w)    = r.RelChange.TwrBsMyt;
    S.RelADC(w)             = r.RelChange.ADC;
    S.RelPower(w)           = r.RelChange.Power;
    S.MaxPitchRate_degps(w) = r.Optimum.MaxRate;                         % command into FAST
    S.MaxPitchRateFAST_degps(w) = r.Optimum.MaxRateFAST;                 % FAST output BldPitch
end
Summary = S;
disp(Summary);
writetable(Summary, fullfile(sumDir, opts.Name + ".csv"));
save(fullfile(sumDir, opts.Name + ".mat"), 'Summary', 'opts');

% Relative changes over the wind speed
figure(500); clf;
set(gcf, 'Name', "IPC fixed gains: " + opts.Name, 'NumberTitle', 'off');
plot(S.WindSpeed_mps, 100*S.RelDEL_RootMycMax, 'o-', 'LineWidth', 1.2); hold on;
plot(S.WindSpeed_mps, 100*S.RelDEL_TwrBsMyt, 's-', 'LineWidth', 1.2);
plot(S.WindSpeed_mps, 100*S.RelPower, 'd-', 'LineWidth', 1.2);
yline(0, 'k'); grid on;
xlabel('Mean wind speed (m/s)');
ylabel('Change to baseline (%)');
legend('Blade root DEL (max. of 3 blades)', 'Tower base DEL', 'Mean power', 'Location', 'best', 'AutoUpdate', 'off');
title(sprintf('IPC K_P = %.4f, K_I = %.4f, %g°/s (tuned at 18 m/s)', opts.Gains(1), opts.Gains(2), opts.RateLimit));
yyaxis right;
plot(S.WindSpeed_mps, 100*S.RelADC, '^--', 'LineWidth', 1);
ylabel('Pitch activity ADC, change (%)');
print(gcf, fullfile(sumDir, opts.Name), '-dpng', '-r150');
end
