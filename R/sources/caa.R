library(tidyverse)
library(rvest)

caa <- read_html("https://www.caa.co.uk/data-and-analysis/uk-aviation-market/data-publication-dates/") |>
  html_table() |>
  pluck(1) |>
  janitor::row_to_names(row_number = 1) |>
  pivot_longer(-Date) |>
  filter(value != "") |>
  select(title = 2, date = 1) |>
  mutate(date = lubridate::dmy(date),
         link = "https://www.caa.co.uk/data-and-analysis/uk-aviation-market/data-publication-dates/")
