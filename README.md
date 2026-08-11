# Datarock Broken Down Lead Deposit: Geochemical Proximity Classification

This repository contains a time-boxed data-science solution for the Datarock coding challenge. The objective is to use eight geochemical assay variables (As, Au, Pb, Fe, Mo, Cu, S and Zn) to classify intervals as:

- **A:** proximal to the orebody
- **B:** distal from the orebody

The main focus of this version is not simply maximising random-split accuracy. It is estimating how well a model may generalise to **unseen drill holes**.

## Approach

### 1. QA/QC and assay handling

The workflow checks sample IDs, drill-hole intervals, missing values, below-detection-limit strings and sentinel values.

Important preprocessing decisions:

- `-999` is treated as missing.
- Values such as `<0.005` are treated as censored measurements rather than ordinary missing values. For this exercise they are replaced with half the stated reporting limit, for example `<0.005` becomes `0.0025`.
- This below-detection-limit treatment is an explicit modelling assumption. In a production workflow I would confirm the appropriate convention with the assay/geochemistry team.

The workflow also compares missingness between the labelled and unlabeled holes to identify possible data-distribution shift.

### 2. Features

The primary model uses only the eight assay variables:

`As, Au, Pb, Fe, Mo, Cu, S, Zn`

`Unique_ID`, `holeid`, `from` and `to` are retained as metadata but excluded from the main predictive model.

This is deliberate. The purpose is to test whether the geochemistry itself contains useful information about proximity, rather than allowing the model to exploit drill-hole identity or depth/location shortcuts.

### 3. Drill-hole-aware validation

Adjacent samples from the same drill hole are spatially related. A random row-level train/test split can therefore place neighbouring intervals from the same hole in both training and validation, producing an optimistic performance estimate.

This solution uses:

`StratifiedGroupKFold`

with `holeid` as the group.

Each validation hole is therefore completely unseen during training.

### 4. Models

Two deliberately simple models are compared:

1. **Logistic Regression**
   - interpretable baseline
   - log-transformed assay values
   - median imputation with missing-value indicators
   - balanced class weights

2. **Extra Trees**
   - nonlinear tree ensemble
   - median imputation with missing-value indicators
   - balanced class weights

The main model-selection metric is **balanced accuracy**, with ROC-AUC, precision, recall and F1 also reported.

A large hyperparameter search is intentionally avoided. For a short coding exercise, correct validation and defensible assumptions are more important than marginal gains from extensive tuning.

### 5. Final prediction

After model comparison, the selected model is refit on **all labelled samples**.

It then predicts the 767 unlabeled intervals and exports:

`outputs/predictions.csv`

including:

- predicted class
- probability of Class A
- prediction confidence
- a simple low-confidence flag

### 6. Interpretation

Model feature importance is treated as **predictive association, not geological causation**.

If elements such as Pb, Mo, As or Au are influential, that is a useful starting point for discussion with a geologist or geochemist. It should not be interpreted as proof of a mineralisation mechanism from the model alone.

### 7. Downhole continuity

The model predicts intervals independently. Some holes may therefore show rapid A/B switching.

The solution deliberately does **not** smooth those predictions automatically, because that would impose another geological assumption without validation.

In a production workflow I would first ask the geology team how much downhole continuity is expected and at what scale, then test a spatial, sequence or smoothing approach if justified.

## Domain questions I would clarify before production use

1. Is half the reporting limit an appropriate treatment for below-detection-limit assays for these analytical methods?
2. Which error is more costly operationally: falsely flagging a distal interval as proximal, or missing a genuinely proximal interval?
3. Do the strongest model associations make geological sense for this deposit?
4. How much downhole continuity should reasonably be expected?
5. Are the unlabeled holes from the same assay campaign, laboratory and geological setting as the labelled data?

## Limitations

This is a predictive prototype, not a production geological decision system.

Important limitations include:

- labels are based on proximity to an existing orebody interpretation;
- grouped cross-validation still has fold-to-fold variability;
- assay missingness differs between parts of the dataset;
- the model does not explicitly include spatial or downhole dependence;
- probability thresholds have not been calibrated against operational cost;
- geological and assay-domain review would be required before operational deployment.

## Repository structure

```text
data/
    data_for_distribution.csv

nbtk/
    geochem_proximity_model.ipynb

outputs/
    predictions.csv    # generated when notebook is run

environment.yml
README.md
```

## Environment

Create the environment with:

```bash
conda env create -f environment.yml
conda activate geochem_classification
jupyter notebook
```

## Original challenge

The original coding-test problem is available from the Solve Geosolutions / Datarock coding-test repository.
