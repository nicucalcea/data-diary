library(tidyverse)
library(lubridate)
library(openxlsx)
library(googlesheets4)

#################################################################
##                  Scrape individual sources                  ##
#################################################################

# 🇬🇧 UK: ONS
source("R/sources/ons.R")

# 🇬🇧 UK: GOV.UK
source("R/sources/gov-uk.R")

# 🇬🇧 UK: Nomis
source("R/sources/nomis.R")

# # 🇬🇧 UK: Bank of England (+ bank rate)
# source("R/sources/boe.R")

# # 🇬🇧 UK: Office for Budget Responsibility
# source("R/sources/obr.R")

# # 🇬🇧 UK: Halifax
# source("R/sources/halifax.R")

# # 🇬🇧 UK: NHS Digital
# source("R/sources/nhs-digital.R")

# # 🇬🇧 UK: Ofcom
# source("R/sources/ofcom.R")

# # 🇬🇧 UK: Office of Rail and Road
# source("R/sources/orr.R")

# # 🇬🇧 UK: Civil Aviation Authority
# source("R/sources/caa.R")

# # 🇬🇧 UK: Office for Students
# source("R/sources/ofs.R")

# # 🇬🇧 UK: Kantar
# source("R/sources/kantar.R")

# 🇪🇺 EU: Eurostat
source("R/sources/eurostat.R")

# 🇺🇸 US: Bureau of Labor Statistics
source("R/sources/bls.R")

# 🌍 International: UN
source("R/sources/un.R")

# # 🌍 International: OECD
# source("R/sources/oecd.R")

# 🌍 International: IMF
source("R/sources/imf.R")

# 🌍 International: IEA
source("R/sources/iea.R")

# 🌍 International: Financial earnings
source("R/sources/earnings.R")

#################################################################
##                      Classify releases                      ##
#################################################################

# business_keywords <- c("agriculture in the united kingdom", "annual population survey", "apprenticeship", "balance sheet", "bank rate", "benefit sanctions", "budget allocation", "business", "capital acquisitons", "capital formation", "capital stocks", "claimant count", "construction output", "consumer price", "cost of living", "CPI(H)", "credit union", "domestic rates", "earnings and employment", "earnings and expenses", "economic activity", "Economic and fiscal outlook", "economic estimates", "economic statistics", "economic well-being", "electric vehicle", "electricity consumption", "employed people", "employee earnings", "employer skills survey", "employment cost index", "employment situation", "employment survey", "energy consumption in the UK", "energy performance of building certificates", "family food", "fiscal risk", "fuel prices", "foreign direct investment", "fuel sales", "gdp", "government debt", "gross domestic", "HICP", "house building", "house price", "household costs", "household energy efficiency", "household income", "housing benefit", "housing purchase affordability", "housing survey", "HMRC survey compliance cost", "import and export", "income estimates", "income from farming", "index of production", "index of services", "industrial turnover", "inflation euro area", "interest rate", "international reserves", "insolvency", "job openings", "job seekers", "kantar", "labour", "labor", "market data", "mergers and acquisitions", "money and credit", "national accounts", "pay gap", "price index", "pricing trends", "producer price", "productivity", "profitability", "public sector employment", "public sector finances", "rail fares", "rail passenger numbers", "rail performance", "real earnings", "rental prices", "rental sector", "retail sales", "revenues and expenses", "revenues and spend", "stamp duty", "taxpayers", "tax credit", "tax receipt", "tax relief", "time use", "trade", "trends and prices", "uk economic accounts", "uk energy in brief", "uk energy statistics", "union membership", "universal credit", "unemployment", "vehicle licensing statistics", "weekly earnings", "working and workless", "world economic outlook") |>
  # paste(collapse = "|")

# important_keywords <- c("Bank of England Bank Rate", "Consumer price inflation, UK", "GDP monthly estimate", "GDP quarterly national accounts", "Retail sales", "UK labour market", "Public sector finances", "world economic outlook") |>
  # paste(collapse = "|")


globalwitness_keywords <- c("climate", "environment", "renewable", "batter", "fossil", "petrol", "oil", "gas", "lng", "carbon", "emission", "green", "energy", "mining", "mines", "mineral", "commodit", "forest") |>
  paste(collapse = "|")

globalwitness_sources <- c("IEA", "Earnings")


#################################################################
##                           Combine                           ##
#################################################################

