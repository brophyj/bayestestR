#' Describe Posterior Distributions
#'
#' Compute indices relevant to describe and characterise the posterior distributions.
#'
#' @param posteriors A vector, dataframe or model of posterior draws.
#' @param ci_method The type of index used for Credible Interval. Can be \link{hdi} (default) or "quantile" (see \link{ci}).
#' @param test The \href{https://easystats.github.io/bayestestR/articles/indicesEstimationComparison.html}{indices of effect existence} to compute. Can be a character or a list with "p_direction", "rope", "p_map" or "bayesfactor".
#' @param rope_range \href{https://easystats.github.io/bayestestR/rope}{ROPE's} lower and higher bounds. Should be a list of two values (e.g., \code{c(-0.1, 0.1)}) or \code{"default"}. If \code{"default"}, the bounds are set to \code{x +- 0.1*SD(response)}.
#' @param rope_ci The Credible Interval (CI) probability, corresponding to the proportion of HDI, to use for the percentage in ROPE.
#'
#' @inheritParams point_estimate
#' @inheritParams ci
#'
#'
#' @examples
#' library(bayestestR)
#'
#' x <- rnorm(1000)
#' describe_posterior(x)
#' describe_posterior(x, centrality = "all", dispersion = TRUE, test = "all")
#' describe_posterior(x, ci = c(0.80, 0.90))
#'
#' df <- data.frame(replicate(4, rnorm(100)))
#' describe_posterior(df)
#' describe_posterior(df, centrality = "all", dispersion = TRUE, test = "all")
#' describe_posterior(df, ci = c(0.80, 0.90))
#'
#' # rstanarm models
#' # -----------------------------------------------
#' library(rstanarm)
#' model <- stan_glm(mpg ~ wt + gear, data = mtcars, chains = 2, iter = 200)
#' describe_posterior(model)
#' describe_posterior(model, centrality = "all", dispersion = TRUE, test = "all")
#' describe_posterior(model, ci = c(0.80, 0.90))
#' \dontrun{
#' # brms models
#' # -----------------------------------------------
#' library(brms)
#' model <- brms::brm(mpg ~ wt + cyl, data = mtcars)
#' describe_posterior(model)
#' describe_posterior(model, centrality = "all", dispersion = TRUE, test = "all")
#' describe_posterior(model, ci = c(0.80, 0.90))
#'
#' # BayesFactor objects
#' # -----------------------------------------------
#' library(BayesFactor)
#' bf <- ttestBF(x = rnorm(100, 1, 1))
#' describe_posterior(bf)
#' describe_posterior(bf, centrality = "all", dispersion = TRUE, test = "all")
#' describe_posterior(bf, ci = c(0.80, 0.90))
#' }
#'
#' @importFrom stats mad median sd setNames
#'
#' @export
describe_posterior <- function(posteriors, centrality = "median", dispersion = TRUE, ci = 0.89, ci_method = "hdi", test = c("pd", "rope"), rope_range = "default", rope_ci = 0.89, ...) {
  UseMethod("describe_posterior")
}




