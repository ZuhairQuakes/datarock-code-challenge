# Datarock Broken Down Lead Deposit: geochemical proximity classification

This repository is a reproducible solution to the [Solve Geosolutions / Datarock coding test](https://github.com/Solve-Geosolutions/coding-test). It uses eight geochemical assay variables—As, Au, Pb, Fe, Mo, Cu, S, and Zn—to classify drill-hole intervals as:

- **A:** proximal to the orebody
- **B:** distal from the orebody

The final model scores the 767 intervals whose original class is `?`. The main analysis and presentation deliverable is the fully executed notebook:

[`nbtk/geochem_proximity_model.ipynb`](nbtk/geochem_proximity_model.ipynb)

## Results at a glance

The final model is selected using five-fold `StratifiedGroupKFold` validation, grouped by `holeid`. Every validation hole is absent from its corresponding training fold.

| Model | Accuracy | Balanced accuracy | ROC-AUC | Precision A | Recall A | F1 A |
|---|---:|---:|---:|---:|---:|---:|
| Extra Trees | 0.801 | 0.793 | 0.867 | 0.900 | 0.811 | 0.853 |
| Logistic Regression | 0.772 | 0.770 | 0.835 | 0.892 | 0.775 | 0.829 |

Extra Trees is selected because it has the higher grouped out-of-fold balanced accuracy.

![Model comparison](output/plots/model_comparison.png)

The final model produces:

| Predicted class | Intervals |
|---|---:|
| A | 267 |
| B | 500 |

The complete predictions are available at [`output/predictions.csv`](output/predictions.csv).

## Workflow

### 1. QA/QC and assay handling

The workflow checks:

- duplicate sample identifiers;
- non-positive drill intervals;
- blank and missing assay values;
- below-detection-limit strings such as `<0.005`;
- the `-999` missing-value sentinel.

For this exercise, `<x` is replaced with `x / 2`, while `-999` is converted to missing. The detection-limit convention is an explicit assumption requiring validation with an assay or geochemistry domain expert before operational use.

Missingness is compared between labelled and prediction datasets and saved to [`output/missingness_comparison.csv`](output/missingness_comparison.csv).

![Missingness comparison](output/plots/missingness_comparison.png)

### 2. Features

The model uses only the eight assay variables. `Unique_ID`, `holeid`, `from`, and `to` are retained as metadata but excluded from the predictors. This tests predictive information in the geochemistry without introducing hole identity or interval depth as shortcuts.

### 3. Drill-hole-aware validation

Adjacent intervals from one drill hole are related. A row-random split could put neighbouring intervals from the same hole in both training and validation, producing an optimistic estimate for future holes.

The workflow uses `StratifiedGroupKFold` with `holeid` as the group. The reported metrics are therefore out-of-fold results for holes unseen by the corresponding fitted model.

Two models are compared:

1. **Logistic Regression**
   - median imputation with missingness indicators;
   - `log1p` transformation and standardisation;
   - balanced class weights.
2. **Extra Trees**
   - median imputation with missingness indicators;
   - nonlinear tree ensemble;
   - balanced class weights;
   - deterministic single-worker fitting for repeatable score files.

![Grouped confusion matrix](output/plots/confusion_matrix.png)

### 4. Per-hole evaluation

Overall row-level metrics give larger holes more weight because they contain more intervals. The notebook therefore also calculates metrics separately for all 123 labelled holes.

- Per-hole accuracy is reported for every hole.
- Per-hole balanced accuracy and ROC-AUC are reported only for holes containing both classes.
- Mean per-hole accuracy gives each hole equal weight.
- Full results are saved to [`output/per_hole_validation.csv`](output/per_hole_validation.csv).

| Per-hole validation summary | Result |
|---|---:|
| Labelled holes evaluated | 123 |
| Mean per-hole accuracy | 0.872 |
| Median per-hole accuracy | 0.958 |
| 10th percentile per-hole accuracy | 0.659 |
| Holes containing both classes | 32 |
| Mean balanced accuracy across two-class holes | 0.715 |
| Mean ROC-AUC across two-class holes | 0.809 |

Because 91 of the 123 holes contain only one observed class, mean per-hole accuracy is not a replacement for the overall grouped balanced accuracy. The two-class-hole metrics are shown separately for that reason.

![Per-hole accuracy](output/plots/per_hole_accuracy.png)

Variation across holes is presented as a validation result only. Any relationship between difficult holes and geology, sampling, assay campaigns, or spatial context requires domain-expert review.

### 5. Final model scores

The selected Extra Trees pipeline is refit on all 4,004 labelled intervals and applied to all 767 unlabelled intervals.

The output deliberately uses **score** terminology:

- `model_score_A`: uncalibrated Extra Trees score for Class A;
- `score_strength`: the larger of `model_score_A` and `1 - model_score_A`;
- `near_decision_boundary`: `True` when the score lies between 0.40 and 0.60.

These values are not presented as calibrated probabilities.

## Distribution checks and validation boundary

Class A represents approximately 71.5% of labelled intervals. The model assigns Class A to approximately 34.8% of prediction intervals, a difference of about -36.7 percentage points.

![Class distribution comparison](output/plots/class_distribution.png)

This is a descriptive comparison between known labels and model predictions. It is not interpreted as a geological trend.

Before drawing conclusions from this result, domain experts should validate:

1. whether the labelled and new holes are comparable in geological setting, drilling purpose, assay campaign, laboratory, and sampling process;
2. whether a different proximal/distal prevalence is expected in the new drilling area;
3. whether the missingness differences—especially for As and Mo—represent benign acquisition changes or material dataset shift;
4. whether the strongest predictive associations are plausible or are dataset-specific proxies;
5. whether a 0.50 score threshold reflects the operational costs of false proximal and false distal calls;
6. whether the observed downhole switching rates are plausible before smoothing or sequence assumptions are introduced.

Until those checks are complete, the observed differences require validation and should not be used to infer a cause.

## Predictive associations

Extra Trees impurity-based importance is exported for inspection. It describes predictive association, not causation.

![Feature importance](output/plots/feature_importance.png)

The ranking requires geology and geochemistry review before meaning is assigned to the associations.

## Reproduce the analysis

Python 3.9 or later is recommended. Direct dependencies are pinned in [`requirements.txt`](requirements.txt).

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
./run.sh
```

After dependencies are installed, `./run.sh` is the one-command execution path. It executes the notebook in place, refreshes all embedded outputs and plots, and rewrites the CSV result tables under `output/`.

## Generated outputs

| Path | Description |
|---|---|
| `output/predictions.csv` | Predictions and uncalibrated model scores for the 767 unlabelled intervals |
| `output/model_comparison.csv` | Grouped out-of-fold model metrics |
| `output/fold_metrics.csv` | Metrics for each grouped validation fold |
| `output/per_hole_validation.csv` | Validation metrics for every labelled drill hole |
| `output/per_hole_summary.csv` | Equal-hole-weighted summary statistics |
| `output/missingness_comparison.csv` | Missingness comparison by assay feature |
| `output/class_distribution.csv` | Labelled and predicted class proportions |
| `output/feature_importance.csv` | Extra Trees predictive feature importance |
| `output/downhole_continuity.csv` | Predicted transition counts by new drill hole |
| `output/plots/` | Figures embedded in the README and executed notebook |

## Repository structure

```text
data/
    data_for_distribution.csv
    README.md
nbtk/
    geochem_proximity_model.ipynb
    README.md
output/
    predictions.csv
    validation tables...
    plots/
requirements.txt
run.sh
README.md
```

## Limitations

- Labels are derived from proximity to an existing orebody interpretation.
- Grouped cross-validation still shows fold-to-fold and hole-to-hole variation.
- Missingness differs between the labelled and prediction datasets.
- Model scores are not calibrated probabilities.
- The 0.50 classification threshold has not been selected using operational error costs.
- Intervals are scored independently; no spatial or downhole smoothing is applied.
- Geological, geochemical, assay, and operational review is required before deployment or interpretation of trends.
