library(tidyverse)
library(googleCloudStorageR)


# pull in data from google cloud ---------------------------------------------------
# TODO this will be updated to pull from elsewhere ?
# TODO not using upstream passage estimates because they are summarized by year

gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

gcs_get_object(object_name = "standard-format-data/standard_daily_redd.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "standard_daily_redd.csv"),
               overwrite = TRUE)

gcs_get_object(object_name = "standard-format-data/standard_adult_upstream_passage.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "standard_adult_passage_estimate.csv"),
               overwrite = TRUE)

gcs_get_object(object_name = "standard-format-data/standard_carcass.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "standard_carcass.csv"),
               overwrite = TRUE)

redd_raw <- read.csv(here::here("data-raw", "standard_daily_redd.csv")) |>
  filter(stream == "yuba river")

up_raw <- read.csv(here::here("data-raw", "standard_adult_passage_estimate.csv")) |>
  filter(stream == "Yuba River")

carcass_raw <- read.csv(here::here("data-raw", "standard_carcass.csv")) |>
  filter(stream == "yuba river")


# clean data --------------------------------------------------------------
# TODO do we want to use the yuba_redd dataset or the standard? most of these columns are empty
redd <- redd_raw |>
  mutate(date = as.Date(date)) |>
  select(-c(reach, river_mile, fish_guarding, redd_measured, redd_width, redd_length,
            age, age_index, survey_method, run, year, starting_elevation_ft,
            redd_substrate_class, tail_substrate_class, pre_redd_substrate_class)) |> # remove empty columns
  select(-stream) |> # not necessary
  glimpse()

up <- up_raw |>
  select(-c(run, sex, viewing_condition, spawning_condition,
            jack_size, flow, temperature, comments)) |>
  glimpse()

carcass <- carcass_raw |>
  select(-c(survey_method, reach, run, mark_recapture, tag_id,
            tag_col, week, head_tag)) |> # empty
  select(-stream) |> # no need
  glimpse()


# write files -------------------------------------------------------------
write.csv(redd, here::here("data", "yuba_redd.csv"), row.names = FALSE)
write.csv(up, here::here("data", "yuba_upstream_passage.csv"), row.names = FALSE)
write.csv(carcass, here::here("data", "yuba_carcass.csv"), row.names = FALSE)


# review ------------------------------------------------------------------
read.csv(here::here("data", "yuba_redd.csv")) |> glimpse()
read.csv(here::here("data", "yuba_upstream_passage.csv")) |> glimpse()
read.csv(here::here("data", "yuba_carcass.csv")) |> glimpse()


