clc; clear; close all;
addpath("breakyaxis")

% Reynolds number at radial segment of blade
nF = plotPaper01_Re;

% Lift and drag coefficients
nF = plotPaper01_lift_data(nF);

% OL steady state, different flap settings in two plot
nF = plotPaper06_TEFOL_2(nF);

% CL PSD for 16; comparison between initial AALC and opt. AALC
nF = plotPaper02_PSD_comparison(nF);