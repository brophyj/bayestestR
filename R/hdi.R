#' Highest Density Interval (HDI)
#'
#' Compute the \strong{Highest Density Interval (HDI)} of a posterior distribution, i.e., all points within the interval have a higher probability density than points outside the interval. The HDI can be used in the context of Bayesian posterior characterisation as \strong{Credible Interval (CI)}.
#'
#' @details Unlike equal-tailed intervals (see \link{ci}) that typically exclude 2.5\% from each tail
#'   of the distribution, the HDI is \emph{not} equal-tailed and therefore always
#'   includes the mode(s) of posterior distributions.
#'   \cr \cr
#'   By default, \code{hdi()} returns the 89\% intervals (\code{ci = 0.89}),
#'   deemed to be more stable than, for instance, 95\% intervals (\cite{Kruschke, 2014}).
#'   An effective sample size of at least 10.000 is recommended if 95\% intervals
#'   should be computed (\cite{Kruschke, 2014, p. 183ff}). Moreover, 89 is the
#'   highest prime number that does not exceed the already unstable 95\% threshold.
#'   What does it have to do with anything? Nothing, but it reminds us of the total
#'   arbitrarity of any of these conventions (McElreath, 2015).
#'
#' @param x Vector representing a posterior distribution. Can also be a
#'   \code{stanreg} or \code{brmsfit} model.
#' @param ci Value or vector of probability of the interval (between 0 and 1)
#'   to be estimated. Named Credible Interval (CI) for consistency.
#' @param effects Should results for fixed effects, random effects or both be returned?
#'   Only applies to mixed models. May be abbreviated.
#' @param component Should results for all parameters, parameters for the conditional model
#'   or the zero-inflated part of the model be returned? May be abbreviated. Only
#'   applies to \pkg{brms}-models.
#' @param parameters Regular expression pattern that describes the parameters that
#'   should be returned. Meta-parameters (like \code{lp__} or \code{prior_}) are
#'   filtered by default, so only parameters that typically appear in the
#'   \code{summary()} are returned. Use \code{parameters} to select specific parameters
#'   for the output.
#' @param verbose Toggle off warnings.
#' @param ... Currently not used.
#'
#' @return A data frame with following columns:
#'   \itemize{
#'     \item \code{Parameter} The model parameter(s), if \code{x} is a model-object. If \code{x} is a vector, this column is missing.
#'     \item \code{CI} The probability of the HDI.
#'     \item \code{CI_low} , \code{CI_high} The lower and upper HDI limits for the parameters.
#'   }
#'
#' @examples
#' library(bayestestR)
#'
#' posterior <- rnorm(1000)
#' hdi(posterior, ci = .89)
#' hdi(posterior, ci = c(.80, .90, .95))
#'
#' df <- data.frame(replicate(4, rnorm(100)))
#' hdi(df)
#' hdi(df, ci = c(.80, .90, .95))
#'
#' library(rstanarm)
#' model <- stan_glm(mpg ~ wt + gear, data = mtcars, chains = 2, iter = 200)
#' hdi(model)
#' hdi(model, ci = c(.80, .90, .95))
#'
#' \dontrun{
#' library(brms)
#' model <- brms::brm(mpg ~ wt + cyl, data = mtcars)
#' hdi(model)
#' hdi(model, ci = c(.80, .90, .95))
#'
#' library(BayesFactor)
#' bf <- ttestBF(x = rnorm(100, 1, 1))
#' hdi(bf)
#' hdi(bf, ci = c(.80, .90, .95))
#' }
#'
#' @author Credits go to \href{https://rdrr.io/cran/ggdistribute/src/R/stats.R}{ggdistribute} and \href{https://github.com/mikemeredith/HDInterval}{HDInterval}.
#'
#' @references \itemize{
#'   \item Kruschke, J. (2014). Doing Bayesian data analysis: A tutorial with R, JAGS, and Stan. Academic Press.
#'   \item McElreath, R. (2015). Statistical rethinking: A Bayesian course with examples in R and Stan. Chapman and Hall/CRC.
#' }
#'
#' @export
hdi <- function(x, ...) {
  UseMethod("hdi")
}



