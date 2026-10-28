function printFigureFixedWidth(h, fName)
%PRINTFIGUREFIXEDWIDTH Export as vector .eps and 300 dpi .png with the width of the standard figure
%   printFigureFixedWidth(h, fName) saves figure h as fName.eps and
%   fName.png with the width of the standard MATLAB figure (560 px =
%   14.82 cm) and the height from the aspect ratio of the window. The
%   output is laid out for this paper size, not for the window, and the eps
%   bounding box is the full paper size (-loose), so that all thesis
%   figures have the same width and font size in LaTeX (e.g. two side by
%   side with width=0.495	extwidth).

pos = get(h, 'Position');
sizeCm = 14.82*[1, pos(4)/pos(3)];
set(h, 'PaperUnits', 'centimeters', 'PaperPositionMode', 'manual', ...
    'PaperSize', sizeCm, 'PaperPosition', [0 0 sizeCm]);
print(h, fName, '-depsc', '-painters', '-loose');
print(h, fName, '-dpng', '-r300');
end
