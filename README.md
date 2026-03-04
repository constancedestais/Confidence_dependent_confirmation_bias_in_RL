
# Confidence-dependent confirmation bias in reinforcement learning

Code for model fitting, statistics, figures, and parameter-recovery analyses for paper.
Paper DOI: [WILL BE ADDED UPON ACCEPTANCE OF THE PAPER]
Data can be accessed at: [WILL BE ADDED UPON ACCEPTANCE OF THE PAPER]

## Repository contents

- `Data/`: preprocessed behavioral datasets (`.mat`, `.csv`)
- `Functions/`: model, fitting, loading, plotting, and simulation utilities
- `Outputs/`: model-fitting outputs and generated figures
- Top-level scripts:
  - `fit_parameters_to_participants.m`
  - `stats_for_paper.m`
  - `figures_for_paper.m`
  - `stats_for_SupplementaryMaterial.m`
  - `figures_for_SupplementaryMaterial.m`
  - `parameter_recovery.m`

## Requirements

- MATLAB
- Optimization Toolbox (`fmincon`)
- Statistics and Machine Learning Toolbox
- Parallel Computing Toolbox (optional, if `use_parallel = 1`)
- Local dependency expected by scripts:
  - `../MBB-team_VBA-toolbox`

## Available models

- model 1: no confidence-dependent learning rates, no confidence modulation of choice (fixed learning rates for confirmatory and disconfirmatory evidence)
- model 2: confidence-dependent learning rates, no confidence modulation of choice
- model 4: confidence-dependent learning rates, AND confidence modulation of choice

## Available datasets

- "MLNSG_0reversals_all"
- "MLNSG_1reversal_all"
- "CDAG_all"
- "MLNSG_0reversals_partialfeedbacktrials"
- "MLNSG_0reversals_completefeedbacktrials"
- "MLNSG_1reversal_partialfeedback" 
- "MLNSG_1reversal_completefeedback"
- "CDAG_partialfeedback"
- "CDAG_completefeedback"

## Quick start

1. Open MATLAB in the repository root.
2. Run:
   - `stats_for_paper`
   - `figures_for_paper`

These scripts use data in `Data/` and precomputed model outputs in `Outputs/`.

## Re-fit model parameters (optional)
Run: fit_parameters_to_participants

## Supplementary analyses
Run:
- stats_for_SupplementaryMaterial
- figures_for_SupplementaryMaterial
  - requires Parameter Recovery data

## Parameter recovery
Run:
- parameter_recovery
This simulates agents with generative models, refits candidate models, and saves outputs under:
- Outputs/Simulations_recovery/

## Notes
Dataset name handling is centralized in:
  Functions/read_behaviour_dataset_dictionary.m
  Functions/read_modelling_output_dataset_dictionary.m
Model definitions and parameter bounds/priors are in:
  Functions/load_models_info.m
