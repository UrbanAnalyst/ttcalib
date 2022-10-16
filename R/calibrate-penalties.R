
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
                                     centrality = TRUE,
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

        fname_base <- basename (path)
        fname_path <- dirname (path)

        fp_tl <- round (p_tl * 10)
        fp_tu <- round (p_tu * 10)

        fname_base <- gsub (
            "\\.Rds$",
            paste0 ("_tl", fp_tl, "_tu", fp_tu, "_dlim", dist_threshold, ".Rds"),
            fname_base
        )
        fname <- file.path (fname_path, fname_base)

        if (file.exists (fname)) {
            next
        }

        msg <- paste0 (
            cli::col_green ("Traffic lights: "),
            cli::col_red (p_tl),
            cli::col_green ("; Turn: "),
            cli::col_red (p_tu)
        )
        cli::cli_h2 (msg)

        dodgr::clear_dodgr_cache ()

        graph_p <- ttcalib_streetnet (
            path,
            centrality = centrality,
            penalty_traffic_lights = p_tl,
            penalty_turn = p_tu
        )

        fst::write_fst (graph_p, fname)
    }
}
