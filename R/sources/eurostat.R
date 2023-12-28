library(tidyverse)
library(rvest)
library(V8)

eurostat <- jsonlite::read_json(paste0("https://ec.europa.eu/eurostat/o/calendars/eventsJson?theme=0&category=0&keywords=&isEuroindicator=&authorInclude=&authorExclude=ecb%2Cecfin&start=", lubridate::floor_date(Sys.Date(), "month"), "T00%3A00%3A00%2B01%3A00&end=", lubridate::ceiling_date(Sys.Date() %m+% months(1), "month"), "T00%3A00%3A00%2B01%3A00&timeZone=Europe%2FLuxembourg")) |>
  tibble() |>
  unnest_wider(1) |>
  mutate(start = as.Date(start),
         link = "https://ec.europa.eu/eurostat/web/main/news/release-calendar",
         business = theme == "Economy and finance") |>
  select(title, link, date = start, business)


# eurostat_raw <- read_html("https://ec.europa.eu/eurostat/web/main/news/release-calendar") |>
#   html_elements("script") |>
#   pluck(45) |>
#   html_text() |>
#   paste(collapse = "\n") |>
#   stringr::str_remove("const url = new URL\\(window\\.location\\.href\\);[\\s\\S]*")
#
# ctx <- v8()
#
# paste0(c("var window = {};", eurostat_raw), collapse = "\n") |>
#   ctx$eval()
#
# eurostat <- ctx$get("fullEvents") |>
#   mutate(date = lubridate::ymd_hms(start) |> as.Date(),
#          link = "https://ec.europa.eu/eurostat/web/main/news/release-calendar",
#          business = theme == "Economy and finance") |>
#   select(title, link, date, business)
#
# remove(eurostat_raw, ctx)
