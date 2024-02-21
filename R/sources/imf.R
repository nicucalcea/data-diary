library(tidyverse)
library(jsonlite)

imf <- read_json("https://www.imf.org/coveo/rest/v2?sitecoreItemUri=sitecore%3A%2F%2Fweb%2F%7B4A7DECEF-882C-40CE-A443-6BE41FA52909%7D%3Flang%3Den%26amp%3Bver%3D4&siteName=imf") |>
  pluck("results") |>
  tibble() |>
  unnest_wider(1) |>
  select(raw) |>
  unnest_wider(raw, names_sep = "_") |>
  # filter(grepl("coming soon", raw_systitle, ignore.case = T),
  #        !grepl("prd-sitecore-cm", raw_sysuri)) |>
  select(title = raw_systitle, link = raw_sysuri, date = raw_date) |>
  mutate(date = lubridate::as_datetime(date / 1000),
         title = gsub("Coming Soon: ", "", title)) |>
  identity()
