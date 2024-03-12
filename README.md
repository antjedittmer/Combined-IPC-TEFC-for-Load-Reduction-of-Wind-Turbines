# Combined Individual Pitch and Flap Control for Load Reduction of Wind Turbines 
## General

This repository contains the MATLAB code, Simulink models and FAST input files used to obtain the results in 
> A. Dittmer, B. Osterwinter, D. Ossmann (2024) Combined Individual Pitch and Flap Control for Load Reduction of Wind Turbines

submitted to Torque 2024.

It may be used to recreate the simulation results and figures from the paper. To do so, run the script `mainPlotPaper.m`, located in the folder Main/plotFunktionen/

The paper and the code is based on the Master thesis 
> Osterwinter, Bernhard (2023) Kombinierte individuelle Blatt- und Hinterkantenklappenregelung zur Lastminimierung bei Windkraftanlagen. DLR-Interner Bericht. DLR-IB-FT-BS-2023-66. Master's. Hochschule fur angewandte Wissenschaften München"

The script `UserInputs_and_ProgrammStart.m` in the directory Main was used to generate analytic plots of this Master thesis. It was also run to create the simulation data saved in the folder Main/Post_processing_for_plots used as inputs to create the plots of the paper. Running the simulation for the four combination of IPC and TEFC enabled and disables takes roughly 5 minutes using a laptop with an 11th Gen Intel(R) Core(TM) i7-11850H @ 2.50GHz processor.

## Simulation Environment

The National Renewable Energy Laboratory’s (NREL) OpenFAST simulation software (https://github.com/OpenFAST/openfast) is used to investigate the benefits of combining individual pitch and trailing-edge flap control. The NREL 5MW wind turbine model is  modified to implement controllable trailing-edge flaps on the rotor blades.
A baseline power controller is taken from TU Delft's FASTTool (https://github.com/TUDelft-DataDrivenControl/FASTTool). An optimization data set with wind of turbulence class A was created to optimize the PID
parameters for each wind speed separately, with the AALC’s effect analyzed via the incorporation of 
* five wind speeds in region II, from 4 m/s to 11 m/s, 
* and nine different wind speeds in region III, ranging from 12 m/s to 25 m/s. 

Two verification sets were created for the 14 different wind speeds, one set with turbulence class A with a different seed and one with turbulence class B.
The vertical wind speed distribution is modeled with a power law wind profile to represent wind shear, using an exponent of 0.2. The wind fields are available in the directory 5MW-Turbine-Inputfiles\Sub-Inputfiles\WindData\Eigene_Wind_Dateien
* Optimization set (NTM class A) in directory TurbKlasseA
* Verification set 1 (NTM class A) in directory TurbKlasseAnewSeed
* Verification set 2 (NTM class B) in main directory Eigene_Wind_Dateien
* 14 data sets with constant wind speed for open loop TEF verification in directory

The  

## Evaluation 

The code in this repository was tested in the following environment:

* Windows 10 Enterprise 21H2
* Matlab 2021b (Toolboxes used: Control System Toolbox and Optimization Toolbox)

## Code Overwiew

Directories

* Main: Contains MATLAB code for turbine simulation in open and closed loop
* FAST_Sim_TEF: Contains modified OpenFAST files including TEF inputs. 

To run simulation for testing the effects of IPC and TEFC control, use the main file from the Master thesis, `UserInputs_and_ProgrammStart.m` in the directory Main.

