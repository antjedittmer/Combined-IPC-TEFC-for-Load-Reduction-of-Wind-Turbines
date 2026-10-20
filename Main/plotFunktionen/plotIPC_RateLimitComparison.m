function plotIPC_RateLimitComparison(figDir)
%PLOTIPC_RATELIMITCOMPARISON Time series and PSD plots of the optimized PI-IPC
%   plotIPC_RateLimitComparison(figDir) reproduces the IPC figures of thesis
%   section 4.2 with the gains of Results_IPC_PI_RateLimitOpt (best cost
%   per pitch rate limit) from the stored time series (option
%   'SaveTimeSeries' of optimizeIPC_PI_RateLimits):
%   - 4 deg/s:  K_P = 0.7455, K_I = 0.2168 (fminsearch, RL04_refine),
%               Post_processing/IPC_PI_TS_RL04_opt
%   - 8 deg/s:  K_P = 1.0959, K_I = 0.2504 (fmincon, RL08_fmincon),
%               Post_processing/IPC_PI_TS_RL08_x08
%   - 13 deg/s: K_P = 0.9669, K_I = 0.2209 (fmincon, RL13_fmincon_x08),
%               Post_processing/IPC_PI_TS_RL13_opt
%   Baseline (CPC PI, IPC off) with the standard rate limit of 8 deg/s.
%   Wind: optimization wind field 18 m/s, NTM class A (18mps.bts), 660 s,
%   evaluation window from 66 s (as in the optimization).
%
%   Figures (figDir, default plotFunktionen/figIPC_RateLimits):
%   - fig00a_Timeseries1/2/3: baseline (black) vs. IPC (blue; pitch: blue,
%     red, yellow for the three blades) for 4, 8 and 13 deg/s
%   - fig02_PSDroot_ratecomp: PSD of the blade 1 root out-of-plane moment
%     (RootMyc1), baseline (black), IPC 4 (blue), 8 (red), 13 deg/s (yellow)
%   The 1P/2P peak reductions and the standard deviations are printed.
%
%   Start from the Main folder.

if nargin < 1 || isempty(figDir)
    figDir = fullfile(fileparts(mfilename('fullpath')), 'figIPC_RateLimits');
end
if ~isfolder(figDir), mkdir(figDir); end
addpath(fullfile(fileparts(mfilename('fullpath')), 'breakyaxis'));

ppDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'Post_processing');
cases = struct('rl', {4, 8, 13}, ...
    'file', {fullfile(ppDir, 'IPC_PI_TS_RL04_opt', 'TimeSeries_RL04.mat'), ...
             fullfile(ppDir, 'IPC_PI_TS_RL08_x08', 'TimeSeries_RL08.mat'), ...
             fullfile(ppDir, 'IPC_PI_TS_RL13_opt', 'TimeSeries_RL13.mat')}, ...
    'gains', {[0.7455 0.2168], [1.0959 0.2504], [0.9669 0.2209]});
tStart = 66; % s, evaluation window as in the optimization

% Baseline: standard rate limit 8 deg/s
S8 = load(cases(2).file);
base = toTable(S8.TimeSeries.Baseline);
ipc = cell(1, numel(cases));
for k = 1:numel(cases)
    S = load(cases(k).file);
    ipc{k} = toTable(S.TimeSeries.Optimum);
end

%% Time series
for k = 1:numel(cases)
    plotTimeSeries(base, ipc{k}, cases(k), tStart, k, figDir);
end

%% PSD of the blade 1 root out-of-plane moment
plotPSDcomparison(base, ipc, cases, tStart, figDir);

%% Standard deviations (as Table tab:stddev_unified_IPC)
sig = {'NcIMUTAxs', 'GenPwr', 'RotSpeed', 'PitchRate', 'RootMyc1'};
lbl = {'Tower fore-aft acc. (m/s^2)', 'Generated power (kW)', 'Rotor speed (rpm)', ...
    'Blade pitch rate (deg/s)', 'Blade root OoP moment (kNm)'};
