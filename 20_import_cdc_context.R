# World Toilet Day: supplemental disease context
# 20_import_cdc_context.R
#
# Pulls national NNDSS surveillance data for contextual visualization only.
# These data are never joined to, correlated with, or modeled against the ACS
# plumbing data.

cdc_api_url <- "https://data.cdc.gov/resource/x9gk-5huc.json"

cdc_condition_labels <- c(
  "Cholera",
  "Salmonella Typhi infection",
  "Typhoid fever",
  "Salmonella Paratyphi infection",
  "Paratyphoid fever"
)

cdc_label_query <- cdc_condition_labels %>%
  paste0("'", ., "'") %>%
  paste(collapse = ",")

cdc_where_query <- glue::glue(
  "location2 in('TOTAL','Total') ",
  "and label in({cdc_label_query})"
)

cdc_request <- httr2::request(cdc_api_url) %>%
  httr2::req_url_query(
    `$select` = paste(
      "states",
      "location2",
      "year",
      "week",
      "label",
      "m1",
      "m1_flag",
      "m3",
      "m3_flag",
      sep = ","
    ),
    `$where` = cdc_where_query,
    `$order` = "year,week,label",
    `$limit` = 50000
  ) %>%
  httr2::req_user_agent("world-toilet-day-public-script/1.0") %>%
  httr2::req_retry(max_tries = 3)

cdc_response <- cdc_request %>%
  httr2::req_perform()

cdc_retrieved_at <- Sys.time()

cdc_payload <- cdc_response %>%
  httr2::resp_body_json(simplifyVector = TRUE) %>%
  tibble::as_tibble()

required_cdc_fields <- c("states", "location2", "year", "week", "label")

if (!all(required_cdc_fields %in% names(cdc_payload))) {
  stop(
    "The CDC API response did not contain the expected fields. Returned: ",
    paste(names(cdc_payload), collapse = ", "),
    call. = FALSE
  )
}

cdc_raw <- cdc_payload %>%
  dplyr::mutate(
    year = as.integer(year),
    week = as.integer(week),
    current_week_cases = readr::parse_number(
      as.character(m1),
      na = c("", "NA")
    ),
    cumulative_ytd_raw = readr::parse_number(
      as.character(m3),
      na = c("", "NA")
    ),
    current_week_flag = dplyr::coalesce(m1_flag, ""),
    cumulative_ytd_flag = dplyr::coalesce(m3_flag, ""),
    cumulative_ytd_cases = dplyr::case_when(
      !is.na(cumulative_ytd_raw) ~ cumulative_ytd_raw,
      cumulative_ytd_flag == "-" ~ 0,
      TRUE ~ NA_real_
    ),
    disease = dplyr::case_when(
      label %in% c("Salmonella Typhi infection", "Typhoid fever") ~
        "Typhoid fever",
      label %in% c(
        "Salmonella Paratyphi infection",
        "Paratyphoid fever"
      ) ~ "Paratyphoid fever",
      label == "Cholera" ~ "Cholera",
      TRUE ~ label
    )
  )

if (nrow(cdc_raw) == 0) {
  stop(
    "The CDC API returned no national records for the requested diseases.",
    call. = FALSE
  )
}

cdc_annual_by_label <- cdc_raw %>%
  dplyr::filter(
    !is.na(year),
    !is.na(week)
  ) %>%
  dplyr::group_by(year, disease, label) %>%
  dplyr::arrange(week, .by_group = TRUE) %>%
  dplyr::slice_tail(n = 1) %>%
  dplyr::ungroup()

cdc_annual <- cdc_annual_by_label %>%
  dplyr::group_by(year, disease) %>%
  dplyr::summarise(
    last_published_week = max(week, na.rm = TRUE),
    reported_cases = if (all(is.na(cumulative_ytd_cases))) {
      NA_real_
    } else {
      sum(cumulative_ytd_cases, na.rm = TRUE)
    },
    source_labels = paste(sort(unique(label)), collapse = "; "),
    reporting_flags = paste(
      sort(unique(cumulative_ytd_flag[cumulative_ytd_flag != ""])),
      collapse = "; "
    ),
    .groups = "drop"
  ) %>%
  dplyr::mutate(
    series_status = dplyr::if_else(
      year == max(year, na.rm = TRUE),
      glue::glue("Year to date through MMWR week {last_published_week}"),
      "Last cumulative value published in weekly NNDSS tables"
    ),
    retrieved_at = format(
      cdc_retrieved_at,
      "%Y-%m-%d %H:%M:%S %Z"
    ),
    source_url = cdc_api_url
  )