#' @keywords internal
.describe_posterior <- function(x, centrality = "median", dispersion = FALSE, ci = 0.89, ci_method = "hdi", test = c("pd", "rope"), rope_range = "default", rope_ci = 0.89, bf_prior = NULL, ...) {


  # Point-estimates
  if (!is.null(centrality)) {
    estimates <- point_estimate(x, centrality = centrality, dispersion = dispersion, ...)
    if (!"Parameter" %in% names(estimates)) {
      estimates <- cbind(data.frame("Parameter" = "Posterior"), estimates)
    }
  } else {
    estimates <- data.frame("Parameter" = NA)
  }

  # Uncertainty
  if (!is.null(ci)) {
    ci_method <- match.arg(tolower(ci_method), c("hdi", "quantile", "ci", "eti"))
    if (ci_method == "hdi") {
      uncertainty <- hdi(x, ci = ci)
    } else {
      uncertainty <- ci(x, ci = ci)
    }
    if (!"Parameter" %in% names(uncertainty)) {
      uncertainty <- cbind(data.frame("Parameter" = "Posterior"), uncertainty)
    }
  } else {
    uncertainty <- data.frame("Parameter" = NA)
  }

  # Effect Existence
  if (!is.null(test)) {
    test <- match.arg(tolower(test), c(
      "pd", "p_direction", "pdir", "mpe",
      "rope", "equivalence", "equivalence_test", "equitest",
      "bf", "bayesfactor", "bayes_factor", "all"
    ), several.ok = TRUE)
    if ("all" %in% test) {
      test <- c("pd", "rope", "equivalence", "bf")
    }

    # Probability of direction
    if (any(c("pd", "p_direction", "pdir", "mpe") %in% test)) {
      test_pd <- p_direction(x, ...)
      if (!is.data.frame(test_pd)) test_pd <- data.frame("Parameter" = "Posterior", "pd" = test_pd)
    } else {
      test_pd <- data.frame("Parameter" = NA)
    }

    # ROPE
    if (any(c("rope") %in% test)) {
      test_rope <- rope(x, range = rope_range, ci = rope_ci, ...)

      if (!"Parameter" %in% names(test_rope)) {
        test_rope <- cbind(data.frame("Parameter" = "Posterior"), test_rope)
      }
      names(test_rope)[names(test_rope) == "CI"] <- "ROPE_CI"
    } else {
      test_rope <- data.frame("Parameter" = NA)
    }

    # Equivalence test
    if (any(c("equivalence", "equivalence_test", "equitest") %in% test)) {
      if (any(c("rope") %in% test)) {
        equi_warnings <- FALSE
      } else {
        equi_warnings <- TRUE
      }

      test_equi <- equivalence_test(x, range = rope_range, ci = rope_ci, verbose = equi_warnings, ...)

      if (!"Parameter" %in% names(test_equi)) {
        test_equi <- cbind(data.frame("Parameter" = "Posterior"), test_equi)
      }
      names(test_equi)[names(test_equi) == "CI"] <- "ROPE_CI"

      test_rope <- merge(test_rope, test_equi, all = TRUE)
      test_rope <- test_rope[!names(test_rope) %in% c("HDI_low", "HDI_high")]
    }

    # Bayes Factors
    if (any(c("bf", "bayesfactor", "bayes_factor") %in% test)) {
      test_bf <- bayesfactor_savagedickey(x, prior = bf_prior, ...)
      if (!"Parameter" %in% names(test_bf)) {
        test_bf <- cbind(data.frame("Parameter" = "Posterior"), test_bf)
      }
    } else {
      test_bf <- data.frame("Parameter" = NA)
    }
  } else {
    test_pd <- data.frame("Parameter" = NA)
    test_rope <- data.frame("Parameter" = NA)
    test_bf <- data.frame("Parameter" = NA)
  }

  out <- merge(estimates, uncertainty, by = "Parameter", all = TRUE)
  out <- merge(out, test_pd, by = "Parameter", all = TRUE)
  out <- merge(out, test_rope, by = "Parameter", all = TRUE)
  out <- merge(out, test_bf, by = "Parameter", all = TRUE)
  out <- out[!is.na(out$Parameter), ]

  # Restore columns order
  col_order <- point_estimate(x, centrality = "median", dispersion = FALSE, ci = NULL, ...)
  if ("Parameter" %in% names(col_order)) {
    col_order <- col_order$Parameter
    col_order <- rep(col_order, each = round(nrow(out) / length(col_order)))
    out[match(col_order, out$Parameter), ]
  }

  out
}











#' @rdname describe_posterior
#' @param bf_prior Distribution representing a prior for the computation of \href{https://easystats.github.io/bayestestR/bayesfactor_savagedickey}{Bayes factors}. Used if the input is a posterior, otherwise (in the case of models) ignored.
#' @export
describe_posterior.numeric <- function(posteriors, centrality = "median", dispersion = TRUE, ci = 0.89, ci_method = "hdi", test = c("pd", "rope"), rope_range = "default", rope_ci = 0.89, bf_prior = NULL, ...) {
  .describe_posterior(posteriors, centrality = centrality, dispersion = dispersion, ci = ci, ci_method = ci_method, test = test, rope_range = rope_range, rope_ci = rope_ci, bf_prior = bf_prior, ...)
}

#' @export
describe_posterior.double <- describe_posterior.numeric

#' @export
describe_posterior.data.frame <- describe_posterior.numeric





