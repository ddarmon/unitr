# unitr

Minimal helpers for regression testing across GitHub commit SHAs.

This package installs two versions of a package from GitHub and compares the
results of running a specified function. It is useful for detecting behavioural
changes between commits in continuous integration and testthat workflows.

## Installation

Use `pak` to install from GitHub:

```r
pak::pkg_install("owner/unitr")
```

## Example

```r
library(unitr)

# Compare `main()` results between two SHAs of "org/pkg"
res <- sha_compare(
  repo = "org/pkg",
  sha_old = "abc123",   # base commit
  sha_new = "def456",   # comparison commit
  pkg = "pkg",
  entry_fun = "main",
  data = data.frame(x = 1:3)
)

if (res$passed) {
  print("Objects identical")
} else {
  print(res$diff)
}
```

The object returned by `sha_compare()` includes whether the objects are
identical (`passed`) as well as the two results and their diff.

## License

MIT
