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

# Directories used to install the package versions
old_lib <- tempfile("regressr_old_")
new_lib <- tempfile("regressr_new_")
dir.create(old_lib)
dir.create(new_lib)

# SHAs to compare against a baseline commit
shas <- c("def456", "ghi789")
for (i in seq_along(shas)) {
  res <- sha_compare(
    repo = "org/pkg",
    sha_old = "abc123",   # baseline commit
    sha_new = shas[i],     # comparison commit
    pkg = "pkg",
    entry_fun = "main",
    data = data.frame(x = 1:3),
    old_lib = old_lib,
    new_lib = new_lib,
    install = i == 1,      # reuse installs after first iteration
    quiet = TRUE
  )

  if (res$passed) {
    print("Objects identical")
  } else {
    print(res$diff)
  }
}
```

Reusing the library directories and setting `install = FALSE` after the first
iteration avoids downloading and installing the packages again. This speeds up
repeated comparisons and reduces unnecessary network traffic.

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
  lib_old = old_lib,
  lib_new = new_lib,
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