#' @inheritParams insight::get_parameters
#' @inheritParams diagnostic_posterior
#' @param priors Add the prior used for each parameter.
#' @rdname describe_posterior
#' @export
describe_posterior.stanreg <- function(posteriors, centrality = "median", dispersion = FALSE, ci = 0.89, ci_method = "hdi", test = c("pd", "rope"), rope_range = "default", rope_ci = 0.89, bf_prior = NULL, diagnostic = c("ESS", "Rhat"), priors = TRUE, effects = c("fixed", "random", "all"), parameters = NULL, ...) {
  out <- .describe_posterior(posteriors, centrality = centrality, dispersion = dispersion, ci = ci, ci_method = ci_method, test = test, rope_range = rope_range, rope_ci = rope_ci, bf_prior = bf_prior, effects = effects, parameters = parameters, ...)

  if (!is.null(diagnostic)) {
    col_order <- out$Parameter
    diagnostic <- diagnostic_posterior(posteriors, diagnostic, effects = effects, parameters = parameters, ...)
    out <- merge(out, diagnostic, all = TRUE)
    out <- out[match(col_order, out$Parameter), ]
  }

  if (priors) {
    col_order <- out$Parameter
    priors_data <- describe_prior(posteriors, ...)
    out <- merge(out, priors_data, all = TRUE)
    out <- out[match(col_order, out$Parameter), ]
  }
  out
}

#' @inheritParams describe_posterior.stanreg
#' @rdname describe_posterior
#' @export
describe_posterior.brmsfit <- function(posteriors, centrality = "median", dispersion = FALSE, ci = 0.89, ci_method = "hdi", test = c("pd", "rope"), rope_range = "default", rope_ci = 0.89, bf_prior = NULL, diagnostic = c("ESS", "Rhat"), effects = c("fixed", "random", "all"), component = c("conditional", "zi", "zero_inflated", "all"), parameters = NULL, ...) {
  out <- .describe_posterior(posteriors, centrality = centrality, dispersion = dispersion, ci = ci, ci_method = ci_method, test = test, rope_range = rope_range, rope_ci = rope_ci, bf_prior = bf_prior, effects = effects, component = component, parameters = parameters, ...)

  if (!is.null(diagnostic)) {
    col_order <- out$Parameter
    diagnostic <- diagnostic_posterior(posteriors, diagnostic, effects = effects, component = component, parameters = parameters, ...)
    out <- merge(out, diagnostic, all = TRUE)
    out <- out[match(col_order, out$Parameter), ]
  }
  out
}



#' @rdname describe_posterior
#' @export
describe_posterior.BFBayesFactor <- function(posteriors, centrality = "median", dispersion = FALSE, ci = 0.89, ci_method = "hdi", test = c("pd", "rope", "bf"), rope_range = "default", rope_ci = 0.89, priors = TRUE, ...) {

  # Match test args  to catch BFs
  if (!is.null(test)) {
    test <- match.arg(tolower(test), c(
      "pd", "p_direction", "pdir", "mpe",
      "rope", "equivalence", "equivalence_test", "equitest",
      "bf", "bayesfactor", "bayes_factor", "all"
    ), several.ok = TRUE)

    if ("all" %in% test) {
      test <- c("pd", "rope", "equivalence", "bf")
    }
  }

  # Remove BF from list
  if (any(c("bf", "bayesfactor", "bayes_factor") %in% test)) {
    test <- test[!test %in% c("bf", "bayesfactor", "bayes_factor")]
    compute_bf <- TRUE
  } else{
    compute_bf <- FALSE
  }

  # Describe posterior
  out <- .describe_posterior(posteriors, centrality = centrality, dispersion = dispersion, ci = ci, ci_method = ci_method, test = test, rope_range = rope_range, rope_ci = rope_ci, ...)


  # Compute and readd BF a posteriori
  if(compute_bf){
    out$BF <- as.data.frame(bayesfactor_models(posteriors, ...))[-1, ]$BF
  }


  # Add priors
  if (priors) {
    col_order <- out$Parameter
    priors_data <- describe_prior(posteriors, ...)
    out <- merge(out, priors_data, all = TRUE)
    out <- out[match(col_order, out$Parameter), ]
  }
  out
}