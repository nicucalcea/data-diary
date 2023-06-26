library(tidyverse)
library(rvest)


scrape_gov_uk <- function(page_nr = 1) {

  page_nr = page_nr
  page_date = Sys.Date()
  max_date = lubridate::ceiling_date(Sys.Date() %m+% months(1), "month")

  gov_uk_all <- tibble()

  while (page_date < max_date) {
    Sys.sleep(1)
    print(paste0("Scraping page ", page_nr))

    # Scrape the current page
    gov_uk_raw <- read_html(paste0("https://www.gov.uk/search/research-and-statistics?content_store_document_type=upcoming_statistics&order=updated-newest&page=", page_nr))

    gov_uk_title <- gov_uk_raw |>
      html_nodes(".gem-c-document-list__item-title") |>
      html_text(trim = T)

    gov_uk_link <- gov_uk_raw |>
      html_nodes(".gem-c-document-list__item-title") |>
      # html_children() |>
      html_attr('href') %>%
      paste0("https://www.gov.uk", .)

    gov_uk_date <- gov_uk_raw |>
      html_nodes("li.gem-c-document-list__attribute:nth-of-type(3)") |>
      html_text(trim = T)

    gov_uk_status <- gov_uk_raw |>
      html_nodes("li.gem-c-document-list__attribute:nth-of-type(4)") |>
      html_text(trim = T)


    gov_uk <- tibble(title = gov_uk_title,
                     link = gov_uk_link,
                     date = gov_uk_date,
                     status = gov_uk_status) |>
      filter(!str_detect(status, 'cancelled')) |>
      mutate(date = as.POSIXct(date, format = "Release date: %d %B %Y %I:%M%p")) |>
      select(-c("status"))

    # Add to the big list
    gov_uk_all <- gov_uk_all |>
      bind_rows(gov_uk)

    page_nr = page_nr + 1
    page_date = gov_uk$date |> na.omit() |> tail(1)
  }

  return(gov_uk_all)
}



gov_uk <- scrape_gov_uk()
