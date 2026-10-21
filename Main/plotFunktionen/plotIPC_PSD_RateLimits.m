function P = plotIPC_PSD_RateLimits(opts)
%PLOTIPC_PSD_RATELIMITS PSD comparison of the PI-IPC at 4, 8 and 13 deg/s
%   P = plotIPC_PSD_RateLimits plots the power spectral densities of the
%   baseline (CPC PI, IPC off) and of the optimized PI-IPC at the pitch rate
%   limits 4, 8 and 13 deg/s for several load channels (one tile per
%   channel) and prints the 1P, 2P and 3P peaks and the standard deviations
%   relative to the baseline. P contains the frequencies and the PSDs.
%
%   The inputs are the time series stored by optimizeIPC_PI_RateLimits with
%   'SaveTimeSeries', true (TimeSeries_RLxx.mat with the fields Baseline and
%   Optimum). Each file contains its own baseline at the same rate limit;
%   the baseline of the file selected by opts.BaselineRate is plotted.
%
%   P = plotIPC_PSD_RateLimits(opts) with the optional fields
%     Files        TimeSeries_RLxx.mat files, one per rate limit (default:
%                  Results_IPC_PI_RateLimitOpt/TimeSeries/TimeSeries_RL04,
%                  _RL08, _RL13.mat, i.e. the gains before the IPC/TEF
%                  fade-in, as in plotIPC_RateLimitComparison; copies of
%                  Post_processing/IPC_PI_TS_RL04_opt, IPC_PI_TS_RL08_x08
%                  and IPC_PI_TS_RL13_opt reduced to 25 channels)
%     RateLimits   rate limits of the files in deg/s (default: from the
%                  file names TimeSeries_RLxx*.mat)
%     Labels       legend and table labels of the IPC runs (default
%                  "IPC, <rate limit>°/s")
%     Channels     FAST channels (default RootMyc1, TwrBsMyt, TwrBsMxt,
%                  YawBrMyp, NcIMUTAxs, BldPitch1)
%     BaselineRate rate limit of the plotted baseline (default 8)
%     TStart       start of the evaluation window in s (default 66)
%     FMax         upper frequency of the plots in Hz (default 0.7)
%     NWin         Welch window length in samples (default 2^14, Hann,
%                  50 % overlap)
%     LogScale     logarithmic PSD axis (default true)
%     FigDir       output folder (default plotFunktionen/figIPC_RateLimits)
%     FigName      file name of the figure (default fig03_PSD_ratecomp)
%     Plot         false: only compute P, no table and no figure (default
%                  true; used by plotIPC_PSD_Paper)
%
%   Example with the fmincon gains of the fade-in optimization (time series
%   in Results_IPC_PI_RateLimitOpt/FadeIn/TimeSeries, created with
%   storeIPC_FadeInTimeSeries), from the Main folder:
%       ts = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'TimeSeries');
%       plotIPC_PSD_RateLimits(struct('Files', ...
%           string(fullfile(ts, {'TimeSeries_RL04.mat', 'TimeSeries_RL08.mat', ...
%                                'TimeSeries_RL13.mat', 'TimeSeries_RL08_IPCTEF.mat'})), ...
%           'Labels', ["IPC, 4°/s", "IPC, 8°/s", "IPC, 13°/s", "IPC + TEF, 8°/s"], ...
%           'FigName', 'fig03_PSD_ratecomp_fadeIn'));

arguments
    opts struct = struct()
end

plotDir = fileparts(mfilename('fullpath'));
tsDir = fullfile(fileparts(plotDir), 'Results_IPC_PI_RateLimitOpt', 'TimeSeries');
def.Files = string(fullfile(tsDir, {'TimeSeries_RL04.mat', 'TimeSeries_RL08.mat', 'TimeSeries_RL13.mat'}));
def.RateLimits   = [];
def.Labels       = [];
def.Channels     = ["RootMyc1", "TwrBsMyt", "TwrBsMxt", "YawBrMyp", "NcIMUTAxs", "BldPitch1"];
def.BaselineRate = 8;
def.TStart       = 66;
def.FMax         = 0.7;
def.NWin         = 2^14;
def.LogScale     = true;
def.FigDir       = fullfile(plotDir, 'figIPC_RateLimits');
def.FigName      = 'fig03_PSD_ratecomp';
def.Plot         = true;
fn = fieldnames(def);
for k = 1:numel(fn)
    if ~isfield(opts, fn{k}), opts.(fn{k}) = def.(fn{k}); end
end
files = string(opts.Files);
channels = string(opts.Channels);
nRuns = numel(files);
if isempty(opts.RateLimits)
    tok = regexp(cellstr(files), 'TimeSeries_RL(\d+)[^\\/]*\.mat$', 'tokens', 'once');
    if any(cellfun(@isempty, tok))
        error('Cannot read the rate limit from the file names; set opts.RateLimits.');
    end
    opts.RateLimits = cellfun(@(t) str2double(t{1}), tok);
end
if numel(opts.RateLimits) ~= nRuns
    error('opts.RateLimits must have one entry per file.');
end
if isempty(opts.Labels)
    opts.Labels = "IPC, " + opts.RateLimits + "°/s";
end
labels = string(opts.Labels);
if numel(labels) ~= nRuns
    error('opts.Labels must have one entry per file.');
end
if ~isfolder(opts.FigDir), mkdir(opts.FigDir); end

%% Load the time series
ipc = cell(1, nRuns);
bases = cell(1, nRuns);
for k = 1:nRuns
    if ~isfile(files(k))
        error('Time series %s not found (see help plotIPC_PSD_RateLimits).', files(k));
    end
    S = load(files(k), 'TimeSeries');
    bases{k} = toTable(S.TimeSeries.Baseline);
    ipc{k} = toTable(S.TimeSeries.Optimum);
