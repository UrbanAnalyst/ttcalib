
#' Read geometries for chosen city from Uber Movement data.
#'
#' Currently hard-coded to Brussels or Santiago data only.
#'
#' @param path Path to directory containing Uber movement data.
#' @param city One of "brussels" or "santiago" (case-insensitive).
#' @return A 'data.frame' with centroids of polygons used to aggregate movement
#' data.
#' @export
ttcalib_geodata <- function (path, city = "santiago") {

    city <- match.arg (tolower (city), c ("brussels", "santiago"))

    f <- list.files (path, pattern = "\\.json$", full.names = TRUE)
    f <- grep (city, f, value = TRUE, ignore.case = TRUE)

    stopifnot (length (f) == 1L)

    s <- sf::st_read (f)
    # have to lapply for st_cast to take first element of actual multipolygons
    s$geometry <- sf::st_sfc (lapply (s$geometry, function (i)
        sf::st_cast (i, "POLYGON"))) |>
        sf::st_centroid ()
    xy <- sf::st_coordinates (s$geometry)
    s <- data.frame (
        ID = s$MOVEMENT_ID,
        x = xy [, 1],
        y = xy [, 2]
    )

    return (s)
}
