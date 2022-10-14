
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
#' @param dist_threshold Threshold used for centrality calculations (in metres);
#' see documentation for \pkg{dodgr} function, 'dodgr_centrality' for
#' information.
#' @return Network with centrality estimates on each edge.
#' @export
ttcalib_streetnet <- function (path, centrality = FALSE,
    penalty_traffic_lights = 8, penalty_turn = 7.5,
    dist_threshold = 10000) {

    wp <- write_wt_profile (penalty_traffic_lights, penalty_turn)

    stopifnot (file.exists (path))
    net <- readRDS (path)

    message (cli::symbol$play,
        cli::col_green (" Weighting network for routing "),
        appendLF = FALSE)
    utils::flush.console ()
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
        utils::flush.console ()
        graph <- dodgr::dodgr_centrality (
            graph,
            dist_threshold = dist_threshold
        )
        message ("\r", cli::col_green (cli::symbol$tick,
            " Calculated network centrality  "))

        attr (graph, "dist_threshold") <- dist_threshold
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

    w [tl] <- gsub (
        "[0-9]+,$",
        paste0 (traffic_lights, ","),
        w [tl],
        fixed = TRUE
    )
    w [tu] <- gsub (
        "[0-9]+,$",
        paste0 (turn, ","),
        w [tu],
        fixed = TRUE
    )

    writeLines (w, f)

    return (f)
}

#' Weight an 'SC' street network by a range of traffic light and turn penalties,
#' and locally save the results.
#'
#' This function produces an array of differently-weighted streetnets, each
#' locally saved to a uniquely-named file. The resultant graphs are saved with
#' the \pkg{fst} package, which removes the necessary attributes of the
#' resultant `data.frame` objects. These must be manually restored prior to
#' submitting to \link{ttcalib_traveltimes}. Required attributes are:
#' \itemize{
#' \item "left_side", passed as same parameter to \pkg{dodgr} function
#' `wt_streetnet`.
#' \item "wt_profile", passed as same parameter to \pkg{dodgr} function
#' `wt_streetnet`, and which should generally be "motorcar" here.
#' \item "turn_penalty", passed as same parameter to \pkg{dodgr} function
#' `wt_streetnet`, and able to be recovered from names of resultant files, as
#' value denoted 'tp'.
#' \item "dist_threshold", passed as same parameter to \pkg{dodgr} function
#' `dodgr_centrality`, and able to be recovered from names of resultant files,
#' as value denoted 'dlim'.
#' }
#'
#' @note This function will generally take a very long time - hours to days - to
#' run.
#'
#' @inheritParams ttcalib_streetnet
#' @export
ttcalib_streetnet_batch <- function (path,
                                     centrality = FALSE,
                                     penalty_traffic_lights = 1:10,
                                     penalty_turn = 1:10,
                                     dist_threshold = 10000) {

   penalties <- expand.grid (
        traffic_lights = penalty_traffic_lights,
        turn = penalty_turn
    )

    for (p in seq_len (nrow (penalties))) {

        p_tl <- penalties$traffic_lights [p]
        p_tu <- penalties$turn [p]

        msg <- paste0 (
            cli::col_green ("Traffic lights: "),
            cli::col_red (p_tl),
            cli::col_green ("; Turn: "),
            cli::col_red (p_tu)
        )
        cli::cli_h2 (msg)

        graph_p <- ttcalib_streetnet (
            path,
            centrality = centrality,
            penalty_traffic_lights = p_tl,
            penalty_turn = p_tu
        )

        fname_base <- basename (path)
        fname_path <- dirname (path)

        p_tl <- round (p_tl * 10)
        p_tu <- round (p_tu * 10)

        fname_base <- gsub (
            "\\.Rds$",
            paste0 ("_tl", p_tl, "_tu", p_tu, "_dlim", dist_threshold, ".Rds"),
            fname_base
        )
        fname <- file.path (fname_path, fname_base)

        fst::write_fst (graph_p, fname)
    }
}
