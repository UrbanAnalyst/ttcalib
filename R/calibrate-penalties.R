
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

        fname_base <- basename (path)
        fname_path <- dirname (path)

        fp_tl <- round (p_tl * 10)
        fp_tu <- round (p_tu * 10)

        ptn <- paste0 (
            "_tl", fp_tl,
            "_tu", fp_tu,
            "_dlim", dist_threshold,
            ".Rds"
        )
        fname_base <- gsub ("\\.Rds$", ptn, fname_base)
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

#' Calculate standard error against 'uber' data for all weighted networks
#' generated via \link{ttcalib_streetnet_batch}.
#'
#' @param path_results Path to directory holding main OSM network data,
#' including a sub-directory with output of \link{ttcalib_streetnet_batch}.
#' @param path_uberdata Path to Uber movement data.
#' @inheritParams ttcalib_uberdata
#'
#' @export
ttcalib_penalties <- function (path_results, path_uberdata, city, hours = NULL) {

    requireNamespace ("pbapply")

    geodata <- ttcalib_geodata (path = path_uberdata, city = city)
    uberdata <- ttcalib_uberdata (path = path_uberdata, hours = hours, city = city)

    path_b <- find_batch_result_dir (path_results)

    flist <- list.files (
        path_b,
        full.names = TRUE,
        pattern = "\\_tl.*\\_tu.*\\_dlim.*\\.Rds"
    )

    res <- pbapply::pblapply (flist, function (f) {

        tl <- regmatches (f, regexpr ("\\_tl[0-9]+", f))
        tl <- as.integer (gsub ("^\\_tl", "", tl)) / 10
        tu <- regmatches (f, regexpr ("\\_tu[0-9]+", f))
        tu <- as.integer (gsub ("^\\_tu", "", tu)) / 10

        graph <- fst::read_fst (f)
        class (graph) <- c ("dodgr_streetnet_sc", class (graph))
        attr (graph, "left_side") <- FALSE
        attr (graph, "wt_profile") <- "motorcar"
        attr (graph, "turn_penalty") <- tu

        dat <- ttcalib_traveltimes (graph, geodata, uberdata)

        dat <- dat [which (is.finite (dat$m4ra)), ]
        mod <- summary (lm (log10 (dat$uber) ~ log10 (dat$m4ra)))

        return (c (
            traffic_lights = tl,
            turn = tu,
            r2 = mod$r.squared,
            residuals = sum (mod$residuals ^ 2)))
    })

    res <- data.frame (do.call (rbind, res))

    if (is.null (hours)) {
        hours <- c (0, 24)
    }

    res$hour0 <- hours [1]
    res$hour1 <- hours [2]

    return (res)
}

find_batch_result_dir <- function (path) {

    f <- normalizePath (list.files (path, full.names = TRUE))
    f <- f [which (dir.exists (f))]
    has_batch_results <- vapply (f, function (i) {
        flist <- list.files (i)
        any (grep ("\\_tl.*\\_tu.*\\_dlim.*\\.Rds", flist))
              }, logical (1L))
    f <- f [which (has_batch_results)]
    if (length (f) != 1L) {
        stop ("Could not locate directory with batch results",
              call. = FALSE)
    }

    return (f)
}
