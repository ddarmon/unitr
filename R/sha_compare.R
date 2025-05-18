#' Compare outputs between two SHAs of a GitHub repository
#'
#' @param repo GitHub repo specification ("owner/pkg").
#' @param sha_old Character string; base commit SHA/branch/tag.
#' @param sha_new Character string; commit SHA/branch/tag to test.
#' @param entry_fun Name of exported function to invoke (default "main").
#' @param data Data frame or list of arguments passed to `entry_fun`.
#' @param diff_fun Function used to diff objects (default `waldo::compare`).
#' @return A list with elements `passed`, `diff`, `old`, `new`.
#' @export
sha_compare <- function(repo, sha_old, sha_new,
                        entry_fun = "main",
                        data = NULL,
                        diff_fun = waldo::compare) {
  stopifnot(requireNamespace("pak", quietly = TRUE))
  stopifnot(requireNamespace("waldo", quietly = TRUE))
  stopifnot(requireNamespace("withr", quietly = TRUE))

  lib_old <- tempfile("unitr_old_")
  lib_new <- tempfile("unitr_new_")
  dir.create(lib_old, recursive = TRUE)
  dir.create(lib_new, recursive = TRUE)

  pak::pkg_install(paste0(repo, "@", sha_old), lib = lib_old, ask = FALSE)
  pak::pkg_install(paste0(repo, "@", sha_new), lib = lib_new, ask = FALSE)

  run_entry <- function(lib) {
    withr::with_libpaths(lib, action = "prefix", {
      pkg <- basename(repo)
      fun <- get(entry_fun, envir = asNamespace(pkg))
      if (is.null(data)) {
        fun()
      } else if (is.data.frame(data) || !is.list(data)) {
        fun(data)
      } else {
        do.call(fun, data)
      }
    })
  }

  old_res <- run_entry(lib_old)
  new_res <- run_entry(lib_new)

  diff <- diff_fun(old_res, new_res)
  passed <- length(diff) == 0L

  structure(list(passed = passed,
                 diff = diff,
                 old = old_res,
                 new = new_res),
            class = "unitr_result")
}

#' @export
print.unitr_result <- function(x, ...) {
  if (x$passed) {
    cat("\u2714 Objects identical\n")
  } else {
    cat("\u2716 Differences detected:\n")
    cat(paste(x$diff, collapse = "\n"), "\n")
  }
}

