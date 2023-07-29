rm(list = ls())
library("rstudioapi")
setwd(dirname(getActiveDocumentContext()$path))
library(shiny)
source("ui.R", local = TRUE)
source("server.R")
shinyApp(
  ui = ui,
  server = server
)