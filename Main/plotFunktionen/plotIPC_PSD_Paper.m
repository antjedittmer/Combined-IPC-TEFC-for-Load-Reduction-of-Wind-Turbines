function plotIPC_PSD_Paper(opts)
%PLOTIPC_PSD_PAPER PSD of the baseline and the controllers, as in the paper
%   plotIPC_PSD_Paper plots, in the style of plotPaper02_PSD_comparison
%   (fig02_PSDroot_breaky), the PSD of the blade root out-of-plane moment of the
%   baseline and of the controllers of one group per figure: linear axis
%   split with breakyaxis between the controllers and the baseline 1P peak,
%   the legend as coloured title and the 1P and 2P peak values as text
%   arrows. Default: the fmincon gains of the re-optimization with the
%   IPC/TEF fade-in (Results_IPC_PI_RateLimitOpt/FadeIn/TimeSeries), two
%   figures:
%   - fig02_PSDroot_breaky_IPC: IPC at 4, 8 and 13 deg/s
%   - fig02_PSDroot_breaky_RL08_IPCTEF: IPC + TEF at 8 deg/s
%   The baseline is that of the file with the rate limit opts.BaselineRate
%   in the group (each file contains its own baseline), otherwise that of
%   the first file of the group. The PSDs come from plotIPC_PSD_RateLimits
%   (Welch, Hann window of 2^14 samples, from 66 s).
%
%   plotIPC_PSD_Paper(opts) with the optional fields
%     Files        TimeSeries_RLxx*.mat files
%     Labels       names of the controllers (title)
%     Groups       cell array of indices into Files, one figure per group
%                  (default {[1 2 3], 4}); up to 4 controllers per group
%     BaselineRate rate limit of the baseline in deg/s (default 8)
%     Channel      FAST channel (default RootMyc1)
%     YLabel       y axis label (default PSD Bl1 MOoP (kNm^2/Hz), blade 1 root
%                  out-of-plane moment)
%     FMax         upper frequency in Hz (default 0.7)
%     TStart       start of the evaluation window in s (default 66)
%     FigDir       output folder (default plotFunktionen/figIPC_RateLimits)
%     FigNames     file names, one per group (default
%                  fig02_PSDroot_breaky_<file suffixes>)
%     mP           figure height: 10 cm * mP/0.9 (default 0.9, i.e. 10 cm)
%     mW           figure width: 14.8 cm * mW (default 1, i.e. 14.8 cm as
%                  the other thesis figures, so that the fonts of 12 pt
%                  keep their size when the figures are scaled to the
%                  same width)
%     BaselineLabel title of the baseline (default "Baseline <rate>°/s")
%     FontSizeNum  font size of the tick labels and peak values (default 12)
%     YSplit       y values [low, high] of the axis split, one per group
%                  (cell array); [] or missing: automatic, only if the
%                  baseline 1P peak is 1.5 times above the other values
%     PSDFile      precomputed PSDs (e.g. PSD_RL08_AALC.mat of storeAALC_PSD)
%                  instead of Files: the runs are P.Runs, the labels
%                  default to P.Labels, the baseline is P.Baseline (fast,
%                  no time series needed)
%     StyleIdx     colour/line style of each file or run (1 blue, 2 green,
%                  3 red, 4 magenta; default: position within the group)
%
%   Example, pitch rate limit comparison before the fade-in:
%       ts = fullfile('..', 'Results_IPC_PI_RateLimitOpt', 'TimeSeries');
%       plotIPC_PSD_Paper(struct('Files', string(fullfile(ts, ...
%           {'TimeSeries_RL04.mat', 'TimeSeries_RL08.mat', 'TimeSeries_RL13.mat'})), ...
%           'Labels', ["IPC 4°/s", "IPC 8°/s", "IPC 13°/s"], 'Groups', {1:3}, ...
%           'FigNames', "fig02_PSDroot_breaky_IPC_old"));
%   Example with precomputed PSDs (see plotAALC_PSD_comparison):
%       plotIPC_PSD_Paper(struct('PSDFile', fullfile(ts, 'PSD_RL08_AALC.mat'), ...
%           'Groups', {{[1 2], [3 5]}}, 'StyleIdx', [1 2 3 1 4]));

arguments
    opts struct = struct()
end

