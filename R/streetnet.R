
#' Load an 'SC' street network, weight for motorcar routing, and optionally
#' calculate centrality.
#'
#' @param path Path to 'SC'-format file containing street network data.
#' @param centrality If `TRUE`, calculate network centrality on all graph edges.
#' Load an 'SC' street network, weight for motorcar routing, and calculate
#' centrality.
#' @param penalty_traffic_lights Time penalty for waiting at traffic lights (in
#' seconds).
#' @param penalty_turn Time penalty for turning across oncoming traffic.
#' @return Network with centrality estimates on each edge.
#' @export
ttcalib_streetnet <- function (path, centrality = FALSE,
    penalty_traffic_lights = 1, penalty_turn = 2) {

    wp <- write_wt_profile (penalty_traffic_lights, penalty_turn)

    stopifnot (file.exists (path))
    net <- readRDS (path)

    message (cli::symbol$play,
        cli::col_green (" Weighting network for routing "),
        appendLF = FALSE)
    graph <- dodgr::weight_streetnet (
        net,
        wt_profile = "motorcar",
        wt_profile_file = wp,
        turn_penalty = TRUE
    )
    ps <- attr (graph, "px")
    while (ps$is_alive ()) ps$wait ()
    message ("\r", cli::col_green (cli::symbol$tick,
        " Weighted network for routing   "))

    if (centrality) {

        graph <- dodgr::dodgr_deduplicate_graph (graph)

        message (cli::symbol$play,
            cli::col_green (" Calculating network centrality "),
            appendLF = FALSE)
        graph <- dodgr::dodgr_centrality (graph)
        message ("\r", cli::col_green (cli::symbol$tick,
            " Calculated network centrality  "))
    }

    return (graph)
}

write_wt_profile <- function (traffic_lights = 1, turn = 2) {

    f <- file.path (tempdir (), "wt_profile.json")
    dodgr::write_dodgr_wt_profile (f)

    w <- readLines (f)

    p <- grep ("\"penalties\"\\:\\s", w)
    m <- grep ("\"motorcar\"", w)
    m <- m [which (m > p) [1]]
    tl <- grep ("\"traffic_lights\"", w)
    tl <- tl [which (tl > m) [1]]
    tu <- grep ("\"turn\"", w)
    tu <- tu [which (tu > m) [1]]

    w [tl] <- gsub ("[0-9]+,$", paste0 (traffic_lights, ","), w [tl])
    w [tu] <- gsub ("[0-9]+,$", paste0 (turn, ","), w [tu])

    writeLines (w, f)

    return (f)
}
