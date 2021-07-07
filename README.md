
# Kellogg Garden's Freight Data Analysis in GCP

A brief description of how to load, clean, analyze and visualize a historical freight dataset


## Authors

- [@pedroheyerdahl](https://github.com/pedroheyerdahl/)
## Summary

- Exporting to csv with sheets
- Loading in Bigquery
- Cleaning the data
- Data enrichment

## Exporting to csv

BigQuery supports [querying Drive data](https://cloud.google.com/bigquery/external-data-drive) as an external data source. But, since the original dataset was provided as a xlsx file with three tabs (zip_to_zip, accessorials and data),
in order to load the data to Bigquery, first it was neccessary to split each tab into a different file.

After uploading the original file to Drive, each tab was copyied to a different spreadsheet and later renamed accordingly.

Any extra carriage returns were removed prior to loading in BQ, using Google Sheet's Find and Replace GUI tool and searching line breaks characters with regex.

## Loading into BigQuery
After retrieving the Drive URI for each spreadsheet, a permanent table linked to the external data source was created using the bq command-line tool's `mk` command:
```
bq mk \
--external_table_definition=[SCHEMA]@[SOURCE_FORMAT]=[DRIVE_URI] \
DATASET.TABLE
```
```
bq mk \
--external_table_definition=Shipping_Warehouse:STRING,Assigned_Customer_Warehouse:STRING,Base_T_L_H_Nbr:INTEGER,SO____T_R_:STRING,Customer:INTEGER,custname:STRING,shipdate:DATE,Zip:STRING,Has_Stops_Over:BOOLEAN,_Contract__Freight_:STRING,_Freight_Amount_:STRING,_Discrepancy_Amount_:STRING,_Grand_Total_:STRING,T_L_H_Comments:STRING,Posted:STRING,Customer_PO_Number:STRING,Carrier:STRING,Shipment_:STRING,State:STRING@GOOGLE_SHEETS=https://docs.google.com/spreadsheets/d/1lHzmgg0C9kXHTFI3a5d_AORTB_CB7xTG44pIcvRGYGM/edit?usp=sharing \
kellogg.raw_data

bq mk \
--external_table_definition=Shipping_Warehouse:STRING,Assigned_Customer_Warehouse:STRING,Base_T_L_H_Nbr:INTEGER,SO____T_R_:STRING,Customer:INTEGER,custname:STRING,shipdate:DATE,Zip:STRING,Has_Stops_Over:BOOLEAN,_Contract__Freight_:STRING,_Freight_Amount_:STRING,_Discrepancy_Amount_:STRING,_Grand_Total_:STRING,T_L_H_Comments:STRING,Posted:STRING,Customer_PO_Number:STRING,Carrier:STRING,Shipment_:STRING,State:STRING@GOOGLE_SHEETS=https://docs.google.com/spreadsheets/d/1n1km521AlxMzY8NmHPht4KnJXDtI_NQF3Imt_XP_1wY/edit?usp=sharing \
kellogg.raw_accessorials


bq mk \
--external_table_definition=Ship_Zip:INTEGER,Deliver_Zip:INTEGER,_Grand_Total_:STRING,State:STRING,Customer:INTEGER,custname:STRING,shipdate:DATE,Has_Stops_Over:BOOLEAN,_Contract__Freight_:STRING,_Freight_Amount_:STRING,_Discrepancy_Amount_:STRING,T_L_H_Comments:STRING,Posted:BOOLEAN,Customer_PO_Number:STRING,Carrier:STRING,Shipment_:STRING@GOOGLE_SHEETS=https://docs.google.com/spreadsheets/d/1n4dAba8CmGCKxr70yf0Z7xO5xxdwO7iBTOecLRLgi2s/edit?usp=sharing \
kellogg.raw_zip_to_zip
```
## Cleaning the data
After loading the data into BQ, a regex function removes special characters from currency columns, such as `$` and `-`. This same function transforms zeroed values to `NULL`.
Next, duplicated shipments are discarded, and so are the rows with null 'grand_total' amounts. 
Finally, the external connection data is materialized into a native Bigquery table with the project's default column naming convention.

## Quality assessment
Since the original file has three different tabs with duplicate columns, a script evaluates the summary of distinct and null counts for each dimension and the min-max ranges for each metric.

|Column | Distinct | Null | Min | Max | Avg |
|-------|----------|------|-----|-----|-----|
|consignee_id|2978|0|2800401|9905624|-|
|consignee_name|2978|0|-|-|
|ship_date|0|0|2018-07-02|2021-06-21|-|
|has_stops_over|2|0	|-|-|-|
|contract_price|335|48370|10|2000|464.68|
|freight_price|4195|2483|10|50000|500.51|
|discrepancy_amount|2487|62079|0.04|4150|339.14|
|final_price|4634|0|23.14|50000|564.94|
|was_posted|1|0|-|-|-|
|cust_po|78173|3067|-|-|-|
|carrier|392|2|-|-|-|
|load_id|82323|0|-|-|-|
|state|52|22|-|-|-|

At this step, all of the metrics display a healthy amount of null values and min-max ranges (other than a suspect 50k final_price max value).
Since no discrepancies were found, with all columns having the same value across tables, from this point on, the analysis is based almost exclusively on the zip_to_zip table. The only exception being the shipper_id, that will be joined from the accessorials table in the next step.

## Data enrichment
