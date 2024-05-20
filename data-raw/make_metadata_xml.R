library(EDIutils)
library(tidyverse)
library(EMLaide)
library(readxl)
library(EML)

datatable_metadata <-
  dplyr::tibble(filepath = c("data/yuba_instantaneous_passage.csv",
                             "data/yuba_daily_uncorrected_passage.csv",
                             "data/yuba_daily_corrected_passage.csv"),
                attribute_info = c("data-raw/metadata/yuba_instantaneous_passage.xlsx",
                                   "data-raw/metadata/yuba_daily_uncorrected_passage.xlsx",
                                   "data-raw/metadata/yuba_daily_corrected_passage.xlsx"),
                datatable_description = c("Instantaneous passage records",
                                          "Uncorrected daily net passage counts",
                                          "Corrected and run differentiated daily passage counts"),
                datatable_url = paste0("https://raw.githubusercontent.com/SRJPE/jpe-yuba-edi/main/data/",
                                       c("yuba_instantaneous_passage.csv",
                                         "yuba_daily_uncorrected_passage.csv",
                                         "yuba_daily_corrected_passage.csv")))

# attach Poxon and Bratovich (2020) pdf
other_entity_metadata <- list("file_name" = "Poxon_and_Bratovich_2020.pdf",
                              "file_description" = "Methods for Lower Yuba River Chinook Salmon Passage and Run Differentiation Analyses",
                              "file_type" = "PDF",
                              "physical" = create_physical("data-raw/metadata/Poxon_and_Bratovich_2020.pdf",
                                                           data_url = "https://raw.githubusercontent.com/FlowWest/edi-battle-clear-rst/main/data-raw/metadata/Poxon_and_Bratovich_2020.pdf"))
other_entity_metadata$physical$dataFormat <- list("externallyDefinedFormat" = list("formatName" = "PDF"))


# save cleaned data to `data/`
excel_path <- "data-raw/metadata/yuba_adult_metadata.xlsx"
sheets <- readxl::excel_sheets(excel_path)
metadata <- lapply(sheets, function(x) readxl::read_excel(excel_path, sheet = x))
names(metadata) <- sheets

abstract_docx <- "data-raw/metadata/abstract.docx"
# methods_docx <- "data-raw/metadata/methods.docx"
methods_md <- "data-raw/metadata/methods.md"

#edi_number <- reserve_edi_id(user_id = Sys.getenv("EDI_USER_ID"), password = Sys.getenv("EDI_PASSWORD"))
edi_number <- "yuba"

dataset <- list() |>
  add_pub_date() |>
  add_title(metadata$title) |>
  add_personnel(metadata$personnel) |>
  add_keyword_set(metadata$keyword_set) |>
  add_abstract(abstract_docx) |>
  add_license(metadata$license) |>
  add_method(methods_md) |>
  add_maintenance(metadata$maintenance) |>
  add_project(metadata$funding) |>
  add_coverage(metadata$coverage, metadata$taxonomic_coverage) |>
  add_datatable(datatable_metadata) |>
  add_other_entity(other_entity_metadata)

# GO through and check on all units
custom_units <- data.frame(id = c("count of fish", "proportion"),
                           unitType = c("dimensionless", "dimensionless"),
                           parentSI = c(NA, NA),
                           multiplierToSI = c(NA, NA),
                           description = c("number of fish counted", "proportion of day operational"))


unitList <- EML::set_unitList(custom_units)

eml <- list(packageId = edi_number,
            system = "EDI",
            access = add_access(),
            dataset = dataset,
            additionalMetadata = list(metadata = list(unitList = unitList))
)
edi_number
EML::write_eml(eml, paste0(edi_number, ".xml"))
EML::eml_validate(paste0(edi_number, ".xml"))

# EMLaide::evaluate_edi_package(Sys.getenv("user_ID"), Sys.getenv("password"), "edi.1047.1.xml")
# EMLaide::upload_edi_package(Sys.getenv("user_ID"), Sys.getenv("password"), "edi.1047.1.xml")

