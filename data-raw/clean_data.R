library(tidyverse)
library(googleCloudStorageR)

# TODO personnel
# TODO title
# TODO keyword set
# TODO funding
# TODO project
# TODO coverage

# pull in data from google cloud ---------------------------------------------------

gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

gcs_get_object(object_name = "standard-format-data/standard_adult_upstream_passage.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "standard_adult_passage.csv"),
               overwrite = TRUE)

gcs_get_object(object_name = "standard-format-data/standard_adult_passage_estimate.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "standard_adult_passage_estimate.csv"),
               overwrite = TRUE)

up_raw <- read.csv(here::here("data-raw", "standard_adult_passage.csv")) |>
  filter(stream == "yuba river")

up_estimates_raw <- read.csv(here::here("data-raw", "standard_adult_passage_estimate.csv")) |>
  filter(stream == "yuba river")

# clean data --------------------------------------------------------------
up <- up_raw |>
  select(-c(run, sex, viewing_condition, spawning_condition,
            jack_size, flow, temperature, comments,
            confidence_in_sex, status, fork_length, dead)) |>
  select(-stream) |>
  glimpse()

up_estimates <- up_estimates_raw |>
  select(-c(ucl, lcl, confidence_interval, ladder, stream)) |>
  glimpse()

# write files -------------------------------------------------------------
write.csv(up, here::here("data", "yuba_upstream_passage.csv"), row.names = FALSE)
write.csv(up_estimates, here::here("data", "yuba_upstream_passage_estimates.csv"), row.names = FALSE)

# review ------------------------------------------------------------------
read.csv(here::here("data", "yuba_upstream_passage_estimates.csv")) |> glimpse()
read.csv(here::here("data", "yuba_upstream_passage.csv")) |> glimpse()


