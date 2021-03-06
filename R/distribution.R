#' Empirical Distributions
#'
#' Generate a sequence of n-quantiles, i.e., a sample of size \code{n} with a near-perfect distribution.
#'
#' @param type Can be \code{"normal"} (default), \code{"cauchy"}, \code{"poisson"}, \code{"chisquared"}, \code{"uniform"}, \code{"student"} or \code{"beta"}.
#' @param random Generate near-perfect or random (simple wrappers for the base R \code{r*} functions) distributions.
#' @param ... Arguments passed to or from other methods.
#'
#' @examples
#' library(bayestestR)
#' x <- distribution(n = 10)
#' plot(density(x))
#' @export
distribution <- function(type = "normal", ...) {
  switch(
    match.arg(arg = type, choices = c("normal", "cauchy", "poisson", "student", "chisquared", "uniform", "beta")),
    "normal" = distribution_normal(...),
    "cauchy" = distribution_cauchy(...),
    "poisson" = distribution_poisson(...),
    "student" = distribution_student(...),
    "chisquared" = distribution_chisquared(...),
    "uniform" = distribution_uniform(...),
    "beta" = distribution_beta(...),
    distribution_custom(type = type, ...)
  )
}





#' @rdname distribution
#' @inheritParams stats::rnorm
#' @importFrom stats qnorm rnorm
#' @export
distribution_normal <- function(n, mean = 0, sd = 1, random = FALSE, ...) {
  if (random) {
    stats::rnorm(n, mean, sd)
  } else {
    stats::qnorm(seq(1 / n, 1 - 1 / n, length.out = n), mean, sd, ...)
  }
}


#' @rdname distribution
#' @inheritParams stats::rcauchy
#' @importFrom stats rcauchy qcauchy
#' @export
distribution_cauchy <- function(n, location = 0, scale = 1, random = FALSE, ...) {
  if (random) {
    stats::rcauchy(n, location, scale)
  } else {
    stats::qcauchy(seq(1 / n, 1 - 1 / n, length.out = n), location, scale, ...)
  }
}


#' @rdname distribution
#' @inheritParams stats::rpois
#' @importFrom stats rpois qpois
#' @export
distribution_poisson <- function(n, lambda = 1, random = FALSE, ...) {
  if (random) {
    stats::rpois(n, lambda)
  } else {
    stats::qpois(seq(1 / n, 1 - 1 / n, length.out = n), lambda, ...)
  }
}


#' @rdname distribution
#' @inheritParams stats::rt
#' @importFrom stats rt qt
#' @export
distribution_student <- function(n, df, ncp, random = FALSE, ...) {
  if (random) {
    stats::rt(n, df, ncp)
  } else {
    stats::qt(seq(1 / n, 1 - 1 / n, length.out = n), df, ncp, ...)
  }
}


#' @rdname distribution
#' @inheritParams stats::rchisq
#' @importFrom stats rchisq qchisq
#' @export
distribution_chisquared <- function(n, df, ncp = 0, random = FALSE, ...) {
  if (random) {
    stats::rchisq(n, df, ncp)
  } else {
    stats::qchisq(seq(1 / n, 1 - 1 / n, length.out = n), df, ncp, ...)
  }
}


#' @rdname distribution
#' @inheritParams stats::runif
#' @importFrom stats runif qunif
#' @export
distribution_uniform <- function(n, min = 0, max = 1, random = FALSE, ...) {
  if (random) {
    stats::runif(n, min, max)
  } else {
    stats::qunif(seq(1 / n, 1 - 1 / n, length.out = n), min, max, ...)
  }
}




#' @rdname distribution
#' @inheritParams stats::rbeta
#' @importFrom stats rbeta qbeta
#' @export
distribution_beta <- function(n, shape1, shape2, ncp = 0, random = FALSE, ...) {
  if (random) {
    stats::rbeta(n, shape1, shape2, ncp = ncp)
  } else {
    stats::qbeta(seq(1 / n, 1 - 1 / n, length.out = n), shape1, shape2, ncp = ncp, ...)
  }
}


#' @rdname distribution
#' @inheritParams distribution
#' @export
distribution_custom <- function(n, type = "norm", ..., random = FALSE) {
  if (random) {
    f <- match.fun(paste0("r", type))
    f(n, ...)
  } else {
    f <- match.fun(paste0("q", type))
    f(seq(1 / n, 1 - 1 / n, length.out = n), ...)
  }
}




#' @rdname distribution
#' @inheritParams stats::rnorm
#' @importFrom stats qnorm
#' @export
rnorm_perfect <- function(n, mean = 0, sd = 1) {
  .Deprecated("distribution_normal")
  stats::qnorm(seq(1 / n, 1 - 1 / n, length.out = n), mean, sd)
}
