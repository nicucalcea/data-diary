library(tidyverse)
library(rvest)

eurostat_raw <- read_html("https://ec.europa.eu/eurostat/web/main/news/release-calendar")

eurostat <- eurostat_raw |>
  html_nodes("script") |>
  pluck(45) |>
  html_text(trim = TRUE)

regex <- "var fullEvents = \\[\\s*((?:.|\\n)+?)\\s*\\];"
matches <- regmatches(eurostat, regexec(regex, eurostat))

fullEvents <- matches[[1]][2]
