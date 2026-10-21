function plotIPC_PSD_Paper(opts)
%PLOTIPC_PSD_PAPER PSD of baseline vs. one controller, as in the paper
%   plotIPC_PSD_Paper plots, in the style of plotPaper02_PSD_comparison
%   (fig02_PSDroot_breaky), the PSD of the blade root flapwise moment of the
%   baseline and of one controller per figure: linear axis split with
%   breakyaxis between the controller and the baseline 1P peak, the legend
%   as coloured title and the 1P and 2P peak values as text arrows.
%   Default: the fmincon gains of the re-optimization with the IPC/TEF
%   fade-in (Results_IPC_PI_RateLimitOpt/FadeIn/TimeSeries), four figures:
%   IPC at 4, 8 and 13 deg/s and IPC + TEF at 8 deg/s. Each controller is
%   compared with the baseline of its own file (same rate limit). The PSDs
%   come from plotIPC_PSD_RateLimits (Welch, Hann window of 2^14 samples,
%   from 66 s).
%
%   plotIPC_PSD_Paper(opts) with the optional fields
%     Files     TimeSeries_RLxx*.mat files, one figure per file
%     Labels    names of the controllers (title)
%     Channel   FAST channel (default RootMyc1)
%     YLabel    y axis label (default blade root flapwise moment)
%     FMax      upper frequency in Hz (default 0.7)
%     TStart    start of the evaluation window in s (default 66)
%     FigDir    output folder (default plotFunktionen/figIPC_RateLimits)
%     FigNames  file names (default fig02_PSDroot_breaky_<file suffix>)
%     mP        figure height relative to the default (default 0.65)
%
%   Example, pitch rate limit comparison before the fade-in:
%       ts = fullfile('..', 'Results_IPC_PI_RateLimitOpt', 'TimeSeries');
%       plotIPC_PSD_Paper(struct('Files', string(fullfile(ts, ...
%           {'TimeSeries_RL04.mat', 'TimeSeries_RL08.mat', 'TimeSeries_RL13.mat'})), ...
%           'Labels', ["IPC 4°/s", "IPC 8°/s", "IPC 13°/s"], ...
%           'FigNames', ["fig02_PSDroot_breaky_old_RL04", "fig02_PSDroot_breaky_old_RL08", ...
%                        "fig02_PSDroot_breaky_old_RL13"]));

arguments
    opts struct = struct()
end

plotDir = fileparts(mfilename('fullpath'));
addpath(fullfile(plotDir, 'breakyaxis'));
ts = fullfile(fileparts(plotDir), 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'TimeSeries');
def.Files    = string(fullfile(ts, {'TimeSeries_RL04.mat', 'TimeSeries_RL08.mat', ...
                                    'TimeSeries_RL13.mat', 'TimeSeries_RL08_IPCTEF.mat'}));
def.Labels   = ["IPC 4°/s", "IPC 8°/s", "IPC 13°/s", "IPC + TEFC 8°/s"];
def.Channel  = "RootMyc1";
def.YLabel   = {'PSD Blade root flapwise moment,' 'kNm^2/Hz'};
def.FMax     = 0.7;
def.TStart   = 66;
def.FigDir   = fullfile(plotDir, 'figIPC_RateLimits');
def.FigNames = [];
def.mP       = 0.65;
fn = fieldnames(def);
for k = 1:numel(fn)
    if ~isfield(opts, fn{k}), opts.(fn{k}) = def.(fn{k}); end
end
files = string(opts.Files);
labels = string(opts.Labels);
if numel(labels) ~= numel(files)
    error('opts.Labels must have one entry per file.');
end
if isempty(opts.FigNames)
    [~, names] = fileparts(files);
    opts.FigNames = "fig02_PSDroot_breaky_" + erase(names, "TimeSeries_");
end
if ~isfolder(opts.FigDir), mkdir(opts.FigDir); end

