clear 
close all
restoredefaultpath

addpath('..\bin');

% these variables are defined in the OpenLoop model's FAST_SFunc block:
FAST_InputFileName = 'C:\Users\oster\Desktop\OpenFast-Masterarbeit\openFAST\5MW-Turbine-Inputfiles\5MW_Land_DLL_WTurb.fst';
TMax               = 60; % seconds

sim('OpenLoop.mdl',[0,TMax]);
