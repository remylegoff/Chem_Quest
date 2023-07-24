get.synonyms = function (name, idtype = NULL, quiet = TRUE) 
{
  curlHandle <- getCurlHandle()
  out <- data.frame(stringsAsFactors = FALSE)
  for (compound in name) {
    tryCatch({
      field = NULL
      if (is.null(idtype)) {
        field <- "name="
        endpoint <- "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/%s/synonyms/XML"
      }
      else if (idtype == "inchikey") {
        field <- "inchikey="
        endpoint <- "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/inchikey/%s/synonyms/XML"
      }
      else if (idtype == "cid") {
        field <- "cid="
        endpoint <- "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/%s/synonyms/XML"
      }
      else stop("Invalid idtype specified")
      res <- dynCurlReader()
      curlPerform(url = sprintf(endpoint, URLencode(compound)), 
                  curl = curlHandle, writefunction = res$update)
      doc <- xmlInternalTreeParse(res$value())
      rootNode <- xmlName(xmlRoot(doc))
      if (rootNode == "InformationList") {
        xpathApply(doc, "//x:Information", namespaces = "x", 
                   function(x) {
                     cid <- xpathSApply(x, "./x:CID", namespaces = "x", 
                                        xmlValue)
                     synonym <- xpathSApply(x, "./x:Synonym", 
                                            namespaces = "x", xmlValue)
                     df <- data.frame(Name = compound, CID = cid, 
                                      Synonym = synonym, stringsAsFactors = FALSE)
                     out <<- rbindlist(list(out, df))
                   })
      }
      else if (rootNode == "Fault") {
        fault <- xpathApply(doc, "//x:Details", namespaces = "x", 
                            xmlValue)
        if (!quiet) {
          print(paste(compound, fault[[1]], sep = ": "))
        }
      }
    }, error = function(e) {
      print(e)
    }, finally = Sys.sleep(0.2))
  }
  rm(curlHandle)
  gc()
  return(out)
}



get_section = function(section){
  sapply(section$Section, function(x){x$TOCHeading})
}

.section.by.heading = function (seclist, heading) 
{
  ret <- Filter(function(x) x$TOCHeading == heading, seclist)
  if (length(ret) == 0) 
    return(NULL)
  return(ret[[1]])
}
.section.handler = function (sec, keep = NULL, ignore = NULL) 
{
  n <- sec$TOCHeading
  if (!is.null(ignore) && n %in% ignore) 
    return(NULL)
  if (!is.null(keep) && !(n %in% keep)) 
    return(NULL)
  ret <- lapply(sec$Information, function(info) {
    if ("Name" %in% names(info)) {
      info.name <- info$Name
    }else {info.name <- ""}
    if (info.name == n){ 
      info.name <- ""
    }
    val <- NA
    info.val <- info$Value
    if ("Number" %in% names(info.val)) {
      val <- as.numeric(info.val$Number)
    } else if ("StringWithMarkup" %in% names(info.val)) {
      elems <- info.val$StringWithMarkup
      val <- elems[[1]][["String"]]
    } else if ("Binary" %in% names(info.val)) {
      val <- info$Value$Binary
    }else if ("DateValue" %in% names(info.val)) {
      val <- info$DateValue
    }else if ("Table" %in% names(info.val)) {
      return(.handle.json.table(info.val$Table))
    }
    ret <- data.frame(val = val, stringsAsFactors = FALSE)
    if (info.name != "" & info.name != "XLogP3-AA") {
      names(ret) <- sprintf("%s.%s", n, info.name)
    }else {
      names(ret) <- n
    }
    return(ret)
  })
  return(ret)
}


get_record = function(cid) {
  url <-
    sprintf("https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/%s/JSON",
            cid)
  if (is.null(page)) {
    warning(sprintf("No data found for %d", cid))
    return(NULL)
  }
  h = basicTextGatherer()
  status = curlPerform(url = url, writefunction = h$update)
  val <- h$value()
  record = RJSONIO::fromJSON(val)$Record
  return(record)
}

