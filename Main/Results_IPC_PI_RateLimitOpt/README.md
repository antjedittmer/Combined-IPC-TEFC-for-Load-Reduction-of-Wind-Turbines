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
| 4 deg/s (RL04_refine)  | 0.7455 | 0.2168 | -18.4 / -22.0 / -18.5 % | +0.6 % | +297 % | ±0 % |
| 8 deg/s (RL08_refine)  | 0.6222 | 0.3168 | -20.8 / -21.6 / -20.1 % | -0.6 % | +284 % | ±0 % |
| 13 deg/s (RL13)        | 0.6323 | 0.3415 | -21.2 / -20.9 / -20.6 % | -4.5 % | +287 % | ±0 % |

All runs, including start values and number of evaluations: `Summary_all.csv`.

- `RLxx_refine` are second optimizations started from the optima of the first round
  (RL04_start3, RL08, RL13). They change the cost by at most 0.2 percentage points:
  4 deg/s -0.1817 -> -0.1837, 8 deg/s -0.2006 -> -0.2006 (converged after 19 evaluations),
  13 deg/s no better point found (-0.2062). The optima lie next to unstable gains: 35 of
  63 evaluations at 4 deg/s and 12 of 61 at 13 deg/s were worse than the baseline or failed
  (tower strike); a 5 % step in K_P or K_I can already be enough.

- `RL04` is the first 4 deg/s run from the repo's start values [0.354 1.194]. It failed (cost
  +0.365): with the high K_I the IPC uses up the shared rate budget and the speed control
  loses track. It is kept for reference.
- `RL04_start1..4` are restarts from other start values. All end at K_I = 0.22-0.25 and
  K_P = 0.52-0.73 with costs between -0.180 and -0.182 (flat valley).
- `RL13` stopped at MaxFunEvals (not fully converged); `RL08` and `RL04_start4` converged.

## fmincon with tower constraint

`RLxx_fmincon`: `fmincon` (SQP, forward finite differences with 1 % step, bounds 0..2) minimizes
the same cost subject to "relative change of DEL TwrBsMyt <= 0", started from the fminsearch optima.
Failed simulations count as infeasible.

| Rate limit | Result | K_P | K_I | RootMyc1/2/3 DEL | TwrBsMyt DEL | Pitch activity |
|---|---|---|---|---|---|---|
| 4 deg/s  | infeasible, best feasible point in history | 0.7438 | 0.2163 | -19.0 / -16.0 / -21.3 % | -1.5 % | +298 % |
| 8 deg/s  | converged, constraint satisfied | 1.0959 | 0.2504 | -23.8 / -21.2 / -22.8 % | -6.6 % | +368 % |
| 13 deg/s | start point kept (constraint already satisfied) | 0.6323 | 0.3415 | -21.2 / -20.9 / -20.6 % | -4.5 % | +287 % |

- 4 deg/s: fmincon stopped with "converged to an infeasible point" and returned the start point
  (tower +0.6 %). The best point in its history with tower <= 0 is listed above (cost -0.160
  instead of -0.184). The table is taken from `RL04_fmincon/History_RL04.csv`.
- 8 deg/s: a second region with higher K_P (about 1.1) and lower K_I gives a slightly lower cost
  (-0.212 vs -0.201) and a lower tower DEL (-6.6 %), but about 30 % more pitch activity than
  K_P = 0.62. 15 of 46 evaluations failed (tower strike), e.g. at K_P = 2.
- The cost is very sensitive on one 660 s wind field: at 4 deg/s, changing K_P and K_I by about 0.2 % changed the
  tower DEL from +0.6 % to -1.5 % and the worst blade from -18.4 % to -16.0 %. Gradient-based
  optimization therefore works poorly here; differences below about 1 percentage point are not
  meaningful.

### 13 deg/s started from the 8 deg/s fmincon optimum (`RL13_fmincon_x08`)

fmincon at 13 deg/s from K_P = 1.0959, K_I = 0.2504 ends at **K_P = 0.9669, K_I = 0.2209** with
cost -0.221 (RootMyc -24.5 / -22.1 / -24.1 %, tower -6.3 %, pitch activity +334 %), the best
result of all runs. 12 of 32 evaluations failed (tower strike).

Comparison at identical gains (first evaluation of a run, or re-simulation with
`'SaveTimeSeries', true`):

| Gains (K_P, K_I) | Rate limit | Cost | Tower DEL | Pitch activity |
|---|---|---|---|---|
| 1.0959, 0.2504 | 8 deg/s  | -0.212 | -6.6 % | +368 % |
| 1.0959, 0.2504 | 13 deg/s | -0.202 | -1.5 % | +368 % |
| 0.9669, 0.2209 | 13 deg/s | -0.221 | -6.3 % | +334 % |
| 0.9669, 0.2209 | 8 deg/s  | failed (tower strike) | | |

- At identical gains the pitch activity is the same for 8 and 13 deg/s. At 18 m/s the pitch rate
  is above 90 % of the 8 deg/s limit only 0.3-0.8 % of the time and never reaches 13 deg/s, so the
  rate limit rarely acts. The higher pitch activity of the 8 deg/s fmincon result compared with the
  13 deg/s fminsearch result comes from its higher K_P, not from the rate limit.
- The loads, however, change considerably between neighbouring gains and between the two rate
  limits, and gains that are stable for one limit can lead to a tower strike for the other. On a
  single 660 s wind field, differences of about 1 percentage point are within this sensitivity.
- The maximum pitch rate of 13.8 deg/s reported for `RL08_fmincon` is not a violation of the rate
  limit: around t = 406 s all three pitch outputs jitter by about +-0.05 deg from one 0.01 s
  sample to the next (numerical artefact), which gives large finite differences. After t = 5 s
  the actuator rate limiter is active; before that the pitch outputs are not limited.

`RL04_start5`: fminsearch at 4 deg/s from K_P = 0, K_I = 0.1. Because x0(1) = 0, fminsearch starts
with a K_P step of only 0.00025 and K_P stays near 0. It stops after 26 evaluations at
K_P = 0.0018, K_I = 0.276 with cost -0.152 (RootMyc -15.2 / -18.0 / -15.3 %, tower +1.9 %),
i.e. an almost pure I controller, clearly worse than K_P around 0.6-0.75.

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

For the restarts add `'x0',[0.1 0.3]` etc. and the `MaxFunEvals` given in `Summary_all.csv`.
Delete the work folders afterwards.

The 8 flap airfoil files in `FAST_Sim_TEF/5MW-Turbine-Inputfiles/Sub-Inputfiles/Airfoils_Flaps_Re_angepasst`
need `NumCoords = 0` (commit ee4724d), because the `*_coords.txt` files are not in the
repository. Otherwise OpenFAST fails during initialization.
