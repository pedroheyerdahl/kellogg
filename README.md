
# Kellogg Garden's Freight Data Analysis in GCP

A brief description of how to load, clean, analyze and visualize a historical freight dataset


## Authors

- [@pedroheyerdahl](https://github.com/pedroheyerdahl/)
## Summary

- Exporting to csv with sheets

- Loading in Bigquery
- Cleaning the data

  ## Exporting to csv

BigQuery supports [querying Drive data](https://cloud.google.com/bigquery/external-data-drive) as an external data source. But, since the original dataset was provided as a xlsx file with many tabs,
in order to load the data to Bigquery, first it was neccessary to split each tab into a different file.

After uploading the original file to Drive, each tab was copyied to a different spreadsheet and later renamed accordingly.

## Loading into BigQuery
After retrieving the Drive URI for each spreadsheet, a permanent table linked to the external data source was created using the bq command-line tool's `mk` command:
```
bq mk \
--external_table_definition=[SCHEMA]@[SOURCE_FORMAT]=[DRIVE_URI] \
DATASET.TABLE
```
