Available models: 
- model 1: no confidence-dependent learning rates, no confidence modulation of choice (fixed learning rates for confirmatory and disconfirmatory evidence)
- model 2: confidence-dependent learning rates, no confidence modulation of choice
- model 4: confidence-dependent learning rates, AND confidence modulation of choice

Available datasets: 
- "MLNSG_0reversals_all"
- "MLNSG_1reversal_all"
- "CDAG_all"
- "MLNSG_0reversals_partialfeedbacktrials"
- "MLNSG_0reversals_completefeedbacktrials"
- "MLNSG_1reversal_partialfeedback" 
- "MLNSG_1reversal_completefeedback"
- "CDAG_partialfeedback"
- "CDAG_completefeedback"

# -------------------------------
# CD2 Analyses (Paper-Focused)

This repository contains the analysis code and **preprocessed data** used for the paper.

## Data policy

- Included: preprocessed behavioral datasets in `Data/` and modelling outputs in `Outputs/`.

## Main scripts

- `for_paper_reversal_stats_plots_19Feb2026_13h00.m`  
  Generates reversal-centered paper stats and figures.
- `stats_for_paper.m`  
  Computes additional paper statistics across datasets/models.
- `fit_parameters_to_participants.m`  
  Regenerates `Outputs/modelling_outputs_actual_outcomes_*.mat` from preprocessed data.

## Quick start (MATLAB)

1. Open MATLAB in the repository root.
2. Run:

```matlab
for_paper_reversal_stats_plots_19Feb2026_13h00
```

3. (Optional) run:

```matlab
stats_for_paper
```

## Regenerating modelling outputs

Run:

```matlab
fit_parameters_to_participants
```

Notes:
- In `fit_parameters_to_participants.m`, set `run_on_DEC_server = 0` to save outputs directly in `Outputs/`.
- Default setting fits models `[1 2 4]` with `outcome_encoding = "actual"`.

## MATLAB toolboxes

- Optimization Toolbox (`fmincon`)
- Statistics and Machine Learning Toolbox (`ttest`, `mle`, `betarnd`)
- Parallel Computing Toolbox (if `use_parallel = 1`)
