#' Compare multiple inputs or SHAs using `sha_compare()`
#'
#' Runs `sha_compare()` over a list of data inputs (and optional argument
#' lists) and aggregates the results. When `parallel == "furrr"` both loops
#' use `furrr::future_map` so evaluations run in parallel. Library
#' directories are created once and reused across iterations so packages are
#' installed a single time.
#'
#' @param repo GitHub repo specification ("owner/pkg").
#' @param sha_old Base commit SHA/branch/tag.
#' @param sha_new Character vector of commit SHAs/branches/tags to test.
#' @param inputs List of data objects passed as the `data` argument.
#' @param args_list Optional list of lists providing extra arguments for each
#'   input. Elements are recycled if shorter than `inputs`.
#' @param pkg Name of the package (defaults to `basename(repo)`).
#' @param entry_fun Name of exported function to invoke.
#' @param lib_old Path to library for the old version. Created if `NULL`.
#' @param lib_new Path to library for the new version. Created if `NULL`.
#' @param install Logical, whether to install the packages on the first
#'   iteration. When `TRUE`, [sha_install_versions()] installs the
#'   packages before entering the loops and subsequent calls reuse the
#'   libraries.
#' @param quiet Logical, passed to `sha_compare()`.
#' @param parallel Either "purrr" (serial) or "furrr" (parallel).
#' @param diff_fun Diff function passed to `sha_compare()`.
#' @param diff_args List of additional arguments passed to `diff_fun`.
#' @return A tibble with columns `input`, `sha_new`, `passed`, `diff` and
#'   `result`.
#' @export
sha_compare_many <- function(repo, sha_old, sha_new,
                             inputs, args_list = NULL,
                             pkg = basename(repo),
                             entry_fun = "main",
                             lib_old = NULL, lib_new = NULL,
                             install = TRUE, quiet = TRUE,
                             parallel = c("purrr", "furrr"),
                             diff_fun = waldo::compare,
                             diff_args = list()) {
  parallel <- match.arg(parallel)

  mapper <- if (parallel == "furrr") furrr::future_map else purrr::map

  if (install) {
    libs <- sha_install_versions(
      repo = repo,
      sha_old = sha_old,
      sha_new = sha_new[1],
      lib_old = lib_old,
      lib_new = lib_new,
      quiet = quiet
    )
    lib_old <- libs$lib_old
    lib_new <- libs$lib_new
    install <- FALSE
  } else {
    if (is.null(lib_old)) lib_old <- tempfile("regressr_old_")
    if (is.null(lib_new)) lib_new <- tempfile("regressr_new_")
    dir.create(lib_old, recursive = TRUE, showWarnings = FALSE)
    dir.create(lib_new, recursive = TRUE, showWarnings = FALSE)
  }

  if (is.null(args_list)) {
    args_list <- replicate(length(inputs), list(), simplify = FALSE)
  }

  args_list <- rep(args_list, length.out = length(inputs))
  
  results <- mapper(
    seq_along(inputs),
    function(i) {
      extra <- args_list[[i]]
      if (!is.list(extra)) extra <- list()

      mapper(
        seq_along(sha_new),
        function(j) {
          do.call(
            sha_compare,
            c(
              list(
                repo       = repo,
                sha_old    = sha_old,
                sha_new    = sha_new[j],
                pkg        = pkg,
                entry_fun  = entry_fun,
                data       = inputs[[i]],
                lib_old    = lib_old,
                lib_new    = lib_new,
                install    = install && i == 1 && j == 1,
                quiet      = quiet,
                diff_fun   = diff_fun,
                diff_args  = diff_args
              ),
              extra
            )
          )
        }
      )
    }
  )

  results <- purrr::flatten(results)

  tibble::tibble(
    input = rep(seq_along(inputs), each = length(sha_new)),
    sha_new = rep(sha_new, times = length(inputs)),
    passed = vapply(results, function(x) x$passed, logical(1)),
    diff = lapply(results, "[[", "diff"),
    result = results
  )
}
