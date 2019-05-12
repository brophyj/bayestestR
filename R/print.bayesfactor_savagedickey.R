#' @export
print.bayesfactor_savagedickey <- function(x, digits = 2, log = FALSE, ...) {
  BFE <- x
  hypothesis <- attr(BFE, "hypothesis")

  colnames(BFE) <- "Bayes Factor"

  if (log) {
    BFE[[1]] <- log(BFE[[1]])
    colnames(BFE) <- "Bayes Factor (log)"
  }

  insight::print_color("# Bayes Factor (Savage-Dickey density ratio)\n\n", "blue")

  print.data.frame(BFE, digits = digits)
  cat("---\n")
  cat(paste0("Test Value: ", round(hypothesis,digits), "\n"))
  invisible(x)
}