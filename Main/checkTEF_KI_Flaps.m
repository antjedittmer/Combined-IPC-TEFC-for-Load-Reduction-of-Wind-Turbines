function T = checkTEF_KI_Flaps()
%CHECKTEF_KI_FLAPS Flap activity with and without the TEF integral gain
%   T = checkTEF_KI_Flaps simulates the start point (TEF K_I = 0, TEF K_P
%   of best.RL08_IPC_TEF_KP_fmincon) and the optimum of runTEF_KPKI_FadeIn
%   (best.RL08_TEF_KPKI_fmincon) with 'SaveTimeSeries' (8 deg/s, fade-in,
%   18 m/s seed A) and compares the flap deflection (To Workspace
%   Flap_Angles, after the flap actuator model, +-10 deg, +-20 deg/s) and the
%   pitch activity from 66 s on. Band RMS of the deflection (rotating frame)
%   from the Welch PSD: below 0.1 Hz, 0.5..1.5 x 1P and above 1.5 x 1P.
%
%   Time series: Main/Post_processing/IPCfade_RL08_TEF_KPKI_TS_<KI0|KIopt>
%   (git-ignored, skipped when they exist). Table:
%   Results_IPC_PI_RateLimitOpt/FadeIn/RL08_TEF_KPKI_Flaps.csv. Start from
%   the Main folder.

pp = fullfile(pwd, 'Post_processing');
fadeIn = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn');
B = load(fullfile(fadeIn, 'best.mat'), 'best');
ipc = B.best.RL08_IPC_TEF_KP_fmincon(1:2);
names = ["KI0", "KIopt"];
tef = [B.best.RL08_IPC_TEF_KP_fmincon(3), 0; B.best.RL08_TEF_KPKI_fmincon(3:4)];

T = table();
for k = 1:numel(names)
    folder = fullfile(pp, char("IPCfade_RL08_TEF_KPKI_TS_" + names(k)));
    fTS = fullfile(folder, 'TimeSeries_RL08.mat');
    if ~isfile(fTS)
        optimizeIPC_PI_RateLimits(struct('RateLimits', 8, 'Vars', "TEF_KPKI", 'IPCGains', ipc, ...
            'Optimizer', "none", 'x0', tef(k,:), 'SaveTimeSeries', true, 'ResultsFolder', folder));
    end
    S = load(fTS, 'TimeSeries');
    R = load(fullfile(folder, 'Results.mat'), 'Results');
    TS = S.TimeSeries.Optimum;
    % Flap_Angles: time, angle 1..3, rate 1..3, acceleration 1..3, integral |angle| 1..3
    F = TS.FlapAngles;
    i = F(:, 1) >= 66;
    d = F(i, 2:4);                                                         % deg
    dt = mean(diff(F(i, 1)));
    r = diff(d) / dt;                                                      % deg/s
    OL = strtrim(TS.OutList);
    t = TS.OutData(:, OL == "Time");
    iO = t >= 66;
    f1P = mean(TS.OutData(iO, OL == "RotSpeed")) / 60;                     % Hz
    p = TS.OutData(iO, startsWith(OL, "BldPitch"));
    [P, f] = pwelch(d - mean(d), hann(2^13), [], [], 1/dt);
    band = @(a, b) sqrt(mean(sum(P(f >= a & f < b, :), 1) * (f(2) - f(1))));
    T = [T; table(names(k), tef(k,1), tef(k,2), R.Results.Cost, ...
        100*R.Results.RelChange.TwrBsMyt, 100*R.Results.RelChange.ADC, ...
        mean(abs(diff(p)), 'all') / mean(diff(t(iO))), ...
        rms(d, 'all'), prctile(abs(d(:)), 99), max(abs(d), [], 'all'), ...
        mean(abs(r), 'all'), 100*mean(abs(d) >= 9.99, 'all'), 100*mean(abs(r) >= 19.9, 'all'), ...
        band(0, 0.1), band(0.5*f1P, 1.5*f1P), band(1.5*f1P, Inf), ...
        'VariableNames', {'Point', 'TEF_K_P', 'TEF_K_I', 'Cost_maxRelDEL_RootMyc', ...
        'RelDEL_TwrBsMyt_pct', 'RelADC_pct', 'PitchADC_degps', 'FlapRMS_deg', 'FlapP99_deg', ...
        'FlapMax_deg', 'FlapADC_degps', 'FlapSat_pct', 'FlapRateSat_pct', ...
        'FlapRMS_below0p1Hz_deg', 'FlapRMS_1P_deg', 'FlapRMS_above1P_deg'})]; %#ok<AGROW>
end
disp(T);
writetable(T, fullfile(fadeIn, 'RL08_TEF_KPKI_Flaps.csv'));
end
