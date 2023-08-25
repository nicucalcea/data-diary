library(tidyverse)
library(rvest)

scrape_nhs <- function(page_nr = 1) {

  page_nr = page_nr
  page_date = Sys.Date()
  max_date = lubridate::ceiling_date(Sys.Date() %m+% years(1), "month")

  data_all <- tibble()

  while (!is_empty(page_date) && page_date < max_date) {
    Sys.sleep(1)
    print(paste0("Scraping page ", page_nr))

    # Scrape the current page
    page_raw <- read_html(paste0("https://digital.nhs.uk/search/document-type/publication/publicationStatus/false?sort=date&area=data&page=", page_nr))

    page_title <- page_raw |>
      html_nodes(".cta__title, .cta__button") |>
      html_text(trim = T)

    page_link <- page_raw |>
      html_nodes(".cta__title, .cta__button") |>
      html_attr('href') %>%
      paste0("https://digital.nhs.uk", .)

    page_date <- page_raw |>
      html_nodes("span[data-uipath='ps.search-results.result.date']") |>
      html_text() |>
      lubridate::dmy()

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

nhs_digital <- scrape_nhs()

remove(scrape_nhs)
