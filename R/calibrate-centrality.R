#' Calibrate travel times to network centrality.
#'
#' This calibration step is performed after calibration to waiting-time
#' penalties for traffic lights and turning across oncoming traffic, performed
#' with the \link{ttcalib_penalties} function. For Santiago, that function gives
#' an optimal waiting time at traffic lights of 16 seconds, and waiting time to
#' turn across oncoming traffic of 1 second. These values should be used to
#' generate a weighted network with time-based centrality via the
#' \link{ttcalib_streetnet} function.
#'
#' The result of that call is presumed to have been saved using the `fst`
#' package (with `write_fst`), which strips all attributes of the graph. These
#' attributes must then be manually re-instated, and so are required to be
#' submitted as parameters to
#' this function.
#'
#' @param path_graph Path to locally-saved `fst`-format weighted street
#' network including centrality column.
#' @param path_uberdata Path to Uber movement data.
#' @param city Currently only accepts "santiago"
#' @param hours A vector of two values defining the range of hours for Uber
#' Movement data to be filtered. Value of `NULL` aggregates all hours without
#' filtering.
#' @param turn_penalty The value of the time penalty for waiting to turn across
#' oncoming traffic used to generate the graph stored at `path`.
#' @export
ttcalib_centrality <- function (path_graph, path_uberdata,
                                city = "santiago", hours = c (7, 10),
                                turn_penalty = 1) {

    graph <- fst::read_fst (path_graph)
    graph <- graph [which (graph$component == 1), ]
    attr (graph, "left_side") <- FALSE
    attr (graph, "wt_profile") <- "motorcar"
    attr (graph, "turn_penalty") <- 1

    geodata <- ttcalib_geodata (path = path, city = city)
    uberdata <- ttcalib_uberdata (path = path, hours = hours, city = city)

    dat <- ttcalib_traveltimes (graph, geodata, uberdata)
}
