# Static dependency declarations for renv.
#
# The pipeline loads packages from the character vector in 00_setup.R. renv's
# dependency scanner cannot infer those dynamic calls, so these unreachable
# library calls provide an explicit, machine-readable dependency manifest.

if (FALSE) {
  library(beepr)
  library(tidyverse)
  library(janitor)
  library(glue)
  library(httr2)
  library(leaflet)
  library(htmlwidgets)
  library(knitr)
  library(rmarkdown)
  library(testthat)
  library(tidycensus)
  library(tigris)
  library(sf)
  library(scales)
  library(viridis)
}