plotDir = fileparts(mfilename('fullpath'));
addpath(fullfile(plotDir, 'breakyaxis'));
ts = fullfile(fileparts(plotDir), 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'TimeSeries');
isDefault = ~isfield(opts, 'Files') && ~isfield(opts, 'PSDFile');
def.Files        = string(fullfile(ts, {'TimeSeries_RL04.mat', 'TimeSeries_RL08.mat', ...
                                        'TimeSeries_RL13.mat', 'TimeSeries_RL08_IPCTEF.mat'}));
def.Labels       = ["IPC 4°/s", "IPC 8°/s", "IPC 13°/s", "IPC + TEFC 8°/s"];
def.Groups       = {[1 2 3], 4};
def.BaselineRate = 8;
def.Channel      = "RootMyc1";
def.YLabel       = 'PSD Bl1 MOoP (kNm^2/Hz)';
def.FMax         = 0.7;
def.TStart       = 66;
def.FigDir       = fullfile(plotDir, 'figIPC_RateLimits');
def.FigNames     = [];
def.mP           = 0.9;
def.mW           = 1;
def.BaselineLabel = "";
def.FontSizeNum  = 12;
def.YSplit       = {};
def.PSDFile      = "";
def.StyleIdx     = [];
Q = [];
if isfield(opts, 'PSDFile') && opts.PSDFile ~= ""
    S = load(opts.PSDFile, 'P');
    Q = S.P;
    opts.Files = Q.Files;
    if ~isfield(opts, 'Labels'), opts.Labels = Q.Labels; end
    def.TStart = Q.TStart;
end
if ~isDefault && ~isfield(opts, 'Groups')
    def.Groups = num2cell(1:numel(opts.Files));                            % one figure per file
end
fn = fieldnames(def);
for k = 1:numel(fn)
    if ~isfield(opts, fn{k}), opts.(fn{k}) = def.(fn{k}); end
end
files = string(opts.Files);
labels = string(opts.Labels);
groups = opts.Groups;
if numel(labels) ~= numel(files)
    error('opts.Labels must have one entry per file.');
end
if any(cellfun(@numel, groups) > 4)
    error('At most 4 controllers per group.');
end
[~, names] = fileparts(files);
suffix = erase(names, "TimeSeries_");
tok = regexp(cellstr(files), 'TimeSeries_RL(\d+)', 'tokens', 'once');
rates = cellfun(@(t) str2double(t{1}), tok);
if isempty(opts.FigNames)
    if isDefault
        opts.FigNames = ["fig02_PSDroot_breaky_IPC", "fig02_PSDroot_breaky_RL08_IPCTEF"];
    else
        opts.FigNames = cellfun(@(g) "fig02_PSDroot_breaky_" + join(suffix(g), "_"), groups);
    end
end
if numel(opts.FigNames) ~= numel(groups)
    error('opts.FigNames must have one entry per group.');
end
if ~isfolder(opts.FigDir), mkdir(opts.FigDir); end

