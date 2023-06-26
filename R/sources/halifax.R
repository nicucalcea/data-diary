library(tidyverse)
library(rvest)

halifax <- tibble(title = "Halifax House Price Index",
                  link = "https://www.halifax.co.uk/media-centre/house-price-index.html",
                  date = read_html("https://www.halifax.co.uk/media-centre/house-price-index.html") |>
                    html_nodes(".floating-icon p:nth-of-type(n+2)") |>
                    html_text() |>
                    lubridate::dmy())
