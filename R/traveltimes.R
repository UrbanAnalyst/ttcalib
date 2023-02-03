
#' Estimate travel times between all Uber movement polygons
#'
#' @param graph A \pkg{dodgr} graph returned from \link{ttcalib_streetnet}.
#' @param geodata A `data.frame` returned from \link{ttcalib_geodata}.
#' @param uberdata A `data.frame` returned from \link{ttcalib_uberdata}.
#' @return A 'data.frame' with columns of \pkg{m4ra} estimates of travel times
#' and corresponding empirical values from Uber movement data.
#' @export

ttcalib_traveltimes <- function (graph, geodata, uberdata) {

    uberdata <- filter_uberdata (uberdata, geodata)

    v <- dodgr::dodgr_vertices (graph)

    from <- unique (uberdata [, c ("sourceid", "src_x", "src_y")])
    index <- dodgr::match_pts_to_verts (v, from [, c ("src_x", "src_y")])
    from$osm_id <- v$id [index]
    from <- from [order (from$sourceid), ]

    to <- unique (uberdata [, c ("dstid", "dst_x", "dst_y")])
    index <- dodgr::match_pts_to_verts (v, to [, c ("dst_x", "dst_y")])
    to$osm_id <- v$id [index]
    to <- to [order (to$dstid), ]

    tmat <- m4ra::m4ra_times_single_mode (
        graph,
        from = from$osm_id,
        to = to$osm_id
    )
    rownames (tmat) <- from$sourceid
    colnames (tmat) <- to$dstid

    # Then join 'uberdata' travel time estimates to 'tmat' values:
    umat <- array (NA, dim = dim (tmat))
    index_from <- match (uberdata$sourceid, rownames (tmat))
    index_to <- match (uberdata$dstid, colnames (tmat))
    index <- index_from + nrow (umat) * (index_to - 1)
    umat [index] <- uberdata$mean_travel_time

    out <- data.frame (
        m4ra = as.vector (tmat) / 60,
        uber = as.vector (umat) / 60
    )

    index <- which (!is.na (out$m4ra) & !is.na (out$uber))
    return (out [index, ])
}


# Not all area IDs in uberdata are in the geojson file, so reduce only to those
# with geometries. Also join geometrical centroids on to uberdata.
filter_uberdata <- function (uberdata, geodata) {

    uberdata <- uberdata [which (uberdata$sourceid %in% geodata$ID &
        uberdata$dstid %in% geodata$ID), ]

    uberdata$src_x <- geodata$x [match (uberdata$sourceid, geodata$ID)]
    uberdata$src_y <- geodata$y [match (uberdata$sourceid, geodata$ID)]
    uberdata$dst_x <- geodata$x [match (uberdata$dstid, geodata$ID)]
    uberdata$dst_y <- geodata$y [match (uberdata$dstid, geodata$ID)]

    return (uberdata)
}
