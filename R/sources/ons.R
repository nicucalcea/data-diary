library(tidyverse)
library(rvest)

scrape_ons <- function(page_nr = 1) {

  page_nr = page_nr
  page_date = Sys.Date()
  max_date = lubridate::ceiling_date(Sys.Date() %m+% months(1), "month")

  data_all <- tibble()

  while (page_date < max_date) {
    Sys.sleep(1)
    print(paste0("Scraping page ", page_nr))

    # Scrape the current page
    page_raw <- read_html(paste0("https://www.ons.gov.uk/releasecalendar?size=100&view=upcoming&page=", page_nr))

    page_title <- page_raw |>
      html_nodes(".search-results__title span") |>
      html_text(trim = T)

    page_link <- page_raw |>
      html_nodes(".search-results__title a") |>
      html_attr('href') %>%
      paste0("https://www.ons.gov.uk", .)

    page_date <- page_raw |>
      html_nodes("p.flush") |>
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
  fill(date)
