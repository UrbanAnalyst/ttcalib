
#' Load an 'SC' street network, weight for motorcar routing, and calculate
#' centralityl.
#'
#' @param path Path to 'SC'-format file containing street network data.
#' @return Network with centrality estimates on each edge.
#' @export
ttcalib_centrality <- function (path) {

    stopifnot (file.exists (path))
    net <- readRDS (path)

    message (cli::symbol$play,
        cli::col_green (" Weighting network for routing "),
        appendLF = FALSE)
    graph <- dodgr::weight_streetnet (net, wt_profile = "motorcar", turn_penalty = TRUE)
    ps <- attr (graph, "px")
    while (ps$is_alive ()) ps$wait ()
    message ("\r", cli::col_green (cli::symbol$tick,
        " Weighted network for routing   "))

    graph <- dodgr::dodgr_deduplicate_graph (graph)

    message (cli::symbol$play,
        cli::col_green (" Calculating network centrality "),
        appendLF = FALSE)
    graph <- dodgr::dodgr_centrality (graph)
    message ("\r", cli::col_green (cli::symbol$tick,
        " Calculated network centrality  "))

    return (graph)
}
