
#' Read Uber Movement data and filter to defined time limits.
#'
#' Currently hard-coded to Brussels data only.
#'
#' @param path Path to directory containing Uber movement data.
#' @param hours A vector of two values defining the range of hours for data to
#' be filtered. Default of `NULL` returns aggregate of all hours without
#' filtering.
#' @return A 'data.frame' of Uber Movement estimates of travel times.
#' @export
ttcalib_uberdata <- function (path, hours = NULL) {

    if (!is.null (hours)) {
        stopifnot (is.numeric (hours))
        stopifnot (length (hours) == 2L)
    }

    flist <- list.files (path, full.names = TRUE)
    f <- grep ("brussels.*Aggregate", flist, value = TRUE)

    # suppress no visible binding notes:
    hod <- sourceid <- dstid <- mean_travel_time <- NULL

    x <- readr::read_csv (f)
    if (!is.null (hours)) {
        x <- dplyr::filter (x, hod %in% 7:10)
    }
    x <- dplyr::group_by (x, sourceid, dstid) |>
        dplyr::summarise (mean_travel_time = mean (mean_travel_time))

    return (x)
}
