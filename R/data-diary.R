library(tidyverse)
library(lubridate)
library(openxlsx)

# TODO write to ical so I can add it to my Outlook

#################################################################
##                      Classify releases                      ##
#################################################################

business_keywords <- c("agriculture in the united kingdom", "annual population survey", "apprenticeship", "balance sheet", "business", "claimant count", "construction output", "consumer price", "cost of living", "credit union", "domestic rates", "earnings and employment", "earnings and expenses", "economic activity", "economic estimates", "economic statistics", "electric vehicle", "employment cost index", "employment situation", "energy performance of building certificates", "fiscal risk", "fuel prices", "fuel sales", "gdp", "government debt", "gross domestic", "house price", "household energy efficiency", "household income", "housing benefit", "housing purchase affordability", "housing survey", "import and export", "income from farming", "index of production", "index of services", "interest rate", "international reserves", "insolvency", "job openings", "job seekers", "labour", "labor", "market data", "money and credit", "national accounts", "price index", "producer price", "productivity", "public sector finances", "rail fares", "rail passenger numbers", "rail performance", "real earnings", "rental prices", "retail sales", "revenues and expenses", "revenues and spend", "taxpayers", "tax credit", "tax receipt", "tax relief", "time use", "trade", "trends and prices", "uk energy in brief", "uk energy statistics", "universal credit", "unemployment", "vehicle licensing statistics", "weekly earnings") |>
  paste(collapse = "|")

important_keywords <- c("Bank of England Bank Rate", "Consumer price inflation, UK", "GDP monthly estimate", "GDP quarterly national accounts", "Retail sales", "UK labour market") |>
  paste(collapse = "|")

#################################################################
##                  Scrape individual sources                  ##
#################################################################

# 🇬🇧 UK: ONS
source("R/sources/ons.R")

# 🇬🇧 UK: GOV.UK
source("R/sources/gov-uk.R")

# 🇬🇧 UK: Nomis
source("R/sources/nomis.R")

# 🇬🇧 UK: Bank of England (+ bank rate)
source("R/sources/boe.R")

# 🇬🇧 UK: Office for Budget Responsibility
source("R/sources/obr.R")

# 🇬🇧 UK: Halifax
source("R/sources/halifax.R")

# 🇬🇧 UK: NHS Digital
source("R/sources/nhs-digital.R")

# 🇬🇧 UK: Ofcom
source("R/sources/ofcom.R")

# 🇬🇧 UK: Office of Rail and Road
source("R/sources/orr.R")

# 🇬🇧 UK: Civil Aviation Authority
source("R/sources/caa.R")

# 🇬🇧 UK: Office for Students
source("R/sources/ofs.R")

# 🇪🇺 EU: Eurostat
source("R/sources/eurostat.R")

# 🇺🇸 US: Bureau of Labor Statistics
source("R/sources/bls.R")

# 🌍 International: UN
source("R/sources/un.R")

# 🌍 International: OECD
source("R/sources/oecd.R")

#################################################################
##                           Combine                           ##
#################################################################

upcoming_stats <- gov_uk |>
  filter(!title %in% c(ons$title, nhs_digital$title, ofcom$title)) |>
  mutate(source = "GOV.UK") |>
  bind_rows(ons |> mutate(source = "ONS")) |>
  bind_rows(nomis |> mutate(source = "Nomis")) |>
  bind_rows(boe |> mutate(source = "Bank of England")) |>
  bind_rows(obr |> mutate(source = "OBR")) |>
  bind_rows(halifax |> mutate(source = "Halifax")) |>
  bind_rows(nhs_digital |> mutate(source = "NHS Digital")) |>
  bind_rows(ofcom |> mutate(source = "Ofcom")) |>
  bind_rows(orr |> mutate(source = "ORR")) |>
  bind_rows(caa |> mutate(source = "CAA")) |>
  bind_rows(ofs |> mutate(source = "OFS")) |>
  bind_rows(eurostat |> mutate(source = "Eurostat", country = "European Union")) |>
  bind_rows(bls |> mutate(source = "BLS", country = "United States")) |>
  bind_rows(un |> mutate(source = "UN", country = "International")) |>
  bind_rows(oecd |> mutate(source = "OECD", country = "International")) |>
  drop_na(date) |>
  filter(!grepl(" time series", title)) |>
  mutate(title_2 = title) |>
  separate_wider_delim(cols = title_2, delim = ": ", names = c("title_1", "title_2"),
                       too_few = "align_start", too_many = "drop") |>
  group_by(date, title_1) |>
  slice_head(n = 1) |>
  ungroup() |>
  select(-title_1, - title_2) |>
  mutate(date = as.Date(date),
         country = ifelse(is.na(country), "United Kingdom", country),
         country = factor(country, levels = c("United Kingdom", "European Union", "United States", "International")),
         flag = case_when(country == "European Union" ~ "🇪🇺",
                          country == "International" ~ "🌍",
                          T ~ countrycode::countrycode(country, "country.name", "unicode.symbol")),
         important = grepl(important_keywords, title, ignore.case = T),
         business = grepl(business_keywords, title, ignore.case = T) | business) |>
  arrange(date, country, important, business, title)

##################################################################
##                        Write to Excel                        ##
##################################################################

calendar_sheets <- upcoming_stats |>
  filter(date >= lubridate::floor_date(Sys.Date() %m+% months(1), "month"),
         date < lubridate::ceiling_date(Sys.Date() %m+% months(1), "month"),
         business) |>
  select(Country = country, Release = title, Date = date, Interest = important, link) |>
  identity()

# create and write workbook
wb <- createWorkbook()
addWorksheet(wb, "df_sheet")

class(calendar_sheets$link) <- "hyperlink" # mark as a hyperlink
writeData(wb, "df_sheet", calendar_sheets$link, startCol = which(colnames(calendar_sheets) == "Release"), startRow = 2)

calendar_sheets <- calendar_sheets |>
  select(-link) |>
  mutate(Date = as.character(Date))

writeData(wb, "df_sheet", calendar_sheets) # overwrite the sheet to get the new pretty name overlaying the hyperlink

saveWorkbook(wb, "output/biz_cal.xlsx", overwrite = TRUE)

##################################################################
##                         Create .ical                         ##
##################################################################

format_event <- function(start, end, summary, description, tz = "GMT") {
  template <-"BEGIN:VEVENT\nUID:%s\nDTSTAMP:%s\nDTSTART;VALUE=DATE:%s\nSUMMARY:%s\nDESCRIPTION:%s\nEND:VEVENT"
  sprintf(template, uuid::UUIDgenerate(),
          format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = tz),
          format(start, "%Y%m%d", tz = tz),
          # format(end, "%Y%m%dT%H%M%SZ", tz = tz),
          summary,
          description)
}

export_calendar <- function(df, file, tz = "BST") {
  header <- "BEGIN:VCALENDAR\nPRODID:-//MyMeetings/ical //EN\nVERSION:2.0\nCALSCALE:GREGORIAN"
  footer <- "END:VCALENDAR"
  df <- df |> filter(business)
  f <- file(file)
  open(f, "w")
  writeLines(header, con = f)
  invisible(lapply(1:nrow(df), \(i) {
    ic_char <- format_event(start = df$date[i], end = df$date[i] + 1,
                            summary = paste0(ifelse(df$important[i], "❗️ ", ""),
                                             df$flag[i], " ", df$title[i]),
                            description = df$link[i],
                            tz = tz)
    writeLines(ic_char, con = f)
  }))
  writeLines(footer, con = f)
  close(f)
}

export_calendar(upcoming_stats, file = "output/biz_cal.ics", tz = "GMT")