context("bayesfactor_*")

# bayesfactor_savagedickey ------------------------------------------------

test_that("bayesfactor_savagedickey", {
  set.seed(444)
  Xprior <- rnorm(1000)
  Xposterior <- rnorm(1000, 0.7, 0.2)

  bfsd <- bayestestR::bayesfactor_savagedickey(Xposterior, prior = Xprior, hypothesis = 0, direction = 0)
  testthat::expect_equal(log(bfsd$BF), 3.7, tolerance = 0.1)

  bfsd <- bayestestR::bayesfactor_savagedickey(Xposterior, prior = Xprior, hypothesis = 0, direction = 1)
  testthat::expect_equal(log(bfsd$BF), 4.3, tolerance = 0.1)

  bfsd <- bayestestR::bayesfactor_savagedickey(Xposterior, prior = Xprior, hypothesis = 0, direction = -1)
  testthat::expect_equal(log(bfsd$BF), -2.5, tolerance = 0.1)

  bfsd <- bayestestR::bayesfactor_savagedickey(Xposterior, prior = Xprior, hypothesis = 1, direction = 0)
  testthat::expect_equal(log(bfsd$BF), -0.8, tolerance = 0.1)

  testthat::expect_warning(bfsd <- bayestestR::bayesfactor_savagedickey(Xposterior))
  testthat::expect_equal(log(bfsd$BF), 0, tolerance = 0.1)

  library(rstanarm)
  set.seed(333)
  junk <- capture.output(model <- stan_glm(extra ~ group, data = sleep))
  bfsd <- bayestestR::bayesfactor_savagedickey(model)
  testthat::expect_equal(log(bfsd$BF), c(-2.69, -0.14), tolerance = 0.2)

  # SKIP FOR TRAVIS
  # library(brms)
  # brms_mixed_6 <- insight::download_model("brms_mixed_6")
  # set.seed(222)
  # bfsd <- bayesfactor_savagedickey(brms_mixed_6, effects = "fixed")
  # testthat::expect_equal(log(bfsd$BF), c(-6.0, -5.8, 0.7, -2.7, -7.4), tolerance = 0.2)
  #
  # brms_mixed_1 <- insight::download_model("brms_mixed_1")
  # testthat::expect_error(bayesfactor_savagedickey(brms_mixed_1))
})


# bayesfactor_models ------------------------------------------------------

set.seed(444)

mo1 <- lme4::lmer(Sepal.Length ~ (1 | Species), data = iris)
mo2 <- lme4::lmer(Sepal.Length ~ Petal.Length + (1 | Species), data = iris)
mo3 <- lme4::lmer(Sepal.Length ~ Petal.Length + (Petal.Length | Species), data = iris)
mo4 <- lme4::lmer(Sepal.Length ~ Petal.Length + Petal.Width + (Petal.Length | Species), data = iris)
mo4_e <- lme4::lmer(Sepal.Length ~ Petal.Length + Petal.Width + (Petal.Length | Species), data = iris[-1, ])

# both uses of denominator
BFM1 <- bayestestR::bayesfactor_models(mo2, mo3, mo4, mo1, denominator = 4)
BFM2 <- bayestestR::bayesfactor_models(mo2, mo3, mo4, denominator = mo1)
BFM3 <- bayestestR::bayesfactor_models(mo2, mo3, mo4, mo1, denominator = mo1)


brms_4bf_1 <- insight::download_model("brms_4bf_1")
brms_4bf_2 <- insight::download_model("brms_4bf_2")
brms_4bf_3 <- insight::download_model("brms_4bf_3")
brms_4bf_4 <- insight::download_model("brms_4bf_4")
brms_4bf_5 <- insight::download_model("brms_4bf_5")

# set.seed(444)
# library(brms)
# brms_models <- suppressWarnings(bayestestR::bayesfactor_models(brms_4bf_1,brms_4bf_2,brms_4bf_3, brms_4bf_4, brms_4bf_5))
#
# library(rstanarm)
# junk <- capture.output(stan_bf_0 <- stan_glm(Sepal.Length ~ 1, data = iris,
#                                              diagnostic_file = file.path(tempdir(), "df0.csv")))
# junk <- capture.output(stan_bf_1 <- stan_glm(Sepal.Length ~ Species, data = iris,
#                                              diagnostic_file = file.path(tempdir(), "df1.csv")))

# test_that("bayesfactor_models", {
#   # brms
#   testthat::expect_warning(bayestestR::bayesfactor_models(brms_4bf_1,brms_4bf_2))
#   testthat::expect_is(brms_models,"bayesfactor_models")
#   testthat::expect_equal(log(brms_models$BF),c(0, 68.5, 102.5, 128.6, 128.8), tolerance = 0.1)
#
#   # rstanarm
#   testthat::expect_warning(bayestestR::bayesfactor_models(stan_bf_0,stan_bf_1))
#   stan_models <- suppressWarnings(bayestestR::bayesfactor_models(stan_bf_0,stan_bf_1))
#   testthat::expect_is(stan_models,"bayesfactor_models")
#   testthat::expect_equal(log(stan_models$BF),c(0, 65.19), tolerance = 0.1)
#
#   ## BIC
#   testthat::expect_equal(BFM1,BFM2)
#   testthat::expect_equal(BFM1,BFM3)
#
#   # only on same data!
#   testthat::expect_error(bayestestR::bayesfactor_models(mo1, mo2, mo4_e))
#
#
#   # update models
#   testthat::expect_equal(log(update(BFM2,subset = c(1,2))$BF),c(0,57.3,54.52), tolerance = 0.1)
#
#   # update reference
#   testthat::expect_equal(log(update(BFM2,reference = 1)$BF),c(0,-2.8,-6.2,-57.4),tolerance = 0.1)
# })



# bayesfactor_inclusion ---------------------------------------------------

test_that("bayesfactor_inclusion", {
  # BayesFactor
  ToothGrowth$dose <- as.factor(ToothGrowth$dose)
  BF_ToothGrowth <- BayesFactor::anovaBF(len ~ dose * supp, ToothGrowth)
  testthat::expect_equal(
    bayestestR::bayesfactor_inclusion(BF_ToothGrowth),
    bayestestR::bayesfactor_inclusion(bayestestR::bayesfactor_models(BF_ToothGrowth))
  )

  # with random effects in all models:
  testthat::expect_true(is.nan(bayestestR::bayesfactor_inclusion(BFM1)[1, "BF.Inc"]))

  # + match_models
  bfinc_matched <- bayestestR::bayesfactor_inclusion(BFM1, match_models = TRUE)
  testthat::expect_equal(bfinc_matched$P.Inc.prior, c(1, 0.25, 0.5, 0.25), tolerance = 0.1)
  testthat::expect_equal(bfinc_matched$P.Inc.posterior, c(1, 0.94, 0.06, 0), tolerance = 0.1)
  testthat::expect_equal(log(bfinc_matched$BF.Inc), c(NaN, 57.37, -2.82, -5.25), tolerance = 0.1)
})
