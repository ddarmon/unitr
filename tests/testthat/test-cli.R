library(testthat)
library(regressr)
cli <- system.file("scripts", "regressr_cli.R", package = "regressr")

test_that("CLI script exists", {
  skip_if(cli == "")
  expect_true(file.exists(cli))
})