upcoming_stats <- gov_uk |>
  filter(!title %in% c(ons$title
                       # , nhs_digital$title, ofcom$title
                       )) |>
  mutate(source = "GOV.UK") |>
  bind_rows(ons |> mutate(source = "ONS")) |>
  bind_rows(nomis |> mutate(source = "Nomis")) |>
  # bind_rows(boe |> mutate(source = "Bank of England")) |>
  # bind_rows(obr |> mutate(source = "OBR")) |>
  # bind_rows(halifax |> mutate(source = "Halifax")) |>
  # bind_rows(nhs_digital |> mutate(source = "NHS Digital")) |>
  # bind_rows(ofcom |> mutate(source = "Ofcom")) |>
  # bind_rows(orr |> mutate(source = "ORR")) |>
  # bind_rows(caa |> mutate(source = "CAA")) |>
  # bind_rows(ofs |> mutate(source = "OFS")) |>
  # bind_rows(kantar |> mutate(source = "Kantar")) |>
  bind_rows(eurostat |> mutate(source = "Eurostat", country = "European Union")) |>
  bind_rows(bls |> mutate(source = "BLS", country = "United States")) |>
  bind_rows(un |> mutate(source = "UN", country = "International")) |>
  # bind_rows(oecd |> mutate(source = "OECD", country = "International")) |>
  bind_rows(imf |> mutate(source = "IMF", country = "International")) |>
  bind_rows(iea |> mutate(source = "IEA", country = "International")) |>
  bind_rows(earnings |> mutate(source = "Earnings", country = "International")) |>
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
         # important = grepl(important_keywords, title, ignore.case = T),
         # business = grepl(business_keywords, title, ignore.case = T) | isTRUE(business),
         globalwitness = grepl(globalwitness_keywords, title, ignore.case = T) | source %in% globalwitness_sources) |>
  arrange(date, country, business, title)

##################################################################
##                        Write to Excel                        ##
##################################################################

# write_excel_data <- function(data, file_path) {
#   calendar_sheets <- data |>
#     filter(date >= lubridate::floor_date(Sys.Date()),
#            # date < lubridate::ceiling_date(Sys.Date() %m+% months(1), "month"),
#            globalwitness) |>
#     select(Country = country, Release = title, Date = date, link) |>
#     identity()
#
#   # create and write workbook
#   wb <- createWorkbook()
#   addWorksheet(wb, "df_sheet")
#
#   class(calendar_sheets$link) <- "hyperlink" # mark as a hyperlink
#   writeData(wb, "df_sheet", calendar_sheets$link, startCol = which(colnames(calendar_sheets) == "Release"), startRow = 2)
#
#   calendar_sheets <- calendar_sheets |>
#     select(-link) |>
#     mutate(Date = as.character(Date))
#
#   writeData(wb, "df_sheet", calendar_sheets) # overwrite the sheet to get the new pretty name overlaying the hyperlink
#
#   saveWorkbook(wb, "output/globalwitness_cal.xlsx", overwrite = TRUE)
# }
#
#
# write_excel_data(upcoming_stats, file_path)

##----------------------------------------------------------------
##                    Write to Google Sheets                     -
##----------------------------------------------------------------

write_sheets_cal <- function() {

  calendar_google_sheets <- upcoming_stats |>
    filter(date >= lubridate::floor_date(Sys.Date()),
           # date < lubridate::ceiling_date(Sys.Date() %m+% months(1), "month"),
           globalwitness) |>
    mutate(title = gs4_formula(
      paste0('=HYPERLINK("', link, '", "', title, '")')
    )) |>
    select(flag, country, title, date) |>
    identity()

  range_clear("https://docs.google.com/spreadsheets/d/1SAPy0tfzRN66ngdblNeEFhbGy8Q5V96C0DeC9qRo6Wc/edit#gid=891834841", sheet = "Full Schedule", range = "B4:F")

  range_write("https://docs.google.com/spreadsheets/d/1SAPy0tfzRN66ngdblNeEFhbGy8Q5V96C0DeC9qRo6Wc/edit#gid=891834841", calendar_google_sheets, sheet = "Full Schedule", range = "B4")

}

write_sheets_cal()

##################################################################
##                         Create .ical                         ##
##################################################################

write_ical <- function() {

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
    df <- df |> filter(globalwitness)
    f <- file(file)
    open(f, "w")
    writeLines(header, con = f)
    invisible(lapply(1:nrow(df), \(i) {
      ic_char <- format_event(start = df$date[i], end = df$date[i] + 1,
                              summary = paste0(
                                # ifelse(df$important[i], "❗️ ", ""),
                                               df$flag[i], " ", df$title[i]),
                              description = df$link[i],
                              tz = tz)
      writeLines(ic_char, con = f)
    }))
    writeLines(footer, con = f)
    close(f)
  }

  export_calendar(upcoming_stats, file = "output/globalwitness_cal.ics", tz = "GMT")

}

write_ical()
