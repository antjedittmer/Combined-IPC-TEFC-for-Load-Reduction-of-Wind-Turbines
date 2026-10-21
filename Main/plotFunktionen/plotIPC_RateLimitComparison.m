function plotIPC_RateLimitComparison(figDir, dataSet)
%PLOTIPC_RATELIMITCOMPARISON Time series and PSD plots of the optimized PI-IPC
%   plotIPC_RateLimitComparison(figDir, dataSet) plots the optimized PI-IPC
%   at the pitch rate limits 4, 8 and 13 deg/s from the time series stored
%   in the repository (25 channels, option 'SaveTimeSeries' of
%   optimizeIPC_PI_RateLimits), no simulation needed. dataSet:
%   - "fadeIn" (default): fmincon gains of the re-optimization with the
%     IPC/TEF fade-in, Results_IPC_PI_RateLimitOpt/FadeIn/TimeSeries
%     (created with storeIPC_FadeInTimeSeries):
%     4 deg/s:  K_P = 0.2533, K_I = 0.1033
%     8 deg/s:  K_P = 1.2219, K_I = 0.3702
%     13 deg/s: K_P = 1.2227, K_I = 0.3653
%     The figure names get the suffix _fadeIn.
%   - "beforeFadeIn": fmincon gains before the fade-in (model of commit
%     6cb257c), Results_IPC_PI_RateLimitOpt/TimeSeries (copies of
%     Post_processing/IPC_PI_TS_RL04_fmincon, _RL08_x08, _RL13_opt):
%     4 deg/s:  K_P = 0.7438, K_I = 0.2163 (RL04_fmincon ended infeasible
%               at its start point, the fminsearch result 0.7455/0.2168
%               with tower +0.6 %; this is the best feasible point of its
%               history, tower -1.5 %; TimeSeries_RL04_fmincon.mat)
%     8 deg/s:  K_P = 1.0959, K_I = 0.2504 (fmincon, RL08_fmincon)
%     13 deg/s: K_P = 0.9669, K_I = 0.2209 (fmincon, RL13_fmincon_x08)
%   Baseline (CPC PI, IPC off) with the standard rate limit of 8 deg/s.
%   Wind: optimization wind field 18 m/s, NTM class A (18mps.bts), 660 s,
%   evaluation window from 66 s (as in the optimization).
%
%   Figures (figDir, default plotFunktionen/figIPC_RateLimits):
%   - fig00a_Timeseries1/2/3[_fadeIn]: baseline (black) vs. IPC (blue; pitch: blue,
%     red, yellow for the three blades) for 4, 8 and 13 deg/s
%   - fig02_PSDroot_ratecomp[_fadeIn]: PSD of the blade 1 root out-of-plane moment
%     (RootMyc1), baseline (black), IPC 4 (blue), 8 (red), 13 deg/s (yellow)
%   The 1P/2P peak reductions and the standard deviations are printed.
%
%   No simulation and no Post_processing folder needed.

if nargin < 2 || isempty(dataSet)
    dataSet = "fadeIn";
end
if nargin < 1 || isempty(figDir)
    figDir = fullfile(fileparts(mfilename('fullpath')), 'figIPC_RateLimits');
end
if ~isfolder(figDir), mkdir(figDir); end
addpath(fullfile(fileparts(mfilename('fullpath')), 'breakyaxis'));

resDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'Results_IPC_PI_RateLimitOpt');
switch string(dataSet)
    case "fadeIn"
        tsDir = fullfile(resDir, 'FadeIn', 'TimeSeries');
        tsFiles = {'TimeSeries_RL04.mat', 'TimeSeries_RL08.mat', 'TimeSeries_RL13.mat'};
        B = load(fullfile(resDir, 'FadeIn', 'best.mat'), 'best');
        gains = {B.best.RL04_IPC_fmincon, B.best.RL08_IPC_fmincon, B.best.RL13_IPC_fmincon};
        figSuffix = '_fadeIn';
    case "beforeFadeIn"
        tsDir = fullfile(resDir, 'TimeSeries');
        tsFiles = {'TimeSeries_RL04_fmincon.mat', 'TimeSeries_RL08.mat', 'TimeSeries_RL13.mat'};
        gains = {[0.7438 0.2163], [1.0959 0.2504], [0.9669 0.2209]};
        figSuffix = '';
    otherwise
        error('Unknown dataSet "%s" ("fadeIn" or "beforeFadeIn").', dataSet);
end
cases = struct('rl', {4, 8, 13}, ...
    'file', fullfile(tsDir, tsFiles), ...
    'gains', gains);
