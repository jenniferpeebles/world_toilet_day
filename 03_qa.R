# World Toilet Day: ACS plumbing access
# 03_qa.R
#
# Performs structural checks and records data-quality flags without changing
# the benchmark estimates or filtering analytical rows.

qa_plumbing_data <- function(data, geography) {
  required_columns <- c(
    "geoid",
    "name_clean",
    "total",
    "complete",
    "lacking",
    "total_moe",
    "complete_moe",
    "lacking_moe",
    "pct_complete",
    "pct_complete_moe",
    "pct_complete_ci_low",
    "pct_complete_ci_high",
    "pct_complete_ci_overlaps_zero",
    "pct_complete_cv_percent",
    "pct_complete_reliability",
    "pct_lacking",
    "pct_lacking_moe",
    "pct_lacking_ci_low",
    "pct_lacking_ci_high",
    "pct_lacking_ci_overlaps_zero",
    "pct_lacking_cv_percent",
    "pct_lacking_reliability"
  )

  missing_columns <- setdiff(required_columns, names(data))

  if (length(missing_columns) > 0) {
    stop(
      geography,
      " data is missing required columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  duplicate_geoids <- sum(duplicated(data$geoid))

  if (duplicate_geoids > 0) {
    stop(
      geography,
      " data contains ",
      duplicate_geoids,
      " duplicated GEOID value(s).",
      call. = FALSE
    )
  }

  if (inherits(data, "sf") && is.na(sf::st_crs(data))) {
    stop(geography, " geometry has no coordinate reference system.", call. = FALSE)
  }

  summary <- tibble::tibble(
    geography = geography,
    rows = nrow(data),
    unique_geoids = dplyr::n_distinct(data$geoid),
    missing_total = sum(is.na(data$total)),
    nonpositive_total = sum(data$total <= 0, na.rm = TRUE),
    component_mismatch = sum(
      data$total != data$complete + data$lacking,
      na.rm = TRUE
    ),
    pct_complete_out_of_bounds = sum(
      data$pct_complete < 0 | data$pct_complete > 1,
      na.rm = TRUE
    ),
    pct_lacking_out_of_bounds = sum(
      data$pct_lacking < 0 | data$pct_lacking > 1,
      na.rm = TRUE
    ),
    missing_pct_complete = sum(is.na(data$pct_complete)),
    missing_pct_lacking = sum(is.na(data$pct_lacking)),
    invalid_pct_complete_moe = sum(
      data$pct_complete_moe < 0 | !is.finite(data$pct_complete_moe),
      na.rm = TRUE
    ),
    invalid_pct_lacking_moe = sum(
      data$pct_lacking_moe < 0 | !is.finite(data$pct_lacking_moe),
      na.rm = TRUE
    ),
    total_ci_overlaps_zero = sum(
      data$total_ci_overlaps_zero,
      na.rm = TRUE
    ),
    complete_ci_overlaps_zero = sum(
      data$complete_ci_overlaps_zero,
      na.rm = TRUE
    ),
    lacking_ci_overlaps_zero = sum(
      data$lacking_ci_overlaps_zero,
      na.rm = TRUE
    ),
    pct_complete_ci_overlaps_zero = sum(
      data$pct_complete_ci_overlaps_zero,
      na.rm = TRUE
    ),
    pct_lacking_ci_overlaps_zero = sum(
      data$pct_lacking_ci_overlaps_zero,
      na.rm = TRUE
    ),
    pct_complete_low_reliability = sum(
      data$pct_complete_reliability == "Low reliability",
      na.rm = TRUE
    ),
    pct_lacking_low_reliability = sum(
      data$pct_lacking_reliability == "Low reliability",
      na.rm = TRUE
    ),
    pct_complete_not_classifiable = sum(
      data$pct_complete_reliability == "Not classifiable",
      na.rm = TRUE
    ),
    pct_lacking_not_classifiable = sum(
      data$pct_lacking_reliability == "Not classifiable",
      na.rm = TRUE
    )
  )

  flagged_fields <- c(
    "missing_total",
    "nonpositive_total",
    "component_mismatch",
    "pct_complete_out_of_bounds",
    "pct_lacking_out_of_bounds",
    "missing_pct_complete",
    "missing_pct_lacking",
    "invalid_pct_complete_moe",
    "invalid_pct_lacking_moe",
    "total_ci_overlaps_zero",
    "complete_ci_overlaps_zero",
    "lacking_ci_overlaps_zero",
    "pct_complete_ci_overlaps_zero",
    "pct_lacking_ci_overlaps_zero",
    "pct_complete_low_reliability",
    "pct_lacking_low_reliability",
    "pct_complete_not_classifiable",
    "pct_lacking_not_classifiable"
  )

  flags <- summary %>%
    dplyr::select(dplyr::all_of(flagged_fields)) %>%
    unlist(use.names = FALSE) %>%
    sum()

  if (flags > 0) {
    warning(
      geography,
      " data produced ",
      flags,
      " QA flag(s). Review output/data/qa_summary.csv.",
      call. = FALSE
    )
  }

  summary
}

qa_inputs <- list(
  us = us_df,
  state = state_df,
  county = county_df,
  place = place_df
)

qa_summary <- names(qa_inputs) %>%
  purrr::map_dfr(
    function(geography) {
      data <- qa_inputs[[geography]]

      if (is.null(data)) {
        return(NULL)
      }

      qa_plumbing_data(data, geography)
    }
  )

ci_metric_specs <- tibble::tribble(
  ~metric, ~estimate_col, ~moe_col, ~low_col, ~high_col, ~flag_col,
  "total", "total", "total_moe", "total_ci_low", "total_ci_high",
  "total_ci_overlaps_zero",
  "complete", "complete", "complete_moe", "complete_ci_low",
  "complete_ci_high", "complete_ci_overlaps_zero",
  "lacking", "lacking", "lacking_moe", "lacking_ci_low",
  "lacking_ci_high", "lacking_ci_overlaps_zero",
  "pct_complete", "pct_complete", "pct_complete_moe",
  "pct_complete_ci_low", "pct_complete_ci_high",
  "pct_complete_ci_overlaps_zero",
  "pct_lacking", "pct_lacking", "pct_lacking_moe",
  "pct_lacking_ci_low", "pct_lacking_ci_high",
  "pct_lacking_ci_overlaps_zero"
)

build_ci_zero_flags <- function(data, geography) {
  flag_data <- if (inherits(data, "sf")) {
    sf::st_drop_geometry(data)
  } else {
    data
  }

  seq_len(nrow(ci_metric_specs)) %>%
    purrr::map_dfr(
      function(index) {
        spec <- ci_metric_specs[index, ]

        flag_data %>%
          dplyr::filter(.data[[spec$flag_col]]) %>%
          dplyr::transmute(
            geography = geography,
            geoid = geoid,
            name = name_clean,
            metric = spec$metric,
            estimate = .data[[spec$estimate_col]],
            margin_of_error_90 = .data[[spec$moe_col]],
            confidence_interval_low_90 = .data[[spec$low_col]],
            confidence_interval_high_90 = .data[[spec$high_col]],
            confidence_interval_overlaps_zero = .data[[spec$flag_col]]
          )
      }
    )
}

ci_zero_flags <- names(qa_inputs) %>%
  purrr::map_dfr(
    function(geography) {
      data <- qa_inputs[[geography]]

      if (is.null(data)) {
        return(NULL)
      }

      build_ci_zero_flags(data, geography)
    }
  )