end
kBase = find(opts.RateLimits == opts.BaselineRate, 1);
if isempty(kBase)
    kBase = 1;
    warning('No file with %g deg/s; the baseline of %g deg/s is plotted.', ...
        opts.BaselineRate, opts.RateLimits(1));
end
base = bases{kBase};
rlBase = opts.RateLimits(kBase);

%% PSDs
f1P = mean(base.RotSpeed(base.Time >= opts.TStart))/60;                    % Hz
P = struct('Channels', channels, 'RateLimits', opts.RateLimits, 'f1P', f1P);
for c = 1:numel(channels)
    [P.Baseline.(channels(c)), P.f] = psdOf(base, channels(c), opts);
    for k = 1:nRuns
        P.IPC{k}.(channels(c)) = psdOf(ipc{k}, channels(c), opts);
    end
end
f = P.f;
iF = f <= opts.FMax;
if ~opts.Plot, return; end

%% Peaks at 1P, 2P, 3P (maximum within +-15 %) and standard deviations
peak = @(Pk, fn) max(Pk(f >= 0.85*fn & f <= 1.15*fn));
fprintf('\nPSD comparison from %g s, 1P = %.3f Hz; baseline %g deg/s; changes relative to the baseline\n', ...
    opts.TStart, f1P, rlBase);
fprintf('%-10s %-10s', 'Channel', '');
fprintf(' %18s', labels);
fprintf('\n');
for c = 1:numel(channels)
    ch = channels(c);
    for n = 1:3
        pb = peak(P.Baseline.(ch), n*f1P);
        fprintf('%-10s %-10s', ch, sprintf('%dP peak', n));
        for k = 1:nRuns
            fprintf(' %+17.0f%%', 100*(peak(P.IPC{k}.(ch), n*f1P)/pb - 1));
        end
        fprintf('\n');
    end
    sb = std(base.(ch)(base.Time >= opts.TStart));
    fprintf('%-10s %-10s', ch, 'std');
    for k = 1:nRuns
        fprintf(' %+17.0f%%', 100*(std(ipc{k}.(ch)(ipc{k}.Time >= opts.TStart))/sb - 1));
    end
    fprintf('\n');
end

%% Plot
cl = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250], ...
      [0.4940 0.1840 0.5560], [0.4660 0.6740 0.1880]};
figure(300); clf;
set(gcf, 'Name', 'PSD comparison of the pitch rate limits', 'NumberTitle', 'off');
nCh = numel(channels);
nCol = 1 + (nCh > 3);
tl = tiledlayout(ceil(nCh/nCol), nCol, 'TileSpacing', 'compact', 'Padding', 'compact');
for c = 1:nCh
    ch = channels(c);
    ax = nexttile; hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
    plot(ax, f(iF), P.Baseline.(ch)(iF), 'k', 'LineWidth', 1.2, ...
        'DisplayName', sprintf('Baseline, %g°/s', rlBase));
    for k = 1:nRuns
        plot(ax, f(iF), P.IPC{k}.(ch)(iF), 'Color', cl{mod(k-1, numel(cl)) + 1}, 'LineWidth', 1, ...
            'DisplayName', labels(k));
    end
    for n = 1:3
        xline(ax, n*f1P, ':', sprintf('%dP', n), 'HandleVisibility', 'off', ...
            'LabelVerticalAlignment', 'bottom');
    end
    if opts.LogScale, set(ax, 'YScale', 'log'); end
    xlim(ax, [0 opts.FMax]);
    ylabel(ax, sprintf('%s (%s)', ch, unitOf(ch)), 'Interpreter', 'none');
    if c == 1, legend(ax, 'Location', 'best'); end
end
xlabel(tl, 'Frequency (Hz)');
title(tl, sprintf('PSD from %g s, 1P = %.3f Hz', opts.TStart, f1P));
posDefault = get(0, 'DefaultFigurePosition');
set(gcf, 'Position', [posDefault(1), posDefault(2) - posDefault(4)*0.6, ...
    posDefault(3)*(0.9 + 0.6*nCol), posDefault(4)*(0.6 + 0.45*ceil(nCh/nCol))]);
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 10);
fnFig = fullfile(opts.FigDir, opts.FigName);
print(gcf, fnFig, '-dpng', '-r150');
print(gcf, fnFig, '-depsc');
fprintf('Figure saved to %s.png/.eps\n', fnFig);
end

function T = toTable(TS)
% Time series struct (OutData, OutList) as table
T = array2table(TS.OutData, 'VariableNames', cellstr(TS.OutList(:))');
end

function [Pxx, f] = psdOf(T, ch, opts)
% Welch PSD of channel ch from opts.TStart (mean removed)
fsHz = 1/mean(diff(T.Time));
x = T.(ch)(T.Time >= opts.TStart);
x = x - mean(x);
nWin = min(opts.NWin, numel(x));
[Pxx, f] = pwelch(x, hann(nWin), floor(nWin/2), nWin, fsHz);
end

function u = unitOf(ch)
% FAST output units (kN, kNm, deg, kW)
if startsWith(ch, ["Root", "TwrBs", "YawBr"]) && contains(ch, "M")
    u = 'kNm^2/Hz';
elseif startsWith(ch, ["Root", "TwrBs", "YawBr"])
    u = 'kN^2/Hz';
elseif startsWith(ch, "BldPitch")
    u = 'deg^2/Hz';
elseif startsWith(ch, ["NcIMUTA", "NcIMURA"])
    u = '(m/s^2)^2/Hz';
elseif ch == "GenPwr"
    u = 'kW^2/Hz';
elseif ch == "RotSpeed"
    u = 'rpm^2/Hz';
else
    u = '-';
end
end
