library(tidyverse)
library(rvest)

un <- read_html("http://data.un.org/UpdateCalendar.aspx") |>
  html_nodes("script") |>
  pluck(7) |>
  html_text(trim = TRUE) |>
  stringr::str_replace("var data = ", "") |>
  stringr::str_sub(end = -2) |>
  jsonlite::parse_json() |>
  pluck("updateData") |>
  tibble() |>
  unnest_wider(1) |>
  mutate(date = lubridate::ymd(NextUpdate),
         link = "http://data.un.org/UpdateCalendar.aspx") |>
  select(title = Name, link, date)
