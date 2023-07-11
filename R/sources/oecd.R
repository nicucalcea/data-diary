library(tidyverse)
library(rvest)
library(RSelenium)

scrape_oecd <- function(title, url) {

  print(paste0("Scraping ", title))

  rD <- rsDriver(browser = "firefox", port = httpuv::randomPort(), verbose = F)
  remDr <- rD[["client"]]

  remDr$navigate(url)

  Sys.sleep(5)

  webElem <- remDr$findElement(using = "id", value = "webEditContent")

  text <- webElem$getElementText() |> toString()

  remDr$close()
  rD$server$stop()

  Sys.sleep(1)

  return(tibble(title = title,
         link = url,
         date = text |> stringr::str_split_1("\n") |> lubridate::dmy()) |>
    drop_na(date))
}


oecd <- scrape_oecd("Consumer Price Indices", "https://www.oecd.org/sdd/prices-ppp/oecdconsumerprices-timetable.htm") |>
  bind_rows(scrape_oecd("Labour market situation", "https://www.oecd.org/sdd/labour-stats/releasedatesoftheoecdnewsreleasesonharmonisedunemploymentrates.htm")) |>
  bind_rows(scrape_oecd("Growth and economic well-being", "https://www.oecd.org/sdd/na/release-dates-oecd-news-releases-quarterly-national-accounts.htm")) |>
  bind_rows(scrape_oecd("International Trade Statistics - G20 Trade", "https://www.oecd.org/sdd/its/releasedatesoftheoecdnewsreleaseoninternationaltradestatistics.htm"))


remove(scrape_oecd)
