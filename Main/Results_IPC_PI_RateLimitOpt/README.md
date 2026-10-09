# PI-IPC gain optimization for pitch rate limits 4, 8 and 13 deg/s

Optimized K_P and K_I of the PI individual pitch controller (IPC) for three
pitch rate limits. Generated on 2026-10-09 with `Main/optimizeIPC_PI_RateLimits.m`.

## Setup

- NREL 5MW with flaps, OpenFAST v3.2.1 S-function, `FAST_Sim_TEF/ClosedLoop_V5_2020b.slx`
- MATLAB R2023a Update 8 (Simulink, Signal Processing Toolbox for `rainflow`)
- One wind field: `WindData/Eigene_Wind_Dateien/TurbKlasseA/18mps.bts` (18 m/s, NTM class A,
  optimization set), TMax = 660 s, DT = 0.01 s, evaluation window from 66 s
- Controllers: GenTq and CPC on, **TEF off**, IPC PI (K_D = 0)
- Rate limit set (in memory only) in both pitch actuator models (Constant2/Constant3 of the
  rate limiter) and in `Control.Pitch.Maxrate/Minrate` of the CPC
- Cost (as `CostFunctionDELAllMoments`): largest relative change of the blade root DELs
  RootMyc1..3 (Woehler exponent 8, rainflow, 1 Hz equivalent) versus a baseline with IPC off
  at the same rate limit. Failed simulations (e.g. tower strike) get cost 1.
- Optimizer: `fminsearch`, TolX = 1e-2, TolFun = 1e-4

## Results

| Rate limit | K_P | K_I | RootMyc1/2/3 DEL | TwrBsMyt DEL | Pitch activity | Power |
|---|---|---|---|---|---|---|
| 4 deg/s (RL04_start3) | 0.7329 | 0.2174 | -18.8 / -22.1 / -18.2 % | +1.5 % | +295 % | ±0 % |
| 8 deg/s (RL08)        | 0.6227 | 0.3269 | -20.9 / -21.7 / -20.1 % | -0.6 % | +285 % | ±0 % |
| 13 deg/s (RL13)       | 0.6323 | 0.3415 | -21.2 / -20.9 / -20.6 % | -4.5 % | +287 % | ±0 % |

All runs, including start values and number of evaluations: `Summary_all.csv`.

- `RL04` is the first 4 deg/s run from the repo's start values [0.354 1.194]. It failed (cost
  +0.365): with the high K_I the IPC uses up the shared rate budget and the speed control
  loses track. It is kept for reference.
- `RL04_start1..4` are restarts from other start values. All end at K_I = 0.22-0.25 and
  K_P = 0.52-0.73 with costs between -0.180 and -0.182 (flat valley).
- `RL13` stopped at MaxFunEvals (not fully converged); `RL08` and `RL04_start4` converged.

## Files

Each run folder contains:

- `Summary.csv`: optimum gains and relative changes
- `History_RLxx.csv`: every cost evaluation (gains, cost, relative DELs, ADC, power)
- `Results.mat`: `opts` (all options used), `Results` (baseline and optimum DELs etc.), `Summary`

`Logs.zip` contains the MATLAB command window logs of all runs.

## Reproduce

From the `Main` folder in MATLAB (do not call scripts that use `restoredefaultpath` first):

```matlab
reproduceIPC_PI_RateLimitOpt            % all runs, one after another
reproduceIPC_PI_RateLimitOpt("RL08")    % one run
```

The output goes to `Main/Post_processing/IPC_PI_RateLimitOpt_<run>` (git-ignored). One run takes
about 1-1.5 h (about 1 min per 660 s simulation).

The original runs were done in parallel, one `matlab -batch` process per run, each with a
private copy of `FAST_Sim_TEF` (option `WorkFolder`). Example for the 8 deg/s run (from `Main`):

```
matlab -batch "optimizeIPC_PI_RateLimits(struct('RateLimits',8,'MaxFunEvals',60,'WorkFolder','D:/ipc_work/RL08','ResultsFolder',fullfile(pwd,'Post_processing','IPC_PI_RateLimitOpt_RL08')))"
```

For the restarts add `'x0',[0.1 0.3]` etc. and `'MaxFunEvals',40` (values in `Summary_all.csv`).
Delete the work folders afterwards.

The 8 flap airfoil files in `FAST_Sim_TEF/5MW-Turbine-Inputfiles/Sub-Inputfiles/Airfoils_Flaps_Re_angepasst`
need `NumCoords = 0` (commit ee4724d), because the `*_coords.txt` files are not in the
repository. Otherwise OpenFAST fails during initialization.
