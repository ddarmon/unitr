library(testthat)
library(regressr)


test_that("sha_compare_many runs", {
  skip_if_offline()
  inputs <- list(data.frame(x = 1:3), data.frame(x = 3:1))
  res <- sha_compare_many(
    repo = "org/pkg",
    sha_old = Sys.getenv("SHA_BASE", "main"),
    sha_new = Sys.getenv("SHA_NEW", "HEAD"),
    inputs = inputs,
    pkg = "pkg",
    entry_fun = "main",
    parallel = "purrr"
  )
  expect_true(all(res$passed))
})