fprintf('\nStandard deviation from %g s (ratio to the baseline at 8 deg/s):\n', tStart);
fprintf('%-30s %12s', 'Signal', 'Baseline');
fprintf(' %18s', sprintf('IPC %d deg/s', cases(1).rl), sprintf('IPC %d deg/s', cases(2).rl), sprintf('IPC %d deg/s', cases(3).rl));
fprintf('\n');
for s = 1:numel(sig)
    b = stdSignal(base, sig{s}, tStart);
    fprintf('%-30s %12.3f', lbl{s}, b);
    for k = 1:numel(cases)
        v = stdSignal(ipc{k}, sig{s}, tStart);
        fprintf(' %10.3f (%4.2f)', v, v/b);
    end
    fprintf('\n');
end
end

function T = toTable(TS)
% Time series struct (OutData, OutList) as table
T = array2table(TS.OutData, 'VariableNames', cellstr(TS.OutList(:))');
end

function v = stdSignal(T, name, tStart)
idx = T.Time >= tStart;
if strcmp(name, 'PitchRate')
    dt = mean(diff(T.Time));
    v = std(diff(T.BldPitch1(idx))/dt);
else
    v = std(T.(name)(idx));
end
end

function plotTimeSeries(base, ipc, c, tStart, figNo, figDir)
% Wind, generator torque, pitch, rotor speed, tower fore-aft acceleration,
% generator power and blade root out-of-plane moments
yAx = {'Wind (m/s)', 'GenTq (kNm)', 'Pitch (°)', 'RotSpd (rpm)', 'TwrAcc_{FA} (m/s^2)', ...
    'GenPwr (MW)', 'M_{yb,1} (MNm)'};
ib = base.Time >= tStart;
ii = ipc.Time >= tStart;
tb = base.Time(ib);
ti = ipc.Time(ii);
figure(100 + figNo); clf;
set(gcf, 'Name', sprintf('Baseline vs. IPC, rate limit %d deg/s', c.rl), 'NumberTitle', 'off');
tiledlayout(numel(yAx), 1, 'TileSpacing', 'Compact');
ax = gobjects(numel(yAx), 1);
for k = 1:numel(yAx)
    ax(k) = nexttile; hold on; grid on; box on;
    ylabel(yAx{k});
end
cPitch = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250]; % blue, red, yellow
plot(ax(1), tb, base.Wind1VelX(ib), 'k');
plot(ax(2), tb, base.GenTq(ib), 'k', 'DisplayName', 'Baseline (8°/s)');
plot(ax(2), ti, ipc.GenTq(ii), 'Color', cPitch(1,:), 'DisplayName', sprintf('IPC (%d°/s)', c.rl));
plot(ax(3), tb, base.BldPitch1(ib), 'k', 'LineWidth', 1.2);
for b = 1:3
    plot(ax(3), ti, ipc.(sprintf('BldPitch%d', b))(ii), 'Color', cPitch(b,:));
end
plot(ax(4), tb, base.RotSpeed(ib), 'k');
plot(ax(4), ti, ipc.RotSpeed(ii), 'Color', cPitch(1,:));
plot(ax(5), tb, base.NcIMUTAxs(ib), 'k');
plot(ax(5), ti, ipc.NcIMUTAxs(ii), 'Color', cPitch(1,:));
plot(ax(6), tb, base.GenPwr(ib)/1000, 'k');
plot(ax(6), ti, ipc.GenPwr(ii)/1000, 'Color', cPitch(1,:));
plot(ax(7), tb, base.RootMyc1(ib)/1000, 'k');
plot(ax(7), ti, ipc.RootMyc1(ii)/1000, 'Color', cPitch(1,:));
title(ax(1), sprintf('Baseline (black, 8°/s) vs. IPC PI (K_P = %.4f, K_I = %.4f), pitch rate limit %d°/s', ...
    c.gains(1), c.gains(2), c.rl));
legend(ax(2), 'Location', 'northeast');
linkaxes(ax, 'x'); axis(ax, 'tight');
% Torque: minimum - 10 % to maximum + 10 % (constant above rated)
tq = [base.GenTq(ib); ipc.GenTq(ii)];
ylim(ax(2), [0.9*min(tq), 1.1*max(tq)]);
xlabel(ax(end), 'Time (s)');
posDefault = get(0, 'DefaultFigurePosition');
set(gcf, 'Position', [posDefault(1), posDefault(2) - posDefault(4)*1.2, posDefault(3)*1.4, posDefault(4)*2.3]);
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 10);
fn = fullfile(figDir, sprintf('fig00a_Timeseries%d', figNo));
print(gcf, fn, '-dpng', '-r150');
print(gcf, fn, '-depsc');
end