fprintf('Data set %s: %s\n', dataSet, tsDir);
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
    plotTimeSeries(base, ipc{k}, cases(k), tStart, k, figDir, figSuffix);
end

%% PSD of the blade 1 root out-of-plane moment
plotPSDcomparison(base, ipc, cases, tStart, figDir, figSuffix);

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

function plotTimeSeries(base, ipc, c, tStart, figNo, figDir, figSuffix)
% Wind, generator torque, pitch, pitch rate, rotor speed, tower fore-aft
% acceleration, generator power and blade root out-of-plane moments
yAx = {'Wind (m/s)', 'GenTq (kNm)', 'Pitch (°)', 'Pitch rate (°/s)', 'RotSpd (rpm)', ...
    'TwrAcc_{FA} (m/s^2)', 'GenPwr (MW)', 'M_{yb,1} (MNm)'};


ib = base.Time >= tStart;
ii = ipc.Time >= tStart;

if std(ipc.GenTq(ii)) < 10 
yAx(2)=[];
end

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
cCPC = [0.4940 0.1840 0.5560];                                             % purple
% CPC (baseline) first, i.e. below the IPC line; in the pitch plot last, on top
idxAx = 1;
plot(ax(idxAx), tb, base.Wind1VelX(ib), 'k');
idxAx = 1+idxAx;

if 10 < std(ipc.GenTq(ii))
plot(ax(idxAx), tb, base.GenTq(ib), 'Color', cCPC);
plot(ax(idxAx), ti, ipc.GenTq(ii), 'Color', cPitch(1,:));
idxAx = 1+idxAx;
end

for b = 1:3
    plot(ax(idxAx), ti, ipc.(sprintf('BldPitch%d', b))(ii), 'Color', cPitch(b,:));
end
plot(ax(idxAx), tb, base.BldPitch1(ib), 'Color', cCPC, 'LineWidth', 1.2);
idxAx = 1+idxAx;

% Pitch rate (finite differences), CPC last as for the pitch; dashed: rate limits 4 and 8 deg/s
for b = 1:3
    plot(ax(idxAx), ti(2:end), diff(ipc.(sprintf('BldPitch%d', b))(ii))./diff(ti), 'Color', cPitch(b,:));
end
plot(ax(idxAx), tb(2:end), diff(base.BldPitch1(ib))./diff(tb), 'Color', cCPC, 'LineWidth', 1.2);
yline(ax(idxAx), [-8 -4 4 8], '--k');
axRate = ax(idxAx);
idxAx = 1+idxAx;

plot(ax(idxAx), tb, base.RotSpeed(ib), 'Color', cCPC);
plot(ax(idxAx), ti, ipc.RotSpeed(ii), 'Color', cPitch(1,:));
idxAx = 1+idxAx;

plot(ax(idxAx), tb, base.NcIMUTAxs(ib), 'Color', cCPC);
plot(ax(idxAx), ti, ipc.NcIMUTAxs(ii), 'Color', cPitch(1,:));
idxAx = 1+idxAx;

plot(ax(idxAx), tb, base.GenPwr(ib)/1000, 'Color', cCPC);
plot(ax(idxAx), ti, ipc.GenPwr(ii)/1000, 'Color', cPitch(1,:));
idxAx = 1+idxAx;

plot(ax(idxAx), tb, base.RootMyc1(ib)/1000, 'Color', cCPC);
plot(ax(idxAx), ti, ipc.RootMyc1(ii)/1000, 'Color', cPitch(1,:));
% Legend as coloured title (no legends in the plots)
rgb = @(cc) ['\color[rgb]{', sprintf('%g,%g,%g', cc), '}'];
title(ax(1), {[rgb(cCPC), 'CPC (8°/s)', '\color{black} vs. ', ...
        sprintf('IPC PI (K_P = %.4f, K_I = %.4f), %d°/s', c.gains(1), c.gains(2), c.rl)], ...
    ['\color{black}Pitch IPC: ', rgb(cPitch(1,:)), 'blade 1, ', rgb(cPitch(2,:)), 'blade 2, ', ...
        rgb(cPitch(3,:)), 'blade 3']}, 'FontWeight', 'bold');
linkaxes(ax, 'x'); axis(ax, 'tight');
% Pitch rate always +-13 deg/s (largest rate limit), ticks at the rate limits
ylim(axRate, [-13 13]);
yticks(axRate, [-13 -8 -4 0 4 8 13]);

