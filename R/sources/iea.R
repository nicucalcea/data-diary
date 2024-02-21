library(tidyverse)
library(rvest)

scrape_iea <- function() {

  iea_raw <- read_html("https://www.iea.org/events") |>
    html_nodes(".m-grid--event") |>
    pluck(1)

  iea_title <- iea_raw |>
    html_nodes(".m-event-listing__hover") |>
    html_text(trim = T)

  iea_link <- iea_raw |>
    html_nodes(".m-event-listing__link") |>
    html_attr('href') %>%
    paste0("https://www.iea.org", .)

  iea_date <- iea_raw |>
    html_nodes(".m-event-listing__date") |>
    html_text() |>
    lubridate::dmy()

  iea <- tibble(title = iea_title,
                date = iea_date,
                link = iea_link)

  return(iea)

}

iea <- scrape_iea()

rm(scrape_iea)
