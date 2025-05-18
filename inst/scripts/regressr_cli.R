#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(optparse)
  library(regressr)
})

option_list <- list(
  make_option(c("-r", "--repo"), type = "character", help = "GitHub repo, owner/pkg"),
  make_option(c("-b", "--base"), type = "character", default = "main",
              help = "Base SHA [default %default]"),
  make_option(c("-s", "--sha"), type = "character", action = "append",
              help = "SHA(s) to compare"),
  make_option(c("-i", "--input"), type = "character", action = "append",
              help = "Input data file (RDS). Can be repeated."),
  make_option(c("-p", "--parallel"), type = "character", default = "purrr",
              help = "Use purrr or furrr [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))

if (is.null(opt$repo) || is.null(opt$sha) || is.null(opt$input)) {
  print_help(OptionParser(option_list = option_list))
  quit(status = 1)
}

inputs <- lapply(opt$input, readRDS)

res <- sha_compare_many(
  repo = opt$repo,
  sha_old = opt$base,
  sha_new = opt$sha,
  inputs = inputs,
  parallel = opt$parallel
)

print(res)
