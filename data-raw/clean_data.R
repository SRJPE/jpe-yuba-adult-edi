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

gcs_get_object(object_name = "adult-upstream-passage-monitoring/yuba-river/data-raw/Yuba VAKI Chinook_Corrected & Run Differentiated Daily Passage Estimates.xlsx",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "yuba_corrected_daily.xlsx"),
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

daily_corrected_raw <- readxl::read_xlsx(here::here("data-raw", "yuba_corrected_daily.xlsx"),
                                         sheet = "YubaCorrected&RunDiffChinook")
daily_corrected_metadata <- readxl::read_xlsx(here::here("data-raw", "yuba_corrected_daily.xlsx"),
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

# TODO e-mail methods, abstract and schedule follow up
daily_uncorrected <- daily_uncorrected_raw |>
  janitor::clean_names() |>
  mutate(uncorrected_north_net_upstream_count_no_ad_clip = uncorrected_north_net_upstream_count_all_chinook -
           uncorrected_north_net_upstream_count_ad_clip_chinook,
         uncorrected_south_net_upstream_count_no_ad_clip = uncorrected_south_net_upstream_count_all_chinook -
           uncorrected_south_net_upstream_count_ad_clip_chinook) |>
  select(date, biological_year, uncorrected_north_net_upstream_count_ad_clip_chinook,
         uncorrected_north_net_upstream_count_no_ad_clip, uncorrected_south_net_upstream_count_ad_clip_chinook,
         uncorrected_south_net_upstream_count_no_ad_clip, north_ladder_vaki_operation,
         south_ladder_vaki_operation) |>
  pivot_longer(uncorrected_north_net_upstream_count_ad_clip_chinook:uncorrected_south_net_upstream_count_no_ad_clip,
               values_to = "count",
               names_to = "count_type") |>
  mutate(date = as.Date(date),
         ladder = ifelse(str_detect(count_type, "north"), "north", "south"),
         adipose_clipped = ifelse(str_detect(count_type, "no_ad_clip"), FALSE, TRUE),
         #count_type = ifelse(str_detect(count_type, "ad_clip"), "adipose clipped fish", "total fish"),
         vaki_operation = ifelse(ladder == "north", north_ladder_vaki_operation, south_ladder_vaki_operation)) |>
  select(date, biological_year, ladder, count, adipose_clipped, vaki_operation) |>
  glimpse()

daily_corrected <- daily_corrected_raw |>
  janitor::clean_names() |>
  mutate(spring_early_no_ad_clip_chinook = spring_early_all_chinook - spring_early_ad_clip_chinook,
         spring_late_no_ad_clip_chinook = spring_late_all_chinook - spring_late_ad_clip_chinook,
         fall_no_ad_clip_chinook = fall_all_chinook - fall_ad_clip_chinook,
         # there are some biological years where no run differentiation is completed
         # so here, capture those as "no run" adipose clipped and non-adipose clipped
         no_run_ad_clip_chinook = ifelse(is.na(spring_early_no_ad_clip_chinook) &
                                           is.na(spring_late_no_ad_clip_chinook) &
                                           is.na(fall_no_ad_clip_chinook),
                                         total_ad_clip_chinook, NA),
         no_run_no_ad_clip_chinook = ifelse(is.na(spring_early_no_ad_clip_chinook) &
                                             is.na(spring_late_no_ad_clip_chinook) &
                                             is.na(fall_no_ad_clip_chinook),
                                            total_all_chinook - total_ad_clip_chinook,
                                            NA)) |>
  select(-c(spring_early_all_chinook, spring_late_all_chinook, fall_all_chinook,
            total_all_chinook, total_ad_clip_chinook)) |>
  pivot_longer(spring_early_ad_clip_chinook:no_run_no_ad_clip_chinook,
               names_to = "count_type",
               values_to = "count") |>
  filter(!is.na(count)) |>
  mutate(run = case_when(str_detect(count_type, "spring_early") ~ "early spring",
                         str_detect(count_type, "spring_late") ~ "late spring",
                         str_detect(count_type, "fall") ~ "fall",
                         str_detect(count_type, "no_run") ~ "no run differentiation",
                         TRUE ~ NA),
         adipose_clipped = ifelse(str_detect(count_type, "no_ad_clip"), FALSE, TRUE)) |>
  select(-count_type) |>
  glimpse()

# write files -------------------------------------------------------------
write.csv(instant, here::here("data", "yuba_instantaneous_passage.csv"), row.names = FALSE)
write.csv(daily_uncorrected, here::here("data", "yuba_daily_uncorrected_passage.csv"), row.names = FALSE)
write.csv(daily_corrected, here::here("data", "yuba_daily_corrected_passage.csv"), row.names = FALSE)

# review ------------------------------------------------------------------
read.csv(here::here("data", "yuba_instantaneous_passage.csv")) |> glimpse()
read.csv(here::here("data", "yuba_daily_uncorrected_passage.csv")) |> glimpse()
read.csv(here::here("data", "yuba_daily_corrected_passage.csv")) |> glimpse()


