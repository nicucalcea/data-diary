library(tidyverse)

# Email from Sophie Comninos <scomninos@camargue.uk>
kantar <- tibble(.rows = 8) |>
  mutate(title = "Kantar Grocery Market Share",
         link = "https://www.kantarworldpanel.com/grocery-market-share/great-britain",
         date = lubridate::dmy(c("3 Jan 2024", "30 Jan 2024", "27 Feb 2024", "26 Mar 2024", "23 Apr 2024", "21 May 2024", "18 Jun 2024", "16 Jul 2024")))

if(Sys.Date() > max(kantar$date)) {
  warning("Kantar figures may be out of date, please update them manually.")
}
