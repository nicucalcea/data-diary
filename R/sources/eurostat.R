library(tidyverse)
library(rvest)
library(V8)

eurostat_raw <- read_html("https://ec.europa.eu/eurostat/web/main/news/release-calendar") |>
  html_elements("script") |>
  pluck(45) |>
  html_text() |>
  paste(collapse = "\n") |>
  stringr::str_remove("const url = new URL\\(window\\.location\\.href\\);[\\s\\S]*")

ctx <- v8()

paste0(c("var window = {};", eurostat_raw), collapse = "\n") |>
  ctx$eval()

eurostat <- ctx$get("fullEvents") |>
  mutate(date = lubridate::ymd_hms(start) |> as.Date(),
         link = "https://ec.europa.eu/eurostat/web/main/news/release-calendar",
         business = theme == "Economy and finance") |>
  select(title, link, date, business)