fs = 12;                                                                   % as plotPaper02_PSD_comparison
lw = 0.8;
cComp = [0 0 1];                                                           % blue
for k = 1:numel(files)
    % PSD of the baseline and the controller of this file
    tok = regexp(files(k), 'TimeSeries_RL(\d+)', 'tokens', 'once');
    rl = str2double(tok(1));
    P = plotIPC_PSD_RateLimits(struct('Files', files(k), 'RateLimits', rl, 'BaselineRate', rl, ...
        'Channels', opts.Channel, 'TStart', opts.TStart, 'Plot', false));
    f = P.f;
    iF = f <= opts.FMax;
    f = f(iF);
    yB = P.Baseline.(opts.Channel)(iF);
    yC = P.IPC{1}.(opts.Channel)(iF);

    % 1P and 2P peaks (maximum within +-15 %)
    pk = zeros(2, 2); fpk = zeros(2, 2);                                   % rows: baseline, controller
    for n = 1:2
        iN = find(f >= 0.85*n*P.f1P & f <= 1.15*n*P.f1P);
        [pk(1,n), i1] = max(yB(iN)); fpk(1,n) = f(iN(i1));
        [pk(2,n), i2] = max(yC(iN)); fpk(2,n) = f(iN(i2));
    end
    fprintf('%s: 1P %.2e -> %.2e (%+.0f %%), 2P %.2e -> %.2e (%+.0f %%)\n', labels(k), ...
        pk(1,1), pk(2,1), 100*(pk(2,1)/pk(1,1) - 1), pk(1,2), pk(2,2), 100*(pk(2,2)/pk(1,2) - 1));

    % Figure as fig02_PSDroot_breaky
    nf = figure(400 + k); clf;
    nfpos = get(0, 'defaultFigurePosition');
    nf.Position = [nfpos(1:3), nfpos(4)*opts.mP];
    set(nf, 'Name', sprintf('PSD %s: baseline vs. %s', opts.Channel, labels(k)), 'NumberTitle', 'off');
    plot(f, yB, 'k-', 'LineWidth', lw); hold on;
    plot(f, yC, '-', 'Color', cComp, 'LineWidth', lw);
    axis tight; grid on;
    xlabel('Frequency, Hz', 'FontSize', fs);
    ylabel(opts.YLabel, 'FontSize', fs);
    yl = ylim;
    ylim([yl(1), yl(2) + 0.01*(yl(2) - yl(1))]);
    titleStr = sprintf('Baseline %d°/s; \\color{blue}%s', rl, labels(k));

    % Split between the highest value below the baseline 1P peak and the peak
    i1P = f >= 0.85*P.f1P & f <= 1.15*P.f1P;
    yLow = 1.15*max([yC; yB(~i1P)]);
    yHigh = 0.85*pk(1,1);
    if yHigh > 1.5*yLow
        [~, br] = evalc('breakyaxis([yLow, yHigh])');                     % breakyaxis prints an axes
        br.highAxes.Title.String = titleStr;
        br.highAxes.Title.FontSize = fs;
        br.highAxes.FontSize = fs - 2;
        br.lowAxes.FontSize = fs - 2;
        axPanes = [br.lowAxes, br.highAxes];
    else
        title(titleStr, 'FontSize', fs);
        axPanes = gca;
    end

    % Peak values as text arrows (baseline black, controller blue)
    cl = {[0 0 0], cComp};
    for r = 1:2
        for n = 1:2
            addArrow(axPanes, fpk(r,n), pk(r,n), sprintf('%2.2e', pk(r,n)), cl{r}, fs, r == 1);
        end
    end

    fnFig = fullfile(opts.FigDir, opts.FigNames(k));
    print(nf, fnFig, '-dpng');
    print(nf, fnFig, '-depsc');
end
end

function addArrow(axPanes, x, y, str, c, fs, isBaseline)
% Text arrow to the data point (x, y) in the pane that contains y
ax = axPanes(end);
for a = axPanes
    yl = get(a, 'YLim');
    if y >= yl(1) && y <= yl(2), ax = a; break; end
end
pos = get(ax, 'Position');
xl = get(ax, 'XLim'); yl = get(ax, 'YLim');
xn = pos(1) + (x - xl(1))/diff(xl)*pos(3);
yn = pos(2) + (y - yl(1))/diff(yl)*pos(4);
% Text up right of the peak, the controller further up than the baseline
% (2P peaks are close); below the peak if it would leave the axes
dx = 0.05 + 0.02*~isBaseline;
dy = 0.07 + 0.11*~isBaseline;
if yn + dy > 0.88, dy = -0.07; dx = 0.06; end
annotation(get(ax, 'Parent'), 'textarrow', [xn + dx, xn], [yn + dy, yn], ...
    'String', str, 'Color', c, 'FontSize', fs - 2);
end
