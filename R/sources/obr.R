library(tidyverse)
library(rvest)

obr_raw <- read_html("https://obr.uk/publications/") |>
  html_nodes(".block-pubs-footer")

obr_title <- obr_raw |>
  html_nodes("a") |>
  html_text(trim = T)

obr_date <- obr_raw |>
  html_text(trim = T) |>
  stringr::str_replace(".*Next release", "") |>
  lubridate::dmy()

obr <- tibble(title = obr_title,
              link = "https://obr.uk/publications/",
              date = obr_date)

remove(obr_raw, obr_title, obr_date)