function plotPSDcomparison(base, ipc, cases, tStart, figDir)
% PSD (Welch, Hann window of 2^14 samples, 50 % overlap) of RootMyc1
fsHz = 1/mean(diff(base.Time));
nWin = 2^14;
[Pb, f] = psdOf(base, tStart, fsHz, nWin);
P = cell(1, numel(ipc));
for k = 1:numel(ipc)
    P{k} = psdOf(ipc{k}, tStart, fsHz, nWin);
end
f1P = mean(base.RotSpeed(base.Time >= tStart))/60; % Hz
fMax = 0.7;
iF = f <= fMax;

% 1P and 2P peaks (maximum within +-15 % of the frequency)
fprintf('\nPSD of RootMyc1 (from %g s), 1P = %.3f Hz:\n', tStart, f1P);
peak = @(Pk, fn) max(Pk(f >= 0.85*fn & f <= 1.15*fn));
pb = [peak(Pb, f1P), peak(Pb, 2*f1P)];
fprintf('  Baseline (8°/s): 1P %.3g, 2P %.3g kNm^2/Hz\n', pb);
for k = 1:numel(ipc)
    pk = [peak(P{k}, f1P), peak(P{k}, 2*f1P)];
    fprintf('  IPC %2d°/s:       1P %.3g (%+.0f %%), 2P %.3g (%+.0f %%)\n', cases(k).rl, ...
        pk(1), 100*(pk(1)/pb(1) - 1), pk(2), 100*(pk(2)/pb(2) - 1));
end

cl = {'k', [0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250]};
figure(200); clf;
nfpos = get(0, 'DefaultFigurePosition');
set(gcf, 'Position', [nfpos(1:3), nfpos(4)*0.9], 'Name', 'PSD blade root out-of-plane moment', 'NumberTitle', 'off');
plot(f(iF), Pb(iF), 'Color', cl{1}, 'LineWidth', 1, 'DisplayName', 'Baseline, 8°/s'); hold on;
for k = 1:numel(ipc)
    plot(f(iF), P{k}(iF), 'Color', cl{k+1}, 'LineWidth', 1, ...
        'DisplayName', sprintf('IPC, %d°/s', cases(k).rl));
end
grid on; axis tight;
xline(f1P, ':', 'HandleVisibility', 'off');
xline(2*f1P, ':', 'HandleVisibility', 'off');
xlabel(sprintf('Frequency (Hz), dotted: 1P = %.3f Hz and 2P', f1P));
ylabel('PSD M_{yb,1} (kNm^2/Hz)');
% Legend as coloured title (the split axis below replaces the axes)
rgb = @(c) ['\color[rgb]{', sprintf('%g,%g,%g', c), '}'];
titleStr = ['\color{black}Baseline 8°/s;  ', rgb(cl{2}), 'IPC 4°/s;  ', rgb(cl{3}), 'IPC 8°/s;  ', ...
    rgb(cl{4}), 'IPC 13°/s'];
% Split y axis between the IPC curves and the baseline 1P peak
yLow = 1.3*max(cellfun(@(p) max(p(f > 0.05 & iF)), P));
yHigh = 0.8*pb(1);
yl = ylim;
ylim([0, 1.02*yl(2)]);
if yHigh > 1.5*yLow
    br = breakyaxis([yLow, yHigh]);
    title(br.highAxes, titleStr, 'FontWeight', 'normal');
else
    title(titleStr, 'FontWeight', 'normal');
end
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 11);
fn = fullfile(figDir, 'fig02_PSDroot_ratecomp');
print(gcf, fn, '-dpng', '-r150');
print(gcf, fn, '-depsc');
end

function [Pxx, f] = psdOf(T, tStart, fsHz, nWin)
x = T.RootMyc1(T.Time >= tStart);
x = x - mean(x);
[Pxx, f] = pwelch(x, hann(nWin), nWin/2, nWin, fsHz);
end
