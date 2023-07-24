#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(data.table)
library(shiny)
library(shinyjs)
library(shinyFiles)
library(tidyverse)
library(readxl)
library(DT)
library(RCurl)
library(RJSONIO)
library(XML)
library(datasets)
library(caret)
library(htmlwidgets)
source('./fonctions_pubchem.R')
# Define server logic libraryd to draw a histogram
server = function(input, output, session) {
  observe({
    name = input$ID_file$datapath
    if (grepl('csv$', name)) {
      data = read.csv2(name, skip =1-1)
    } else if (grepl('xls$', name)) {
      data = read_excel(name, skip = input$skip-1)
    } else if (grepl('xlsx$', name)) {
      data = read_xlsx(name, skip = input$skip-1)
    } else if (grepl('txt$', name)) {
      data = read.table(name, skip = input$skip-1, h=T)
    } else{
      warning('unknown file type')
    }
    total_res = c()
    not_found = c()
    n = length(data$Molecules)
    i = 1
    withProgress(min = 0, max = n, value = 0,message = paste('Molecules : 0 /',n),expr = {
      for (nom in data$Molecules) {
        cid  = get.synonyms(nom)$CID[1]
        if (is.null(cid)) {
          nom2 = gsub(' ', '', nom)
          cid = get.synonyms(nom2)$CID[1]
          if (is.null(cid)) {
            not_found = c(not_found, nom)
            n = n-1
            next
          }
        }
        record  = tryCatch({
          record = get_record(cid)
          record
        },error = function(e){NULL})
        if(is.null(record)){
          not_found = c(not_found, nom)
          n=n-1
          next
        }
        if (!is.null(input$Identifiers)) {
          identifiers = get_identifier(record, input$Identifiers)
        } else{
          identifiers = NA
        }
        if (F) {
          syn = get_synonyms(record)
        } else{
          syn = NA
        }
        mol_form <-
          .section.by.heading(record$Section, "Names and Identifiers")
        mol_form =  .section.by.heading(mol_form$Section, 'Molecular Formula')
        mol_form = unlist(.section.handler(mol_form))
        mol_form = unique(mol_form)[1]
        if (!is.null(input$Formula)) {
          formula = get_formula(record, input$Formula)
        } else{
          formula = NA
        }
        if (!is.null(input$comp_prop)) {
          comp_prop = get_comp_prop(record, input$comp_prop)
        } else{
          comp_prop = NA
        }
        if (!is.null(input$exp_prop)) {
          exp_prop = get_exp_prop(record, input$exp_prop)
        } else{
          exp_prop = NA
        }
        # if (!is.null(input$classification)) {
        #   classification = get_classification(record, input$classification)
        # } else{
        #   classification = c()
        # }
        res = cbind.data.frame(
          data.frame(
            Molecules = nom,
            'Formula' = mol_form,
            Structure =  sprintf(
              '<img src="https://pubchem.ncbi.nlm.nih.gov/image/imgsrv.fcgi?cid=%s&t=l"></img>',
              cid
            )
          ),
          identifiers,
          'Synonyms' = syn,
          formula,
          comp_prop,
          exp_prop
          # classification
        )
        total_res = rbind(total_res, res)
        incProgress(amount = 1,
          message = paste('Molecules: ', i, '/', n))
        i = i + 1
      }
      shiny::setProgress(value = 1, message = 'All done')
    })
    
    total_res = Filter(function(x){! all(is.na(x))}, total_res)
    rownames(total_res) = data$Molecules[!(data$Molecules %in% not_found)]
    assign('tableau', total_res, envir = globalenv())
    output$not_found = renderText(paste('Number of molecules not recovered : ',length(not_found)))
    assign('not_found',not_found, envir =  globalenv())
    output$tableau = renderDT({
      DT::datatable(total_res,
                    escape = FALSE,
                    rownames = F)
    })
  }) %>%
    bindEvent(input$launch_search)
  
  
  
  observe({
    path = choose.dir()
    oldpath = getwd()
    setwd(path)
    write.csv2(
      x = as.data.frame(tableau),
      file = here::here(
        paste0('list_molecules_properties_pubchem_', Sys.Date(), '.csv')
      ),
      row.names = F
    )
    setwd(oldpath)
  }) %>%
    bindEvent(input$save_output)
  observe({
    path = choose.dir()
    oldpath = getwd()
    setwd(path)
    write.csv2(
      x = as.data.frame(tableau),
      file = here::here(
        paste0('unrecovered_molecules_pubchem_', Sys.Date(), '.csv')
      ),
      row.names = F
    )
    setwd(oldpath)
  }) %>%
    bindEvent(input$save_unrecovered)
  
  session$onSessionEnded(function() {
    stopApp()
  })
}
