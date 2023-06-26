library(tidyverse)
library(rvest)

ofcom <- read_html("https://www.ofcom.org.uk/research-and-data/data/statistics/stats23") |>
  html_table() |>
  bind_rows() |>
  select(title = 1, date = 2) |>
  mutate(date = lubridate::dmy(date),
         link = "https://www.ofcom.org.uk/research-and-data/data/statistics/stats23")
