
#' Read geometries for chosen citie from Uber Movement data.
#'
#' Currently hard-coded to Brussels data only.
#'
#' @param path Path to directory containing Uber movement data.
#' @return A 'data.frame' with centroids of polygons used to aggregate movement
#' data.
#' @export
ttcalib_geodata <- function (path) {

    f <- file.path (path, "brussels_statisticaldistrict.json")
    stopifnot (file.exists (f))

    s <- sf::st_read (f)
    # have to lapply for st_cast to take first element of actual multipolygons
    s$geometry <- sf::st_sfc (lapply (s$geometry, function (i)
        sf::st_cast (i, "POLYGON"))) |>
        sf::st_centroid ()
    xy <- sf::st_coordinates (s$geometry)
    s <- data.frame (
        ID = s$ID,
        x = xy [, 1],
        y = xy [, 2]
    )

    return (s)
}
