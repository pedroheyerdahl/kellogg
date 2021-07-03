
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

Any extra carriage returns were removed prior to loading in BQ, using regex 

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
After loading the data into BQ, a regex function removes special characters from currency columns, such as "$" and -. This same function transforms zeroed values to NULL.
Next, duplicated shipments are discarded, and so are the rows with null 'grand_total' amounts. 
Finally, the external connection data is materialized into a native Bigquery table with the project's default column naming convention.

