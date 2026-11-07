function peakLabels(ax, xP, yP, str, cl, fs, L)
%PEAKLABELS Peak values as texts with 45 degree arrows to the peaks
%   peakLabels(ax, xP, yP, str, cl, fs) marks the peaks (xP(k), yP(k)) in
%   the axes ax with filled circles and writes str{k} in the colour cl{k}
%   (font size fs) up and to the right of each peak, with an arrow at 45
%   degrees (on the page) from the text to the peak.
%   Peaks at (almost) the same point form a cluster: the first text of the
%   cluster gets the 45 degree arrow, high enough above the peak that the
%   following texts can be placed one line lower and further to the right
%   each (fanned out, in the given order), all above the peak. Texts and
%   arrows do not overlap other texts (the cluster moves further up along
%   the 45 degree line, if needed also to the right; the clusters are
%   placed in the order with the fewest clashes).
%   peakLabels(..., L) sets the minimum arrow length in cm (default 1.2).
%   Call it after the axes position and limits are final.

if nargin < 7 || isempty(L), L = 1.2; end
fig = ancestor(ax, 'figure');
pxPerCm = get(groot, 'ScreenPixelsPerInch')/2.54;
d0 = L*pxPerCm/sqrt(2);                                                    % x and y offset of the text (px)
gap = 2;                                                                   % px between the arrow tail and the text
axPx = getpixelposition(ax, true);                                         % in the figure
figPx = getpixelposition(fig);
xl = get(ax, 'XLim'); yl = get(ax, 'YLim');
toPx = @(x, y) [(x - xl(1))/diff(xl)*axPx(3), (y - yl(1))/diff(yl)*axPx(4)]; % axes pixels
toN = @(q) (axPx(1:2) + q)./figPx(3:4);                                    % normalized figure units
n = numel(xP);
p = zeros(n, 2);
h = gobjects(n, 1);
ext = zeros(n, 4);
for k = 1:n
    plot(ax, xP(k), yP(k), 'o', 'Color', cl{k}, 'MarkerFaceColor', cl{k}, 'MarkerSize', 5);
    p(k,:) = toPx(xP(k), yP(k));
    h(k) = text(ax, 0, 0, str{k}, 'Color', cl{k}, 'FontSize', fs, 'Units', 'pixels', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Clipping', 'off');
    ext(k,:) = get(h(k), 'Extent');
end
wT = max(ext(:,3)); hT = max(ext(:,4));
step = [0.35*wT, -hT];                                                     % fanned out: one line lower, further right

% Clusters: peaks closer than half a text width and one text height
cluster = zeros(n, 1);
for k = 1:n
    j = find(cluster(1:k-1) > 0 & abs(p(1:k-1,1) - p(k,1)) < 0.5*wT & abs(p(1:k-1,2) - p(k,2)) < hT, 1);
    if isempty(j), cluster(k) = max(cluster) + 1; else, cluster(k) = cluster(j); end
end

% Place the clusters one after the other; all orders of the clusters are
% tried; used is the one with the smallest total arrow length plus 100 px
% (2.6 cm) per clash (on a tie the given order), so that a minor clash is
% preferred to much longer arrows
nClu = max(cluster);
orders = perms(nClu:-1:1);                                                 % first row: 1, 2, ..., nClu
if nClu > 6, orders = 1:nClu; end
nMin = inf;
for o = 1:size(orders, 1)
    [tO, belowO, nO] = placeClusters(orders(o,:), cluster, p, wT, hT, d0, step, axPx);
    score = nO*100 + sum(vecnorm(tO + [zeros(n,1), hT*belowO] - p, 2, 2));
    if score < nMin - 1e-9, t = tO; below = belowO; nMin = score; end
end

for k = 1:n
    set(h(k), 'Position', [t(k,:) + [gap, 0], 0]);
    a = toN(t(k,:) + [0, hT*below(k)]); b = toN(p(k,:));
    annotation(fig, 'arrow', [a(1), b(1)], [a(2), b(2)], 'Color', cl{k}, ...
        'HeadLength', 6, 'HeadWidth', 6);
end
end

function [t, below, nTot] = placeClusters(order, cluster, p, wT, hT, d0, step, axPx)
% Texts (lower left corners t) of the clusters in the given order; nTot:
% number of clashes of the layout
n = size(p, 1);
t = zeros(n, 2);
below = false(n, 1);                                                       % text below the peak (arrow from its upper left corner)
occupied = zeros(0, 4);
segs = zeros(0, 4);                                                        % arrows [x1 y1 x2 y2]
box = @(q) [q(1), q(2), q(1) + wT, q(2) + hT];
nTot = 0;
for c = order
    idx = find(cluster == c);
    m = numel(idx);
    k1 = idx(1);
    pTop = max(p(idx,2));
    % first text at 45 degrees, high enough that the last one is still
    % 0.3 lines above the highest peak of the cluster
    d = max(d0, pTop - p(k1,2) + 0.3*hT + (m - 1)*hT);
    place = @(d, e) p(k1,:) + [d + e, d] + (0:m-1)'*step;
    % whole cluster further up along the 45 degree line if its texts
    % overlap those of another one or the arrows cross texts; if that is
    % not possible within the axes, also further to the right (e)
    % (no position without clashes: the one with the fewest)
    inAxes = @(tc) all(tc(:,1) + wT <= axPx(3)) && all(tc(:,2) + hT <= axPx(4));
    best = place(d, 0);
    nBest = inf;
    for e = 0:0.25*wT:axPx(3)
        for dd = d:0.25*hT:axPx(4)
            tc = place(dd, e);
            if ~inAxes(tc), break, end
            nc = clash(tc, p(idx,:), box, occupied, segs);
            if nc < nBest, best = tc; nBest = nc; end
            if nc == 0, break, end
        end
        if nBest == 0 || ~inAxes(place(d, e)), break, end
    end
    t(idx,:) = best;
    % single peak without room above: text down and to the right
    if m == 1 && t(k1,2) + hT > axPx(4)
        t(k1,:) = p(k1,:) + [d0, -d0 - hT];
        below(k1) = true;
        nBest = 0;
    end
    nTot = nTot + min(nBest, 1e3);
    for k = idx(:)'
        occupied(end+1, :) = box(t(k,:)); %#ok<AGROW>
        segs(end+1, :) = [t(k,:) + [0, hT*below(k)], p(k,:)]; %#ok<AGROW>
    end
end
end

function tf = clash(tc, pc, box, occupied, segs)
% Number of clashes: texts tc (lower left corners) with arrows to the peaks
% pc overlap the texts occupied, or arrows cross texts (new and earlier)
B = cell2mat(arrayfun(@(k) box(tc(k,:)), (1:size(tc,1))', 'UniformOutput', false));
tf = 0;
for k = 1:size(tc,1)
    tf = tf + nnz(overlaps(B(k,:), occupied)) + ...
        hits([tc(k,:), pc(k,:)], occupied) + hits([tc(k,:), pc(k,:)], B([1:k-1, k+1:end],:));
end
for s = 1:size(segs,1)
    tf = tf + hits(segs(s,:), B);
end
end

function tf = hits(seg, B)
% Arrow seg = [x1 y1 x2 y2] passes through one of the boxes B (inner part,
% without the end points)
tf = false;
if isempty(B), return, end
for u = linspace(0.08, 0.92, 40)
    q = seg(1:2) + u*(seg(3:4) - seg(1:2));
    if any(q(1) > B(:,1) & q(1) < B(:,3) & q(2) > B(:,2) & q(2) < B(:,4))
        tf = true; return
    end
end
end

function tf = overlaps(b, B)
tf = b(1) < B(:,3) & b(3) > B(:,1) & b(2) < B(:,4) & b(4) > B(:,2);
end
