# regressr

Minimal helpers for regression testing across GitHub commit SHAs.

This package installs two versions of a package from GitHub and compares the
results of running a specified function. It is useful for detecting behavioural
changes between commits in continuous integration and testthat workflows.

## Installation

Use `pak` to install from GitHub:

```r
pak::pkg_install("ddarmon/regressr")
```

## Example

```r
library(regressr)

# Install the two versions once
libs <- sha_install_versions(
  repo = "org/pkg",
  sha_old = "abc123",
  sha_new = "def456"
)

res <- sha_compare(
  repo = "org/pkg",
  sha_old = "abc123",
  sha_new = "def456",
  lib_old = libs$lib_old,
  lib_new = libs$lib_new,
  install = FALSE
)

if (res$passed) {
  print("Objects identical")
} else {
  print(res$diff)
}
```

Installing once and reusing the library directories avoids repeated downloads
and speeds up comparisons.

## `sha_compare_many()`

Instead of writing the loop yourself you can use `sha_compare_many()` to run
the comparison across a list of inputs. Parallel evaluation via **furrr** is
supported by setting `parallel = "furrr"`.

```r
inputs <- list(df1, df2)
args <- list(list(threshold = 0.1), list(threshold = 0.2))

res <- sha_compare_many(
  repo = "org/pkg",
  sha_old = "abc123",
  sha_new = "def456",
  inputs = inputs,
  args_list = args,
  lib_old = libs$lib_old,
  lib_new = libs$lib_new,
  parallel = "purrr"
)
```

`res` contains a tibble summarising pass/fail status for each input.

## Command line interface

After installing the package you can run comparisons from the command line:

```sh
Rscript $(R -e 'cat(system.file("scripts", "regressr_cli.R", package="regressr"))') \
  --repo org/pkg --base main --sha def456 --input data1.rds --input data2.rds
```
