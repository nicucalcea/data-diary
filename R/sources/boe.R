library(tidyverse)
library(httr)
library(rvest)


##---------------------------------------------------------------
##                          Bank rate                           -
##---------------------------------------------------------------

bank_rate <- read_html("https://www.bankofengland.co.uk/monetary-policy/the-interest-rate-bank-rate") |>
  html_node(".stat-caption") |>
  html_text(trim = T) |>
  lubridate::dmy()


##----------------------------------------------------------------
##                      Other BoE releases                       -
##----------------------------------------------------------------

boe_data = list(
  # `SearchTerm` = "",
  `Id` = "{CE377CC8-BFBC-418B-B4D9-DBC1C64774A8}",
  `PageSize` = "100",
  `NewsTypesAvailable[]` = "571948d14c6943f7b5b7748ad80bef29",
  `Page` = "1",
  `Direction` = "2"
  # `Grid` = "false",
  # `InfiniteScrolling` = "false"
)

boe_res <- httr::POST(url = "https://www.bankofengland.co.uk/_api/News/RefreshPagedNewsList", body = boe_data, encode = "form") |>
  content()

boe_res <- boe_res$Results |>
  xml2::read_html()

boe_title <- boe_res |>
  html_nodes(".list") |>
  html_text()

boe_link <- boe_res |>
  html_nodes(".release-stats") |>
  html_attr('href') %>%
  paste0("https://www.bankofengland.co.uk", .)

boe_date <- boe_res |>
  html_nodes(".release-date") |>
  html_attr('datetime')

boe <- tibble(title = boe_title,
                 link = boe_link,
                 date = boe_date) |>
  mutate(date = as.Date(date)) |>
  add_row(title = "Bank of England Bank Rate",
          link = "https://www.bankofengland.co.uk/monetary-policy/the-interest-rate-bank-rate",
          date = bank_rate)

