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
%     YLabel       y axis label (default PSD Bl1 MOoP, blade 1 root out-of-plane moment)
%     FMax         upper frequency in Hz (default 0.7)
%     TStart       start of the evaluation window in s (default 66)
%     FigDir       output folder (default plotFunktionen/figIPC_RateLimits)
%     FigNames     file names, one per group (default
%                  fig02_PSDroot_breaky_<file suffixes>)
%     mP           figure height relative to the default (default 0.65)
%
%   Example, pitch rate limit comparison before the fade-in:
%       ts = fullfile('..', 'Results_IPC_PI_RateLimitOpt', 'TimeSeries');
%       plotIPC_PSD_Paper(struct('Files', string(fullfile(ts, ...
%           {'TimeSeries_RL04.mat', 'TimeSeries_RL08.mat', 'TimeSeries_RL13.mat'})), ...
%           'Labels', ["IPC 4°/s", "IPC 8°/s", "IPC 13°/s"], 'Groups', {1:3}, ...
%           'FigNames', "fig02_PSDroot_breaky_IPC_old"));

arguments
    opts struct = struct()
end

plotDir = fileparts(mfilename('fullpath'));
addpath(fullfile(plotDir, 'breakyaxis'));
ts = fullfile(fileparts(plotDir), 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'TimeSeries');
isDefault = ~isfield(opts, 'Files');
def.Files        = string(fullfile(ts, {'TimeSeries_RL04.mat', 'TimeSeries_RL08.mat', ...
                                        'TimeSeries_RL13.mat', 'TimeSeries_RL08_IPCTEF.mat'}));
def.Labels       = ["IPC 4°/s", "IPC 8°/s", "IPC 13°/s", "IPC + TEFC 8°/s"];
def.Groups       = {[1 2 3], 4};
def.BaselineRate = 8;
def.Channel      = "RootMyc1";
def.YLabel       = {'PSD Bl1 MOoP,' 'kNm^2/Hz'};
def.FMax         = 0.7;
def.TStart       = 66;
def.FigDir       = fullfile(plotDir, 'figIPC_RateLimits');
def.FigNames     = [];
def.mP           = 0.65;
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
    P = plotIPC_PSD_RateLimits(struct('Files', files(idx), 'RateLimits', rates(idx), ...
        'BaselineRate', rlB, 'Channels', opts.Channel, 'TStart', opts.TStart, 'Plot', false));
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
    nfpos = get(0, 'defaultFigurePosition');
    nf.Position = [nfpos(1:3), nfpos(4)*opts.mP];
    set(nf, 'Name', sprintf('PSD %s: %s', opts.Channel, join(labels(idx), ', ')), 'NumberTitle', 'off');
    plot(f, Y{1}, 'k-', 'LineWidth', lw); hold on;
    for j = 1:nC
        plot(f, Y{j+1}, ls{j}, 'Color', cl{j}, 'LineWidth', lw);
    end
    axis tight; grid on;
    xlabel('Frequency, Hz', 'FontSize', fs);
    ylabel(opts.YLabel, 'FontSize', fs);
    yl = ylim;
    ylim([yl(1), yl(2) + 0.01*(yl(2) - yl(1))]);
    titleStr = sprintf('Baseline %d°/s', rlB);
    for j = 1:nC
        titleStr = [titleStr, '; ', clTitle{j}, char(labels(idx(j)))]; %#ok<AGROW>
    end

    % Split between the highest value below the baseline 1P peak and the peak
    i1P = f >= 0.85*P.f1P & f <= 1.15*P.f1P;
    yLow = 1.15*max([vertcat(Y{2:end}); Y{1}(~i1P)]);
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

    clAll = [{[0 0 0]}, cl];
    if nC == 1
        % Peak values as text arrows (as in the paper)
        for r = 1:2
            for n = 1:2
                addArrow(axPanes, fpk(r,n), pk(r,n), sprintf('%2.2e', pk(r,n)), clAll{r}, fs, r - 1);
            end
        end
    else
        % Several controllers: baseline 1P peak as text arrow, the other
        % peaks marked with circles and their values listed next to 1P and 2P
        addArrow(axPanes, fpk(1,1), pk(1,1), sprintf('%2.2e', pk(1,1)), clAll{1}, fs, 0);
        axLow = axPanes(1);
        ylL = get(axLow, 'YLim');
        for n = 1:2
            rows = (1 + (n == 1)):(nC + 1);                                % 1P: baseline peak is in the high pane
            for i = 1:numel(rows)
                r = rows(i);
                plot(axLow, fpk(r,n), pk(r,n), 'o', 'Color', clAll{r}, 'MarkerSize', 5, 'LineWidth', lw);
                text(axLow, n*P.f1P + 0.03, ylL(2) - (0.19 + 0.11*(i - 1))*diff(ylL), ...
                    sprintf('%2.2e', pk(r,n)), 'Color', clAll{r}, 'FontSize', fs - 2);
            end
            text(axLow, n*P.f1P + 0.03, ylL(2) - 0.08*diff(ylL), ...
                sprintf('%dP peaks:', n), 'Color', [0.3 0.3 0.3], 'FontSize', fs - 2);
        end
    end

    fnFig = fullfile(opts.FigDir, opts.FigNames(g));
    print(nf, fnFig, '-dpng');
    print(nf, fnFig, '-depsc');
end
end

function addArrow(axPanes, x, y, str, c, fs, j)
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
    'String', str, 'Color', c, 'FontSize', fs - 2);
end