fs = 12;                                                                   % as plotPaper02_PSD_comparison
lw = 0.8;
cl = {[0 0 1], [0 0.5 0], [1 0 0], [1 0 1]};                               % blue, green, red, magenta
ls = {'-', '-.', '--', '-.'};
clTitle = {'\color{blue}', '\color[rgb]{0,0.5,0}', '\color{red}', '\color{magenta}'};
for g = 1:numel(groups)
    idx = groups{g};
    kB = find(rates(idx) == opts.BaselineRate, 1);
    if isempty(kB), kB = 1; end
    rlB = rates(idx(kB));
    if isempty(Q)
        P = plotIPC_PSD_RateLimits(struct('Files', files(idx), 'RateLimits', rates(idx), ...
            'BaselineRate', rlB, 'Channels', opts.Channel, 'TStart', opts.TStart, 'Plot', false));
    else
        P = struct('f', Q.f, 'f1P', Q.f1P, 'Baseline', Q.Baseline, 'IPC', {Q.Runs(idx)});
    end
    if isempty(opts.StyleIdx)
        st = 1:numel(idx);
    else
        st = opts.StyleIdx(idx);
    end
    iF = P.f <= opts.FMax;
    f = P.f(iF);
    Y = [{P.Baseline.(opts.Channel)(iF)}, cellfun(@(c) c.(opts.Channel)(iF), P.IPC, 'UniformOutput', false)];
    nC = numel(idx);

    % 1P and 2P peaks (maximum within +-15 %), rows: baseline, controllers
    pk = zeros(nC + 1, 2); fpk = zeros(nC + 1, 2);
    for n = 1:2
        iN = find(f >= 0.85*n*P.f1P & f <= 1.15*n*P.f1P);
        for r = 1:nC + 1
            [pk(r,n), i1] = max(Y{r}(iN));
            fpk(r,n) = f(iN(i1));
        end
    end
    for j = 1:nC
        fprintf('%s vs. baseline %d°/s: 1P %.2e -> %.2e (%+.0f %%), 2P %.2e -> %.2e (%+.0f %%)\n', ...
            labels(idx(j)), rlB, pk(1,1), pk(j+1,1), 100*(pk(j+1,1)/pk(1,1) - 1), ...
            pk(1,2), pk(j+1,2), 100*(pk(j+1,2)/pk(1,2) - 1));
    end

    % Figure as fig02_PSDroot_breaky
    nf = figure(400 + g); clf;
    % Window with the size of the printed figure (96 px per inch), so that
    % the layout (fitted axes, peak labels in pixels) is the printed one
    nfpos = get(0, 'defaultFigurePosition');
    sizeCm = [14.8*opts.mW, 10*opts.mP/0.9];
    nf.Units = 'pixels';
    nf.Position = [nfpos(1:2), round(sizeCm*96/2.54)];
    set(nf, 'Name', sprintf('PSD %s: %s', opts.Channel, join(labels(idx), ', ')), 'NumberTitle', 'off');
    plot(f, Y{1}, 'k-', 'LineWidth', lw); hold on;
    for j = 1:nC
        plot(f, Y{j+1}, ls{st(j)}, 'Color', cl{st(j)}, 'LineWidth', lw);
    end
    axis tight; grid on;
    xlabel('Frequency (Hz)', 'FontSize', fs);
    ylabel(opts.YLabel, 'FontSize', fs);
    yl = ylim;
    ylim([yl(1), yl(2) + 0.01*(yl(2) - yl(1))]);
    titleStr = sprintf('Baseline %d°/s', rlB);
    if opts.BaselineLabel ~= "", titleStr = char(opts.BaselineLabel); end
    for j = 1:nC
        titleStr = [titleStr, '; ', clTitle{st(j)}, char(labels(idx(j)))]; %#ok<AGROW>
    end

    % Split between the highest value below the baseline 1P peak and the peak
    i1P = f >= 0.85*P.f1P & f <= 1.15*P.f1P;
    yLow = 1.15*max([vertcat(Y{2:end}); Y{1}(~i1P)]);
    yHigh = 0.85*pk(1,1);
    fsN = opts.FontSizeNum;
    doSplit = yHigh > 1.5*yLow;
    if numel(opts.YSplit) >= g && ~isempty(opts.YSplit{g})
        yLow = opts.YSplit{g}(1); yHigh = opts.YSplit{g}(2);
        doSplit = true;
    end
    % Title and font sizes before the split: breakyaxis copies the axes (the
    % title and the labels stay on its annotation axes), and the axes are
    % fitted to the figure with these font sizes (lower axis moved up, so
    % that the labels are not cut off)
    set(gca, 'FontSize', fsN);
    if ~isappdata(groot, 'ShowThesisTitle') || getappdata(groot, 'ShowThesisTitle') % title switch of runGenerateAllThesisFigures
        title(titleStr, 'FontSize', fs);
    end
    set([get(gca, 'XLabel'), get(gca, 'YLabel')], 'FontSize', fs);
    fitAxes(gca, 0.02);
    % Axes to the right and the y label as far left as before, so that the
    % label does not touch the tick labels of the split panes (other ticks
    % than those of the full axis)
    pos = get(gca, 'Position');
    dxL = 0.03;
    set(gca, 'Position', [pos(1) + dxL, pos(2), pos(3) - dxL, pos(4)]);
    hYl = get(gca, 'YLabel');
    set(hYl, 'Units', 'normalized');
    set(hYl, 'Position', [hYl.Position(1) - dxL/(pos(3) - dxL), 0.5, 0]);
    if doSplit
        [~, br] = evalc('breakyaxis([yLow, yHigh])');                     % breakyaxis prints an axes
        if numel(opts.YSplit) >= g && ~isempty(opts.YSplit{g})
            set([br.lowAxes, br.highAxes], 'YTickMode', 'auto');           % ticks of the given split
            t = get(br.highAxes, 'YTick');
            dt = diff(t(1:2));
            if nnz(t > yHigh) < 2, dt = dt/2; end                          % at least two ticks above the split
            ylH = get(br.highAxes, 'YLim');
            set(br.highAxes, 'YTick', (floor(yHigh/dt) + 1)*dt:dt:ylH(2));  % none on the split line
        end
        axPanes = [br.lowAxes, br.highAxes];
    else
        axPanes = gca;
    end

    clAll = [{[0 0 0]}, cl(st)];
    if nC == 1
        % Peak values as text arrows (as in the paper)
        for r = 1:2
            for n = 1:2
                addArrow(axPanes, fpk(r,n), pk(r,n), sprintf('%2.2e', pk(r,n)), clAll{r}, fsN, r - 1);
            end
        end
    else
        % Several controllers: baseline 1P peak as text arrow, the other
        % peaks as filled circles with their values fanned out close to the
        % peaks, with 45 degree arrows (peakLabels; largest peak first);
        % headings '1P peaks:' and '2P peaks:' at the top of the lower pane
        addArrow(axPanes, fpk(1,1), pk(1,1), sprintf('%2.2e', pk(1,1)), clAll{1}, fsN, 0);
        axLow = axPanes(1);
        ylL = get(axLow, 'YLim');
        dyL = 0.22*isscalar(axPanes);                                      % no split: below the baseline arrow
        xk = []; yk = []; ck = {};
        for n = 1:2
            rows = (1 + (n == 1)):(nC + 1);                                % 1P: baseline peak is in the high pane
            [~, iS] = sort(pk(rows, n), 'descend');                        % largest peak on top
            rows = rows(iS);
            xk = [xk; fpk(rows,n)]; yk = [yk; pk(rows,n)]; ck = [ck, clAll(rows)]; %#ok<AGROW>
            text(axLow, n*P.f1P + 0.03, ylL(2) - (dyL + 0.08)*diff(ylL), ...
                sprintf('%dP peaks:', n), 'Color', [0.3 0.3 0.3], 'FontSize', fsN);
        end
        peakLabels(axLow, xk, yk, compose('%2.2e', yk), ck, fsN);          % 1P and 2P together
    end

    fnFig = fullfile(opts.FigDir, opts.FigNames(g));
    % Fixed size in cm (independent of the screen), as printFig in
    % plotIPC_RateLimitComparison
    set(nf, 'PaperUnits', 'centimeters', 'PaperPositionMode', 'manual', ...
        'PaperSize', sizeCm, 'PaperPosition', [0 0 sizeCm]);
    print(nf, fnFig, '-dpng', '-r300');
    print(nf, fnFig, '-depsc', '-painters', '-loose');
