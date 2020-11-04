// Databricks notebook source
dbutils.fs.mount(source = "wasbs://rawzone@metadatapocsalesforce.blob.core.windows.net/",
mountPoint = "/mnt/rawzone",
extraConfigs = Map("fs.azure.account.key.metadatapocsalesforce.blob.core.windows.net" -> dbutils.secrets.get(scope = "metadatapocsalesforce", key = "storageaccesskey")))

// COMMAND ----------

dbutils.fs.mount(source = "wasbs://stagezone@metadatapocsalesforce.blob.core.windows.net/",
mountPoint = "/mnt/stagezone",
extraConfigs = Map("fs.azure.account.key.metadatapocsalesforce.blob.core.windows.net" -> dbutils.secrets.get(scope = "metadatapocsalesforce", key = "storageaccesskey")))

// COMMAND ----------

dbutils.fs.mount(source = "wasbs://curatedzone@metadatapocsalesforce.blob.core.windows.net/",
mountPoint = "/mnt/curatedzone",
extraConfigs = Map("fs.azure.account.key.metadatapocsalesforce.blob.core.windows.net" -> dbutils.secrets.get(scope = "metadatapocsalesforce", key = "storageaccesskey")))
