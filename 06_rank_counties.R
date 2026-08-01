# World Toilet Day: ACS plumbing access
# 06_rank_counties.R
#
# Adds national and within-state county rankings. The ranking metric is the
# estimated share of all housing units lacking complete plumbing.

rank_counties <- function(data, grouping_columns = character()) {
  rankable_data <- if (inherits(data, "sf")) {
    sf::st_drop_geometry(data)
  } else {
    data
  }

  rankable_data %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping_columns))) %>%
    dplyr::mutate(
      counties_in_comparison = dplyr::n(),
      rank_highest_pct_lacking = dplyr::min_rank(
        dplyr::desc(pct_lacking)
      ),
      rank_lowest_pct_lacking = dplyr::min_rank(pct_lacking),
      percentile_pct_lacking = dplyr::percent_rank(pct_lacking) * 100,
      decile_pct_lacking = dplyr::ntile(pct_lacking, 10)
    ) %>%
    dplyr::ungroup()
}

national_county_rankings <- county_df %>%
  dplyr::filter(
    state_name %in% c(state.name, "District of Columbia")
  ) %>%
  rank_counties() %>%
  dplyr::arrange(rank_highest_pct_lacking, name_clean)

state_county_rankings <- county_df %>%
  dplyr::filter(
    state_name %in% c(state.name, "District of Columbia")
  ) %>%
  rank_counties("state_name") %>%
  dplyr::arrange(
    state_name,
    rank_highest_pct_lacking,
    name_clean
  )

georgia_county_rankings <- state_county_rankings %>%
  dplyr::filter(state_name == "Georgia")

if (nrow(georgia_county_rankings) != 159) {
  warning(
    "Expected 159 Georgia counties but found ",
    nrow(georgia_county_rankings),
    ". Review the county input.",
    call. = FALSE
  )
}

readr::write_csv(
  national_county_rankings,
  file.path(
    paths$data,
    glue::glue("county_rankings_national_{config$data_year}.csv")
  )
)

readr::write_csv(
  georgia_county_rankings,
  file.path(
    paths$data,
    glue::glue("county_rankings_georgia_{config$data_year}.csv")
  )
)

message(
  "Created national and Georgia county ranking data frames and CSV files."
)
