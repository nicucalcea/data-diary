library(tidyverse)
library(rvest)

nomis <- read_html("https://www.nomisweb.co.uk/home/release_group.asp") |>
  html_node("#prdtab") |>
  html_table() |>
  select(title = 1, date = 2) |>
  mutate(date = lubridate::dmy_hm(date),
         link = "https://www.nomisweb.co.uk/home/release_group.asp")