get_identifier = function(record, list_identifiers) {
  ret = data.frame(matrix(NA,nrow = 1,ncol = length(list_identifiers)))
  colnames(ret) = list_identifiers
  if (sum(grepl('Identifiers', get_section(record))) == 0) {
    return(c())
  } else{
    ids  = .section.by.heading(record$Section, 
                               get_section(record)[grepl('Identifiers', get_section(record))])
    ids = .section.by.heading(ids$Section,'Other Identifiers')
    ids_val <- lapply(list_identifiers, function(x){
      sec <- .section.by.heading(ids$Section, x)
      if(!is.null(sec)){
        return(unlist(.section.handler(sec)))}
      else{return(NA)}
    })
    ids_val = unlist(ids_val)
    ids_val = ids_val[unique(names(ids_val))]
    ids_val = na.omit(ids_val)
    ret[names(ids_val)] = ids_val
    return(ret)
  }
}


get_synonyms = function(record){
  if (sum(grepl('Identifiers', get_section(record))) == 0) {
    return(c())
  } else{
    ids  = .section.by.heading(record$Section, 
                               get_section(record)[grepl('Identifiers', get_section(record))])
    ids = .section.by.heading(ids$Section,'Synonyms')
    syn = sapply(ids$Section, .section.handler)
    return(paste(unlist(syn),collapse = '\n'))
  }
}

get_formula = function(record, list_formula) {
  ret = data.frame(matrix(NA,nrow = 1,ncol = length(list_formula)))
  colnames(ret) = list_formula
  if (sum(grepl('Identifiers', get_section(record))) == 0) {
    return(c())
  } else{
    ids  = .section.by.heading(record$Section, 
                               get_section(record)[grepl('Identifiers', get_section(record))])
    ids = .section.by.heading(ids$Section,'Computed Descriptors')
    
    ids_val <- lapply(list_formula, function(x) {
      sec <- .section.by.heading(ids$Section, x)
      return(unlist(.section.handler(sec)))
    })
    ids_val = unlist(ids_val)
    ids_val = ids_val[unique(names(ids_val))]
    ret[names(ids_val)] = ids_val
    return(ret)
  }
}

get_comp_prop = function(record, list_comp_prop) {
  ret = data.frame(matrix(NA,nrow = 1,ncol = length(list_comp_prop)))
  colnames(ret) = list_comp_prop
  if (sum(grepl('Properties', get_section(record))) == 0) {
    return(c())
  } else{
    ids  = .section.by.heading(record$Section, 
                               get_section(record)[grepl('Properties', get_section(record))])
    ids = .section.by.heading(ids$Section,'Computed Properties')

    ids_val <- lapply(list_comp_prop, function(x) {
      sec <- .section.by.heading(ids$Section, x)
      return(unlist(.section.handler(sec)))
    })
    ids_val = unlist(ids_val)
    ids_val = ids_val[unique(names(ids_val))]
    ret[names(ids_val)] = ids_val
    return(ret)
  }
}


get_exp_prop = function(record, list_exp_prop) {
  ret = data.frame(matrix(NA,nrow = 1,ncol = length(list_exp_prop)))
  colnames(ret) = list_exp_prop
  if (sum(grepl('Properties', get_section(record))) == 0) {
    return(c())
  } else{
    ids  = .section.by.heading(record$Section, 
                               get_section(record)[grepl('Properties', get_section(record))])
    ids = .section.by.heading(ids$Section,'Experimental Properties')
    prop = list_exp_prop[list_exp_prop %in% get_section(ids)]
    ids_val <- lapply(prop, function(x) {
      sec <- .section.by.heading(ids$Section, x)
      sec = unlist(.section.handler(sec))[1]
      return(sec)
    })
    ids_val = unlist(ids_val)
    ids_val = ids_val[unique(names(ids_val))]
    ret[names(ids_val)] = ids_val
    return(ret)
  }
}

get_classification = function(record, list_classification) {
  ret = data.frame(matrix(NA,nrow = 1,ncol = length(list_exp_prop)))
  colnames(ret) = list_exp_prop
  if (sum(grepl('Classification', get_section(record))) == 0) {
    return(c())
  } else{
    ids  = .section.by.heading(record$Section, 
                               get_section(record)[grepl('Classification', get_section(record))])

    ids_val <- lapply(list_classification, function(x) {
      sec <- .section.by.heading(ids$Section, x)
      sec = unlist(.section.handler(sec))
      return(sec)
    })
    ids_val = unlist(ids_val)
    ids_val = ids_val[unique(names(ids_val))]
    ret[names(ids_val)] = ids_val
    return(ret)
  }
}


