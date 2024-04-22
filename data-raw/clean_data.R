library(tidyverse)
library(googleCloudStorageR)

# pull in data from google cloud ---------------------------------------------------

gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

gcs_get_object(object_name = "adult-upstream-passage-monitoring/yuba-river/data-raw/Yuba VAKI Chinook_QAQC instantaneous_v2.xlsx",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "yuba_instantaneous.xlsx"),
               overwrite = TRUE)

gcs_get_object(object_name = "adult-upstream-passage-monitoring/yuba-river/data-raw/Yuba VAKI Chinook_UNCORRECTED Daily Net Upstream Counts.xlsx",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "yuba_uncorrected_daily.xlsx"),
               overwrite = TRUE)

instant_raw <- readxl::read_xlsx(here::here("data-raw", "yuba_instantaneous.xlsx"),
                                       sheet = "Yuba VAKI Chinook")
instant_metadata <- readxl::read_xlsx(here::here("data-raw", "yuba_instantaneous.xlsx"),
                                      sheet = "Metadata",
                                      skip = 7)

daily_uncorrected_raw <- readxl::read_xlsx(here::here("data-raw", "yuba_uncorrected_daily.xlsx"),
                                           sheet = "Uncorr CHN net upstream")
daily_uncorrected_metadata <- readxl::read_xlsx(here::here("data-raw", "yuba_uncorrected_daily.xlsx"),
                                                sheet = "Metadata",
                                                skip = 7)

# clean data --------------------------------------------------------------
instant <- instant_raw |>
  janitor::clean_names() |>
  mutate(date = as.Date(date),
         time = hms::as_hms(time),
         time = as.character(time),
         category = str_to_lower(category),
         ladder = str_to_lower(ladder),
         direction_of_passage = str_to_lower(direction_of_passage),
         adipose_clipped = case_when(category == "chinook ad-clip" ~ "TRUE",
                                     category == "chinook" ~ "FALSE",
                                     category == "chinook ad-undetermined" ~ "undetermined",
                                     TRUE ~ NA),
         species = "chinook",
         count = 1) |>
  select(-category) |>
  glimpse()

daily_uncorrected <- daily_uncorrected_raw |>
  janitor::clean_names() |>
  relocate(north_ladder_vaki_operation, .before = south_ladder_vaki_operation) |>
  pivot_longer(uncorrected_north_net_upstream_count_all_chinook:uncorrected_south_net_upstream_count_ad_clip_chinook,
               values_to = "count",
               names_to = "count_type") |>
  mutate(date = as.Date(date),
         ladder = ifelse(str_detect(count_type, "north"), "north", "south"),
         count_type = ifelse(str_detect(count_type, "ad_clip"), "adipose clipped fish", "total fish"),
         vaki_operation = ifelse(ladder == "north", north_ladder_vaki_operation, south_ladder_vaki_operation)) |>
  select(date, biological_year, ladder, count, count_type, vaki_operation) |>
  glimpse()

# write files -------------------------------------------------------------
write.csv(instant, here::here("data", "yuba_instantaneous_passage.csv"), row.names = FALSE)
write.csv(daily_uncorrected, here::here("data", "yuba_daily_uncorrected_passage.csv"), row.names = FALSE)

# review ------------------------------------------------------------------
read.csv(here::here("data", "yuba_instantaneous_passage.csv")) |> glimpse()
read.csv(here::here("data", "yuba_daily_uncorrected_passage.csv")) |> glimpse()


