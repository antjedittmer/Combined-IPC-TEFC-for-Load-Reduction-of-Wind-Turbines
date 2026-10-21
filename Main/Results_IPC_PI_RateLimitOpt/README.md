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

## Check on other 18 m/s wind seeds (`SeedCheck`)

The optimized gains were simulated (`'Optimizer','none'`, rows of `x0` are evaluated) on the other
18 m/s wind files, each compared with IPC off at the same rate limit and the same wind file:

- B: `Eigene_Wind_Dateien/18mps.bts` (hub 17.7 m/s, TI 17.2 %)
- C1: `TurbKlasseA/18mpsNewSeed.bts` and C2: `TurbKlasseAnewSeed/18mps.bts` (hub 17.8 m/s, TI 15.4 %);
  C1 and C2 are the same seed, the values differ only in the last bit.
- For comparison, the optimization file `TurbKlasseA/18mps.bts`: hub 18.2 m/s, TI 16.0 %.

Worst blade root DEL change (cost) / tower DEL change in %:

| Rate limit | K_P | K_I | Optimization seed | B | C1 | C2 |
|---|---|---|---|---|---|---|
| 4 deg/s  | 0.7455 | 0.2168 | -18.4 / +0.6 | **+129 / +109** | **+152 / +161** | **+152 / +161** |
| 4 deg/s  | 0.5857 | 0.2322 | -18.0 / +1.4 | -14.7 / +1.1 | **+147 / +159** | **+147 / +159** |
| 8 deg/s  | 0.6222 | 0.3168 | -20.1 / -0.6 | -18.0 / +4.3 | -19.4 / +0.1 | -19.4 / +0.1 |
| 8 deg/s  | 1.0959 | 0.2504 | -21.2 / -6.6 | -17.7 / -4.9 | -18.9 / -0.1 | -19.1 / +3.5 |
| 13 deg/s | 0.6323 | 0.3415 | -20.6 / -4.5 | -18.2 / +5.5 | -19.4 / +0.1 | -19.4 / +0.1 |
| 13 deg/s | 0.9669 | 0.2209 | -22.1 / -6.3 | -17.9 / +4.6 | **failed** | **failed** |

- 4 deg/s: none of the gain sets is robust. On seed C (and on seed B for K_P = 0.75) the loads
  increase by more than 100 % and the power drops (-2.6 %, on B -18 %): the IPC uses the shared rate
  budget and the speed control fails, as in the first 4 deg/s run with high K_I. The 4 deg/s gains
  need to be optimized on several seeds or with a robustness margin.
- 8 and 13 deg/s: the moderate fminsearch gains (K_P about 0.62-0.63, K_I about 0.32-0.34) are robust
  and give -18 to -19.4 % on the new seeds (1-2 percentage points less than on the optimization seed).
  The tower DEL changes between -4.5 % and +5.5 % depending on the seed.
- The higher-K_P fmincon gains do not generalize: at 8 deg/s they are slightly worse than the
  fminsearch gains on the new seeds, at 13 deg/s they fail on seed C (tower strike).
- C1 and C2 give practically the same result except for the 8 deg/s fmincon gains (tower -0.1 %
  vs +3.5 %), again showing the sensitivity of the high-gain region.

### 13 deg/s with the 8 deg/s gains (`SeedCheck/Seeds_RL13_x08_*`)

Same table format (worst blade root DEL / tower DEL in %), A = optimization seed:

| Gains (K_P, K_I) | Rate limit | A | B | C1 | C2 |
|---|---|---|---|---|---|
| 0.6222, 0.3168 | 8 deg/s  | -20.1 / -0.6 | -18.0 / +4.3 | -19.4 / +0.1 | -19.4 / +0.1 |
| 0.6222, 0.3168 | 13 deg/s | -20.0 / -0.4 | **tower strike** | -19.4 / +0.1 | -19.4 / +0.1 |
| 0.6323, 0.3415 | 13 deg/s | -20.6 / -4.5 | -18.2 / +5.5 | -19.4 / +0.1 | -19.4 / +0.1 |
| 1.0959, 0.2504 | 8 deg/s  | -21.2 / -6.6 | -17.7 / -4.9 | -18.9 / -0.1 | -19.1 / +3.5 |
| 1.0959, 0.2504 | 13 deg/s | -20.2 / -1.5 | -16.1 / +1.4 | -19.4 / +4.6 | -19.2 / -1.1 |

- On seeds A and C the 8 deg/s gains give practically the same result at 13 deg/s (the rate limit
  is rarely active).
- On seed B the moderate gains (0.6222, 0.3168) lead to a tower strike at 13 deg/s, although the
  same gains work at 8 deg/s and the very similar 13 deg/s gains (0.6323, 0.3415) work at 13 deg/s.
  Seed B (highest turbulence) is close to the tower clearance limit, and small changes decide
  whether a strike occurs. No gain set has been robust on all seeds and rate limits so far.

## Re-optimization with the IPC/TEF fade-in (`FadeIn`)

The runs above were done without the fade-in of the IPC and TEF inputs (0 until 20 s, linear to 1 at
30 s). Without it the IPC swung the pitch in the first seconds, and part of the optima above are
start-up artefacts (e.g. the 8 deg/s fmincon gains 1.0959 / 0.2504: tower -6.6 % without, -1.1 % with
the fade-in). `FadeIn` contains the re-optimization with the fade-in, run one after another on the
optimization seed (`reproduceIPC_FadeInOpt`):

- fminsearch first (InitialStep [0.2 0.1], joint run [0.2 0.1 0.1]), then fmincon from its result
  (tower constraint, bounds 0..2, TEF K_P 0..4, FiniteDiffStep 0.05 because of the noisy cost)
