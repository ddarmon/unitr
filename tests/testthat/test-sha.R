library(testthat)
library(unitr)

test_that("Outputs are identical across SHAs", {
  skip_if_offline()
  # Replace with your own reproducible input fixture
  input <- data.frame(x = 1:3)

  res <- sha_compare(
    repo = "org/pkg",
    sha_old = Sys.getenv("SHA_BASE", "main"),
    sha_new = Sys.getenv("SHA_NEW", "HEAD"),
    entry_fun = "main",
    data = input
  )

  expect_true(res$passed, info = paste(res$diff, collapse = "\n"))
})

