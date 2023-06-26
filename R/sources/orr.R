library(tidyverse)
library(rvest)

orr <- read_html("https://dataportal.orr.gov.uk/publication-dates-for-statistics/") |>
  html_table() |>
  pluck(1) |>
  select(title = 3, date = 5) |>
  mutate(date = lubridate::dmy(date),
         link = "https://dataportal.orr.gov.uk/publication-dates-for-statistics/")