- start values: 4 deg/s [0.75 0.22], 8 and 13 deg/s [0.8 0.3]; IPC + TEF jointly (`Vars` =
  `"IPC_TEF_KP"`, TEF K_I = K_D = 0) at 8 deg/s from the 8 deg/s IPC result and TEF K_P = 0.24

| Run | Rate limit | IPC K_P / K_I | TEF K_P | Worst blade root DEL | Tower DEL | Pitch ADC |
|---|---|---|---|---|---|---|
| IPC, fminsearch | 4 deg/s | 0.591 / 0.236 | - | -18.0 % | +1.4 % | +277 % |
| IPC, fmincon | 4 deg/s | 0.253 / 0.103 | - | -15.1 % | 0.0 % | +225 % |
| IPC, fminsearch | 8 deg/s | 1.222 / 0.370 | - | -20.6 % | -1.1 % | +409 % |
| IPC, fmincon | 8 deg/s | unchanged | - | -20.6 % | -1.1 % | +409 % |
| IPC + TEF, fminsearch | 8 deg/s | 0.082 / 0.669 | 0.641 | -22.7 % | -1.0 % | +266 % |
| IPC + TEF, fmincon | 8 deg/s | unchanged | 0.641 | -22.7 % | -1.0 % | +266 % |
| IPC, fminsearch | 13 deg/s | 1.223 / 0.365 | - | -20.5 % | -0.8 % | +409 % |
| IPC, fmincon | 13 deg/s | unchanged | - | -20.5 % | -0.8 % | +409 % |

- 8 and 13 deg/s end at almost the same gains and DELs; the IPC does not use the extra rate.
- The joint IPC + TEF optimization gives -22.7 % instead of -20.6 % (IPC only) and -21.4 % (TEF on top
  of fixed IPC gains), with much less pitch activity (+266 % instead of +409 %): small IPC K_P, larger
  K_I, and the TEF takes more of the work. The gain of about 2 percentage points is not much above
  the noise of about 1 percentage point; it still needs a check on another seed.
- With the fade-in the IPC hardly changes the tower DEL (-1.1 % to +1.4 %).
- 4 deg/s: the fminsearch point violates the tower constraint (+1.4 %), so fmincon moves to a feasible
  point (tower +0.03 %) with a clearly worse blade DEL (-15.1 %).
- At 8 and 13 deg/s fmincon keeps the start point (feasible, no better point found).

`FadeIn/best.mat` holds the gains of all runs, `FadeIn/Logs.zip` the logs.

`FadeIn/TimeSeries` contains the time series (baseline and optimum, 25 channels as in `TimeSeries`)
of the fmincon gains: `TimeSeries_RL04.mat`, `_RL08.mat`, `_RL13.mat` (IPC) and
`TimeSeries_RL08_IPCTEF.mat` (IPC + TEF at 8 deg/s). They are created with
`storeIPC_FadeInTimeSeries` (from `Main`, about 3 min per run; the full files go to the git-ignored
`Post_processing/IPCfade_TS_<run>`) and plotted without simulation with

```matlab
ts = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'TimeSeries');
plotIPC_PSD_RateLimits(struct('Files', ...
    string(fullfile(ts, {'TimeSeries_RL04.mat', 'TimeSeries_RL08.mat', ...
                         'TimeSeries_RL13.mat', 'TimeSeries_RL08_IPCTEF.mat'})), ...
    'Labels', ["IPC, 4°/s", "IPC, 8°/s", "IPC, 13°/s", "IPC + TEF, 8°/s"], ...
    'FigName', 'fig03_PSD_ratecomp_fadeIn'));
```

The re-simulations reproduce the costs of the optimization (e.g. -0.2053 at 13 deg/s, -0.2269 for
IPC + TEF). The 8 and 13 deg/s PSDs lie on top of each other (almost identical gains).

## PSD plots (`TimeSeries`)

`TimeSeries/TimeSeries_RL04.mat`, `_RL08.mat` and `_RL13.mat` contain the baseline and the
optimum of `RL04_refine` (K_P = 0.7455, K_I = 0.2168), `RL08_fmincon` (1.0959, 0.2504) and
`RL13_fmincon_x08` (0.9669, 0.2209), simulated before the IPC/TEF fade-in with
`'SaveTimeSeries', true` (18 m/s, class A, 660 s). They are copies of
`Main/Post_processing/IPC_PI_TS_RL04_opt`, `IPC_PI_TS_RL08_x08` and `IPC_PI_TS_RL13_opt`
(git-ignored, 70 MB each), reduced to 25 channels (wind, pitch, rotor and generator speed,
blade root, yaw bearing and tower base moments, nacelle acceleration, power, torque) at the
full sample time of 0.01 s. Each file holds its own baseline at the same rate limit.

From `Main/plotFunktionen` (or with it on the path):

```matlab
P = plotIPC_PSD_RateLimits;   % figIPC_RateLimits/fig03_PSD_ratecomp.png/.eps
```

plots the PSDs (Welch, Hann window of 2^14 samples) of the baseline at 8 deg/s and the IPC at
4, 8 and 13 deg/s for RootMyc1, TwrBsMyt, TwrBsMxt, YawBrMyp, NcIMUTAxs and BldPitch1 and prints
the changes of the 1P, 2P and 3P peaks and of the standard deviations. Channels, files, window
and frequency range are options (`help plotIPC_PSD_RateLimits`). It needs the Signal Processing
Toolbox (`pwelch`), but no simulation. The help also shows how to store the time series of the
fade-in gains and plot them.

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
reproduceIPC_FadeInOpt                  % re-optimization with the fade-in (FadeIn)
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
