library(tidyverse)
library(rvest)

scrape_ons <- function(page_nr = 1) {

  page_nr = page_nr
  page_date = Sys.Date()
  max_date = lubridate::ceiling_date(Sys.Date() %m+% years(1), "month")

  data_all <- tibble()

  while (page_date < max_date && page_nr <= 100) {
    Sys.sleep(1)
    print(paste0("Scraping page ", page_nr))

    # Scrape the current page
    page_raw <- read_html(paste0("https://www.ons.gov.uk/releasecalendar?release-type=type-upcoming&sort=date-newest&page=", page_nr))

    page_title <- page_raw |>
      html_nodes(".ons-u-fs-m") |>
      html_text(trim = T)

    page_link <- page_raw |>
      html_nodes(".ons-u-fs-m") |>
      html_attr('href') %>%
      paste0("https://www.ons.gov.uk", .)

    page_date <- page_raw |>
      html_nodes(".ons-u-mt-xs span:nth-of-type(2)") |>
      html_text() |>
      lubridate::dmy_hm()

    page_single <- tibble(title = page_title,
                          link = page_link,
                          date = page_date)

    # Add to the big list
    data_all <- data_all |>
      bind_rows(page_single)

    page_nr = page_nr + 1
    page_date = page_single$date |> na.omit() |> tail(1)
  }

  return(data_all)
}

ons <- scrape_ons() |>
  fill(date) |>
  filter(!grepl("time series", title))

remove(scrape_ons)