end
end

function fitAxes(ax, pad)
% Inner axes position so that the tick labels, the axis labels and the
% title (TightInset) just fit into the figure, with the margin pad
% (normalized); fixed afterwards (breakyaxis copies this position)
drawnow;
set(ax, 'Units', 'normalized');
ti = get(ax, 'TightInset');
set(ax, 'Position', [ti(1) + pad, ti(2) + pad, 1 - ti(1) - ti(3) - 2*pad, 1 - ti(2) - ti(4) - 2*pad]);
end

function addArrow(axPanes, x, y, str, c, fsN, j)
% Text arrow to the data point (x, y) in the pane that contains y; j = 0
% baseline, j = 1, 2, ... controllers (text further up and right)
ax = axPanes(end);
for a = axPanes
    yl = get(a, 'YLim');
    if y >= yl(1) && y <= yl(2), ax = a; break; end
end
pos = get(ax, 'Position');
xl = get(ax, 'XLim'); yl = get(ax, 'YLim');
xn = pos(1) + (x - xl(1))/diff(xl)*pos(3);
yn = pos(2) + (y - yl(1))/diff(yl)*pos(4);
dx = 0.05 + 0.03*j;
dy = 0.07 + 0.09*j;
if yn + dy > 0.88, dy = -0.07; dx = 0.06; end                            % below the peak
annotation(get(ax, 'Parent'), 'textarrow', [xn + dx, xn], [yn + dy, yn], ...
    'String', str, 'Color', c, 'FontSize', fsN);
end
