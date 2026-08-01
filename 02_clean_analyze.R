# World Toilet Day: ACS plumbing access
# 02_clean_analyze.R
#
# Reproduces the benchmark cleaning, MOE calculations, ranks, and percentiles.

calculate_cv_percent <- function(estimate, margin_of_error_90) {
  dplyr::if_else(
    is.finite(estimate) &
      estimate > 0 &
      is.finite(margin_of_error_90) &
      margin_of_error_90 >= 0,
    (margin_of_error_90 / 1.645) / estimate * 100,
    NA_real_
  )
}

classify_reliability <- function(cv_percent) {
  dplyr::case_when(
    is.na(cv_percent) ~ "Not classifiable",
    cv_percent <= 15 ~ "High reliability",
    cv_percent <= 30 ~ "Moderate reliability",
    TRUE ~ "Low reliability"
  )
}

prepare_plumbing_data <- function(data, geo) {
  data %>%
    janitor::clean_names() %>%
    dplyr::rename(
      total = total_e,
      total_moe = total_m,
      complete = complete_e,
      complete_moe = complete_m,
      lacking = lacking_e,
      lacking_moe = lacking_m
    ) %>%
    dplyr::mutate(
      total_ci_low = pmax(total - total_moe, 0),
      total_ci_high = total + total_moe,
      total_ci_overlaps_zero = is.finite(total) &
        is.finite(total_moe) &
        total - total_moe <= 0 &
        total + total_moe >= 0,
      complete_ci_low = pmax(complete - complete_moe, 0),
      complete_ci_high = complete + complete_moe,
      complete_ci_overlaps_zero = is.finite(complete) &
        is.finite(complete_moe) &
        complete - complete_moe <= 0 &
        complete + complete_moe >= 0,
      lacking_ci_low = pmax(lacking - lacking_moe, 0),
      lacking_ci_high = lacking + lacking_moe,
      lacking_ci_overlaps_zero = is.finite(lacking) &
        is.finite(lacking_moe) &
        lacking - lacking_moe <= 0 &
        lacking + lacking_moe >= 0,
      pct_complete = complete / total,
      pct_complete_moe = tidycensus::moe_prop(
        num = complete,
        denom = total,
        moe_num = complete_moe,
        moe_denom = total_moe
      ),
      pct_lacking = lacking / total,
      pct_lacking_moe = tidycensus::moe_prop(
        num = lacking,
        denom = total,
        moe_num = lacking_moe,
        moe_denom = total_moe
      ),
      pct_complete_ci_low = pmax(pct_complete - pct_complete_moe, 0),
      pct_complete_ci_high = pmin(pct_complete + pct_complete_moe, 1),
      pct_complete_ci_overlaps_zero = is.finite(pct_complete) &
        is.finite(pct_complete_moe) &
        pct_complete - pct_complete_moe <= 0 &
        pct_complete + pct_complete_moe >= 0,
      pct_lacking_ci_low = pmax(pct_lacking - pct_lacking_moe, 0),
      pct_lacking_ci_high = pmin(pct_lacking + pct_lacking_moe, 1),
      pct_lacking_ci_overlaps_zero = is.finite(pct_lacking) &
        is.finite(pct_lacking_moe) &
        pct_lacking - pct_lacking_moe <= 0 &
        pct_lacking + pct_lacking_moe >= 0,
      total_cv_percent = calculate_cv_percent(total, total_moe),
      total_reliability = classify_reliability(total_cv_percent),
      complete_cv_percent = calculate_cv_percent(complete, complete_moe),
      complete_reliability = classify_reliability(complete_cv_percent),
      lacking_cv_percent = calculate_cv_percent(lacking, lacking_moe),
      lacking_reliability = classify_reliability(lacking_cv_percent),
      pct_complete_cv_percent = calculate_cv_percent(
        pct_complete,
        pct_complete_moe
      ),
      pct_complete_reliability = classify_reliability(
        pct_complete_cv_percent
      ),
      pct_lacking_cv_percent = calculate_cv_percent(
        pct_lacking,
        pct_lacking_moe
      ),
      pct_lacking_reliability = classify_reliability(
        pct_lacking_cv_percent
      ),
      name_clean = stringr::str_squish(name),
      state_name = if (geo %in% c("county", "place")) {
        sub(".*,\\s*", "", name_clean)
      } else {
        NA_character_
      }
    )
}

add_ranks_percentiles <- function(data) {
  data %>%
    dplyr::mutate(
      complete_rank = rank(
        dplyr::desc(complete),
        ties.method = "min"
      ),
      lacking_rank = rank(
        dplyr::desc(lacking),
        ties.method = "min"
      )
    ) %>%
    dplyr::mutate(
      pct_complete_percentile = dplyr::ntile(pct_complete, 100),
      pct_lacking_percentile = dplyr::ntile(pct_lacking, 100)
    )
}

us_df <- if (!is.null(us_raw)) {
  us_raw %>%
    prepare_plumbing_data("us") %>%
    add_ranks_percentiles()
} else {
  NULL
}

state_df <- if (!is.null(state_raw)) {
  state_raw %>%
    prepare_plumbing_data("state") %>%
    dplyr::filter(!stringr::str_detect(name_clean, "Puerto Rico")) %>%
    add_ranks_percentiles()
} else {
  NULL
}

county_df <- if (!is.null(county_raw)) {
  county_raw %>%
    prepare_plumbing_data("county") %>%
    dplyr::filter(!stringr::str_detect(name_clean, "Puerto Rico")) %>%
    add_ranks_percentiles()
} else {
  NULL
}

place_df <- if (!is.null(place_raw)) {
  place_raw %>%
    prepare_plumbing_data("place") %>%
    dplyr::filter(!stringr::str_detect(name_clean, "Puerto Rico")) %>%
    add_ranks_percentiles()
} else {
  NULL
}
