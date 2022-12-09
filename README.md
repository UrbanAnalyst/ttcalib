[![R build
status](https://github.com/UrbanAnalyst/ttcalib/workflows/R-CMD-check/badge.svg)](https://github.com/UrbanAnalyst/ttcalib/actions?query=workflow%3AR-CMD-check)
[![Project Status:
Concept](https://www.repostatus.org/badges/latest/concept.svg)](https://www.repostatus.org/#concept)

# ttcalib: Calibration of travel times to empirical data

One metric used throughout this organisation is travel times relative to
equivalent times taken by motorcars. This repository documents
procedures used to calibrate estimates of motorcar travel times to
empirical data.

## Empirical Data

### Uber movement data

The empirical data are from [Uber movement](https://movement.uber.com/),
with these analyses calibrating against [data from Santiago,
Chile](https://movement.uber.com/explore/santiago/travel-times?lang=en-US).
The data used are the “All Data” version for the first quarter of 2020,
grouped by “Hour of Day”. The download tab on the website linked to
above also includes a link to the “Geo Boundaries”, which are also
required. Both of these data should be saved to a local directory.

### OSM Network data

The Uber movement data extend over a far greater boundary than the
“Santiago” boundary returned by Nominatim. The OSM network data were
therefore obtained here from the complete Chile `pbf` file downloaded
from Geofabrik, and then processed with `osmium-tools` by:

1.  Trimming to bbox of (-71.363,-33.851,-70.377,-33.113)
2.  Constructing separate keyword-filtered subsets with keywords of:
    “highway”, “restriction”, “access”, “bicycle”, “foot”, “motorcar”,
    “motor_vehicle”, “vehicle”, “toll”.
3.  Converting all of these single `pbf` files to `osm` (XML) format.
4.  Reading in each via
    [`osmdata::osmdata_sc()`](https://docs.ropensci.org/osmdata/reference/osmdata_sc.html),
    and combining all data into single `osmdata_sc` object.

## Calibration

The calibration proceeds in two steps:

1.  Calibration of waiting times both at traffic lights, and to turn
    across oncoming traffic. The effects of these parameters was
    examined in [a 2020 *Scientific Data* paper, “*Longitudinal spatial
    dataset on travel times and distances by different travel modes in
    Helsinki
    Region*](https://www.nature.com/articles/s41597-020-0413-y), which
    implemented a complicated parametrisation of waiting times at
    various types of intersections “based on previous research.”
2.  Calibration of estimated times to measures of network centrality.
    These effects were examined in [a 2014 *Nature Communications*
    paper, “*Predicting commuter flows in spatial networks using a
    radiation model based on temporal
    ranges*](https://www.nature.com/articles/ncomms6347), which started
    with a “base” model able to predict observed travel times with an
    r-squared correlation coefficient of 0.639. This was then increased
    through inclusion of the effects of centrality, using a simple
    threshold model, to 0.752.

These two types of calibration are successively applied here.

### Calibration to waiting times

Waiting times were examined through two parameters:

1.  The effective waiting time at traffic lights; and
2.  The effective waiting time to turn across oncoming traffic.

Street networks were weighted for time-based routing using specific
values of these two parameters, and travel times estimated for all
320,666 observed origins and destinations in the Uber Movement data. The
minimal-error model corresponded to an R-squared correlation of 0.782
for an effective waiting time at traffic lights of 8 seconds in morning
peak hour traffic (7-10 am), or 9 seconds in afternoon traffic (3-7 pm).
Corresponding effective waiting times to turn across oncoming traffic
were only 2 or 1 seconds, respectively, although these made very little
difference to model results compared with the effects of traffic lights.

### Calibration to network centrality

The preceding waiting times were then used to calculate time-based
metrics of centrality, and to adjust observed travel times by
centrality. These adjustments made, however, very little difference, and
increasing travel times along more central portions of the network
increased agreement with observed values at most by only a few
hundredths of a percent or less. The best model was to logarithmically
transform centrality, divide by the maximum value, and increase travel
times for the upper 30% of the centrality distribution by the
corresponding values. Even this, however, only increased resultant
r-squared values by just over 1%.

## Conclusion

This repository documents and justifies the general procedure pursued
here, to estimate vehicular travel times through using the following
time penalties:

1.  Wait at traffic lights = 9 seconds
2.  Wait to turn across oncoming traffic = 1 second

No additional adjustments for network centrality are implemented.

![](man/figures/correlation.png)
