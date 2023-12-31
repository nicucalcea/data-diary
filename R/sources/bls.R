library(tidyverse)
library(rvest)
library(httr)
library(lubridate)

bls_ul <- paste0("https://www.bls.gov/schedule/", format(Sys.Date() %m+% months(1), "%Y/%m"), "_sched_list.htm")

headers = c(
  `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:120.0) Gecko/20100101 Firefox/120.0",
  `Accept` = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
  `Accept-Language` = "en-GB",
  `Accept-Encoding` = "gzip, deflate, br",
  `DNT` = "1",
  `Connection` = "keep-alive",
  `Upgrade-Insecure-Requests` = "1",
  `Sec-Fetch-Dest` = "document",
  `Sec-Fetch-Mode` = "navigate",
  `Sec-Fetch-Site` = "cross-site",
  `TE` = "trailers"
)


bls <- httr::GET(url = bls_ul, httr::add_headers(.headers=headers)) |>
  content() |>
  html_element(".release-list") |>
  html_table() |>
  mutate(date = lubridate::mdy(Date),
         link = bls_ul) |>
  select(title = 3, link, date)

remove(bls_ul, headers)