#' @rdname hdi
#' @export
hdi.numeric <- function(x, ci = .89, verbose = TRUE, ...) {
  out <- do.call(rbind, lapply(ci, function(i) {
    .hdi(x, ci = i, verbose = verbose)
  }))
  class(out) <- unique(c("hdi", "see_hdi", class(out)))
  attr(out, "data") <- x
  out
}



#' @rdname hdi
#' @export
hdi.data.frame <- function(x, ci = .89, verbose = TRUE, ...) {
  dat <- .compute_interval_dataframe(x = x, ci = ci, verbose = verbose, fun = "hdi")
  attr(dat, "object_name") <- deparse(substitute(x), width.cutoff = 500)
  dat
}



#' @importFrom insight get_parameters
#' @rdname hdi
#' @export
hdi.stanreg <- function(x, ci = .89, effects = c("fixed", "random", "all"), parameters = NULL, verbose = TRUE, ...) {
  effects <- match.arg(effects)
  out <- .compute_interval_stanreg(x, ci, effects, parameters, verbose, fun = "hdi")
  attr(out, "object_name") <- deparse(substitute(x), width.cutoff = 500)
  out
}



#' @rdname hdi
#' @export
hdi.brmsfit <- function(x, ci = .89, effects = c("fixed", "random", "all"), component = c("conditional", "zi", "zero_inflated", "all"), parameters = NULL, verbose = TRUE, ...) {
  effects <- match.arg(effects)
  component <- match.arg(component)
  out <- .compute_interval_brmsfit(x, ci, effects, component, parameters, verbose, fun = "hdi")
  attr(out, "object_name") <- deparse(substitute(x), width.cutoff = 500)
  out
}


#' @rdname hdi
#' @export
hdi.BFBayesFactor <- function(x, ci = .89, verbose = TRUE, ...) {
  out <- hdi(insight::get_parameters(x), ci = ci, verbose = verbose, ...)
  attr(out, "object_name") <- deparse(substitute(x), width.cutoff = 500)
  out
}


#' @keywords internal
.hdi <- function(x, ci = .89, verbose = TRUE) {
  check_ci <- .check_ci_argument(x, ci, verbose)

  if (!is.null(check_ci)) {
    return(check_ci)
  }

  x_sorted <- unname(sort.int(x, method = "quick")) # removes NA/NaN, but not Inf
  window_size <- ceiling(ci * length(x_sorted)) # See https://github.com/easystats/bayestestR/issues/39

  if (window_size < 2) {
    if (verbose) {
      warning("`ci` is too small or x does not contain enough data points, returning NAs.")
    }
    return(data.frame(
      "CI" = ci * 100,
      "CI_low" = NA,
      "CI_high" = NA
    ))
  }

  nCIs <- length(x_sorted) - window_size

  if (nCIs < 1) {
    if (verbose) {
      warning("`ci` is too large or x does not contain enough data points, returning NAs.")
    }
    return(data.frame(
      "CI" = ci * 100,
      "CI_low" = NA,
      "CI_high" = NA
    ))
  }

  ci.width <- sapply(1:nCIs, function(.x) x_sorted[.x + window_size] - x_sorted[.x])

  # find minimum of width differences, check for multiple minima
  min_i <- which(ci.width == min(ci.width))
  n_candies <- length(min_i)

  if (n_candies > 1) {
    if (any(diff(sort(min_i)) != 1)) {
      if (verbose) {
        warning("Identical densities found along different segments of the distribution, choosing rightmost.", call. = FALSE)
      }
      min_i <- max(min_i)
    } else {
      min_i <- floor(mean(min_i))
    }
  }

  data.frame(
    "CI" = ci * 100,
    "CI_low" = x_sorted[min_i],
    "CI_high" = x_sorted[min_i + window_size]
  )
}
