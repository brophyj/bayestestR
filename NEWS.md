# bayestestR 0.2.0

## Breaking changes

- `estimate` argument name in `describe_posterior` and `point_estimate` changed to `centrality`
- `hdi`, `ci`, `rope` and `equivalence_test` default `ci` to `0.89`
- `rnorm_perfect()` deprecated in favour of `distribution_normal()`
- `map_estimate()` now returns a single value instead of a dataframe and the `density` parameter has been removed. The MAP density value is now accessible via `attributes(map_output)$MAP_density`

## New functions / features

- `describe_posterior()`, `describe_prior()`, `diagnostic_posterior()`: added wrapper function
- `point_estimate()` added function to compute point estimates
- `p_direction()`: new argument `method` to compute pd based on AUC
- `area_under_curve()`: compute AUC
- `distribution()` functions have been added
- `bayesfactor_savagedickey()`, `bayesfactor_models()` and `bayesfactor_inclusion()` functions has been added
- Started adding plotting methods (currently in the [`see`](https://github.com/easystats/see) package) for `p_direction()` and `hdi()`
- `probability_at()` as alias for `density_at()`
- `effective_samples()` to return the effective sample size of Stan-models
- `mcse()` to return the Monte Carlo standard error of Stan-models

## Minor changes

- Improved documentation
- Improved testing
- `p_direction()`: improved printing
- `rope()` for model-objects now returns the HDI values for all parameters as attribute in a consistent way
- Changes legend-labels in `plot.equivalence_test()` to align plots with the output of the `print()`-method (#78)

## Bug fixes

- `hdi()` returned multiple class attributes (#72)
- Printing results from `hdi()` failed when `ci`-argument had fractional parts for percentage values (e.g. `ci = .995`).
- `plot.equivalence_test()` did not work properly for *brms*-models (#76).

# bayestestR 0.1.0

- CRAN initial publication and [0.1.0 release](https://github.com/easystats/bayestestR/releases/tag/v0.1.0)
- Added a `NEWS.md` file to track changes to the package
