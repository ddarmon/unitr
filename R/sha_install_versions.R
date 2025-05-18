#' Install two SHAs of a GitHub package
#'
#' Installs the `sha_old` and `sha_new` versions of a package into
#' separate library directories. Directories are created when `NULL` and
#' the paths are returned invisibly.
#'
#' @param repo GitHub repo specification ("owner/pkg").
#' @param sha_old Base commit SHA or branch/tag.
#' @param sha_new Commit SHA or branch/tag to test.
#' @param lib_old Library directory for the old version; created if `NULL`.
#' @param lib_new Library directory for the new version; created if `NULL`.
#' @param quiet Logical; suppress messages from `pak::pkg_install`.
#' @return Invisibly, a list with `lib_old` and `lib_new`.
#' @export
sha_install_versions <- function(repo, sha_old, sha_new,
                                 lib_old = NULL, lib_new = NULL,
                                 quiet = TRUE) {
  stopifnot(requireNamespace("pak", quietly = TRUE))

  if (is.null(lib_old)) lib_old <- tempfile("regressr_old_")
  if (is.null(lib_new)) lib_new <- tempfile("regressr_new_")
  dir.create(lib_old, recursive = TRUE, showWarnings = FALSE)
  dir.create(lib_new, recursive = TRUE, showWarnings = FALSE)

  install_pkgs <- function() {
    pak::pkg_install(paste0(repo, "@", sha_old),
                     lib = lib_old, ask = FALSE)
    pak::pkg_install(paste0(repo, "@", sha_new),
                     lib = lib_new, ask = FALSE)
  }

  if (quiet) {
    suppressMessages(install_pkgs())
  } else {
    install_pkgs()
  }

  invisible(list(lib_old = lib_old, lib_new = lib_new))
}
