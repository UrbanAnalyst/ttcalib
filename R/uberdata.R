
#' Read Uber Movement data and filter to defined time limits.
#'
#' Currently hard-coded to Brussels data only.
#'
#' @param path Path to directory containing Uber movement data.
#' @param city One of "brussels" or "santiago" (case-insensitive).
#' @param hours A vector of two values defining the range of hours for data to
#' be filtered. Default of `NULL` returns aggregate of all hours without
#' filtering.
#' @return A 'data.frame' of Uber Movement estimates of travel times.
#' @export
ttcalib_uberdata <- function (path, city = "santiago", hours = NULL) {

    if (!is.null (hours)) {
        stopifnot (is.numeric (hours))
        stopifnot (length (hours) == 2L)
    }
    city <- match.arg (tolower (city), c ("brussels", "santiago"))

    flist <- list.files (path, full.names = TRUE)
    f <- grep (paste0 (city, ".*aggregate"), flist, value = TRUE, ignore.case = TRUE)

    stopifnot (length (f) == 1L)

    # suppress no visible binding notes:
    hod <- sourceid <- dstid <- mean_travel_time <- NULL

    x <- readr::read_csv (f, progress = FALSE, show_col_types = FALSE)
    if (!is.null (hours)) {
        x <- dplyr::filter (x, hod %in% seq (hours [1], hours [2]))
    }
    x <- dplyr::group_by (x, sourceid, dstid) |>
        dplyr::summarise (mean_travel_time = mean (mean_travel_time))

    return (x)
}
