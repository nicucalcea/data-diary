library(tidyverse)
library(rvest)

ofs <- read_html("https://www.officeforstudents.org.uk/data-and-analysis/official-statistics/release-schedules/") |>
  html_table() |>
  pluck(1) |>
  select(title = 1, date = 2) |>
  mutate(date = lubridate::dmy(date),
         link = "https://www.officeforstudents.org.uk/data-and-analysis/official-statistics/release-schedules/")
