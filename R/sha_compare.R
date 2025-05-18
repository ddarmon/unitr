#' Compare outputs between two SHAs of a GitHub repository
#'
#' @param repo GitHub repo specification ("owner/pkg").
#' @param sha_old Character string; base commit SHA/branch/tag.
#' @param sha_new Character string; commit SHA/branch/tag to test.
#' @param pkg Name of the package (defaults to `basename(repo)`).
#' @param entry_fun Name of exported function to invoke (default "main").
#' @param data Data frame passed as the first argument to `entry_fun`.
#' @param lib_old Path to library for the old version. If `NULL` a
#'   temporary directory is used.
#' @param lib_new Path to library for the new version. If `NULL` a
#'   temporary directory is used.
#' @param install Logical, whether to install the package versions
#'   before running (default `TRUE`). When `TRUE`,
#'   [sha_install_versions()] installs the packages into
#'   `lib_old` and `lib_new`.
#' @param quiet Logical, whether to suppress messages from `pak::pkg_install`
#'   (default `TRUE`).
#' @param ... Additional arguments passed on to `entry_fun`.
#' @param diff_fun Function used to diff objects (default `waldo::compare`).
#' @param diff_args List of additional arguments passed to `diff_fun`.
#' @return A list with elements `passed`, `diff`, `old`, `new`.
#' @export
sha_compare <- function(repo, sha_old, sha_new,
                        pkg = basename(repo),
                        entry_fun = "main",
                        data = NULL,
                        lib_old = NULL,
                        lib_new = NULL,
                        install = TRUE,
                        quiet = TRUE, ..., 
                        diff_fun = waldo::compare, 
                        diff_args = list()) {
  stopifnot(requireNamespace("pak", quietly = TRUE))
  stopifnot(requireNamespace("waldo", quietly = TRUE))
  stopifnot(requireNamespace("withr", quietly = TRUE))

  if (install) {
    libs <- sha_install_versions(
      repo = repo,
      sha_old = sha_old,
      sha_new = sha_new,
      lib_old = lib_old,
      lib_new = lib_new,
      quiet = quiet
    )
    lib_old <- libs$lib_old
    lib_new <- libs$lib_new
  } else {
    if (is.null(lib_old)) lib_old <- tempfile("regressr_old_")
    if (is.null(lib_new)) lib_new <- tempfile("regressr_new_")
    dir.create(lib_old, recursive = TRUE, showWarnings = FALSE)
    dir.create(lib_new, recursive = TRUE, showWarnings = FALSE)
  }

  extra_args <- list(...)

  run_entry <- function(lib) {
    withr::with_libpaths(lib, action = "prefix", {
      if (pkg %in% loadedNamespaces()) unloadNamespace(pkg)
      fun <- get(entry_fun, envir = asNamespace(pkg))
      args <- if (is.null(data)) {
        extra_args
      } else if (is.data.frame(data) || !is.list(data)) {
        c(list(data), extra_args)
      } else {
        c(data, extra_args)
      }
      result <- do.call(fun, args)
      unloadNamespace(pkg)
      result
    })
  }

  message("Running ", entry_fun, " on old version...")
  old_res <- run_entry(lib_old)

  message("Running ", entry_fun, " on new version...")
  new_res <- run_entry(lib_new)

  diff <- do.call(diff_fun, c(list(old_res, new_res), diff_args))
  passed <- length(diff) == 0L

  structure(list(passed = passed,
                 diff = diff,
                 old = old_res,
                 new = new_res),
            class = "regressr_result")
}

#' @export
print.regressr_result <- function(x, ...) {
  if (x$passed) {
    cat("\u2714 Objects identical\n")
  } else {
    cat("\u2716 Differences detected:\n")
    cat(paste(x$diff, collapse = "\n"), "\n")
  }
}

