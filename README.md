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