if 10 < std(ipc.GenTq(ii)) 
% Torque: minimum - 10 % to maximum + 10 % (constant above rated)
tq = [base.GenTq(ib); ipc.GenTq(ii)];
ylim(ax(2), [0.9*min(tq), 1.1*max(tq)]);
end

xlabel(ax(end), 'Time (s)');
posDefault = get(0, 'DefaultFigurePosition');
set(gcf, 'Position', [posDefault(1), posDefault(2) - posDefault(4)*1.2, posDefault(3), posDefault(4)*2.3]);
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 11);
fn = fullfile(figDir, sprintf('fig00a_Timeseries%d%s', figNo, figSuffix));
print(gcf, fn, '-dpng', '-r150');
print(gcf, fn, '-depsc');
end

function plotPSDcomparison(base, ipc, cases, tStart, figDir, figSuffix)
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
plot(f(iF), Pb(iF), 'Color', cl{1}, 'LineWidth', 1, 'DisplayName', 'Baseline'); hold on;
for k = 1:numel(ipc)
    plot(f(iF), P{k}(iF), 'Color', cl{k+1}, 'LineWidth', 1, ...
        'DisplayName', sprintf('IPC, %d°/s', cases(k).rl));
end
grid on; axis tight;
xline(f1P, ':', 'HandleVisibility', 'off');
xline(2*f1P, ':', 'HandleVisibility', 'off');
xlabel(sprintf('Frequency (Hz), dotted: 1P = %.1f Hz and 2P', f1P));
ylabel('PSD M_{yb,1} (kNm^2/Hz)');
% Legend as coloured title (the split axis below replaces the axes)
rgb = @(c) ['\color[rgb]{', sprintf('%g,%g,%g', c), '}'];
titleStr = ['\color{black}Baseline 8°/s;  ', rgb(cl{2}), 'IPC 4°/s;  ', rgb(cl{3}), 'IPC 8°/s;  ', ...
    rgb(cl{4}), 'IPC 13°/s'];
% Split y axis between the IPC curves and the baseline 1P peak
yLow = 1e7;                                                                % lower pane up to 10^7
yl = ylim;
ylim([0, 1.02*yl(2)]);
% Upper pane with 2/3 of the y range of the lower one, so that the upper
% pane covers about 2/5 and the lower one 3/5 of the plot (below the
% baseline 1P peak, so that it stays visible)
yHigh = min(1.02*yl(2) - 2/3*yLow, 0.98*pb(1));
if yHigh > 1.5*yLow
    [~, br] = evalc('breakyaxis([yLow, yHigh])');                         % breakyaxis prints an axes
    title(br.highAxes, titleStr, 'FontWeight', 'normal');
    axPanes = [br.lowAxes, br.highAxes];
    % Lower pane: ticks up to the split at 10^7, labelled as x10^7
    br.lowAxes.YTick = (0:0.25:1)*yLow;
    br.lowAxes.YAxis.Exponent = round(log10(yLow));
else
    title(titleStr, 'FontWeight', 'normal');
    axPanes = gca;
end
% 1P and 2P peaks: circles in the line colours, values listed in the same
% colours in the upper pane next to the 1P and 2P lines
Pall = [{Pb}, P];
axTxt = axPanes(end);
ylT = get(axTxt, 'YLim');
for n = 1:2
    iN = find(f >= 0.85*n*f1P & f <= 1.15*n*f1P);
    text(axTxt, n*f1P + 0.015, ylT(2) - 0.08*diff(ylT), sprintf('%dP peaks:', n), ...
        'Color', [0.3 0.3 0.3], 'FontSize', 10);
    for r = 1:numel(Pall)
        [pv, i1] = max(Pall{r}(iN));
        axP = axPanes(end);
        for a = axPanes
            yl = get(a, 'YLim');
            if pv >= yl(1) && pv <= yl(2), axP = a; break; end
        end
        plot(axP, f(iN(i1)), pv, 'o', 'Color', cl{r}, 'MarkerSize', 5, 'LineWidth', 1);
        text(axTxt, n*f1P + 0.015, ylT(2) - (0.08 + 0.1*r)*diff(ylT), sprintf('%2.2e', pv), ...
            'Color', cl{r}, 'FontSize', 10);
    end
end
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 11);
fn = fullfile(figDir, ['fig02_PSDroot_ratecomp', figSuffix]);
print(gcf, fn, '-dpng', '-r150');
print(gcf, fn, '-depsc');
end

function [Pxx, f] = psdOf(T, tStart, fsHz, nWin)
x = T.RootMyc1(T.Time >= tStart);
x = x - mean(x);
[Pxx, f] = pwelch(x, hann(nWin), nWin/2, nWin, fsHz);
end
