library(tidyverse)
library(httr)
library(rvest)
library(lubridate)

# https://markets.businessinsider.com/earnings-calendar

scrape_earnings <- function(company) {

  headers = c(
    `Content-Type` = "application/json",
    `Origin` = "https://markets.businessinsider.com"
  )

  res <- httr::POST(url = "https://markets.businessinsider.com/ajax/updatecalendar",
                    httr::add_headers(.headers=headers),
                    # httr::set_cookies(.cookies = cookies),
                    body = paste0('{"Type":"EarningsCalendar","Page":1,"date":"', format.Date(Sys.Date(), format = "%m/%d/%Y"), '-',Sys.Date() |> lubridate::ceiling_date("years") |> format.Date("%m/%d/%Y"), '","name":"', company, '","tab":"ALL","eventtypes":"103,99"}')) |>
    content(as = "text") |>
    read_html() |>
    html_element(".table__tbody")


  title <- res |>
    html_elements(".calendar__table__company a") |>
    html_text()

  title2 <- res |>
    html_elements(xpath = "//*[contains(@class, 'table__tr')]//td[3]") |>
    html_text(trim = T)

  date <- res |>
    html_elements(".table__tr") |>
    html_element(".table__td") |>
    html_text(trim = T) %>%
    paste0(year(Sys.Date()), "/", .) |>
    lubridate::ymd()

  link <- res |>
    html_elements(".calendar__table__company a") |>
    html_attr("href") %>%
    paste0("https://markets.businessinsider.com", .)

  earnings <- tibble(title = paste0(title, ": ", title2),
                     date = date,
                     link = link)

  Sys.sleep(1)

  return(earnings)


}

earnings <- map(c("Shell (ex Royal Dutch Shell)", "BP plc (British Petrol)", "ExxonMobil Corp. (Exxon Mobil)", "Chevron Corp.", "Marathon Petroleum Corporation", "Marathon Oil Corp.", "Phillips 66", "Valero Energy Corp.", "Eni S.p.A.", "ConocoPhillips", "TOTAL S.A."),
                scrape_earnings) |>
  bind_rows() |>
  arrange(desc(date))

rm(scrape_earnings)
