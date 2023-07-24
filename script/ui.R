#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DT)
list_identifiers = c(
  'CAS',
  'European Community (EC) Number',
  'ICSC Number',
  'NSC Number',
  'UN Number',
  'Pharos Ligand ID',
  'UNII',
  'DSSTox Substance ID',
  'Nikkaji Number',
  'Wikidata',
  'Wikipedia',
  'RXCUI',
  'Metabolomic Workbench ID',
  'ChEMBL ID',
  'NCI Thesaurus Code'
)
list_formula = c("IUPAC Name", "InChI", "InChIKey", "Canonical SMILES")
list_comp_prop = c(
  'Molecular Weight',
  'XLogP3',
  'Hydrogen Bond Donor Count',
  'Hydrogen Bond Acceptor Count',
  'Rotatable Bond Count',
  'Exact Mass',
  'Monoisotopic Mass',
  'Topological Polar Surface Area',
  'Heavy Atom Count',
  'Formal Charge',
  'Complexity',
  'Isotope Atom Count',
  'Defined Atom Stereocenter Count',
  'Undefined Atom Stereocenter Count',
  'Defined Bond Stereocenter Count',
  'Undefined Bond Stereocenter Count',
  'Covalently-Bonded Unit Count',
  'Compound Is Canonicalized'
)
list_exp_prop = c(
  'Physical Description',
  'Color/Form',
  'Odor',
  'Boiling Point',
  'Melting Point',
  'Flash Point',
  'Solubility',
  'Density',
  'Vapor Density',
  'Vapor Pressure',
  'LogP',
  "Henry's Law Constant",
  'Stability / Shelf Life',
  'Decomposition',
  'Corrosivity',
  'Odor Threshold',
  'Other Experimental Properties',
  'Chemical Classes'
)
list_classification = c(
  'MeSH Tree',
  'NCI Thesaurus Tree',
  'ChEBI Ontology',
  'KEGG: Drug',
  'KEGG: ATC',
  'KEGG: Target-based Classification of Drugs',
  'KEGG: JP15',
  'KEGG: Risk Category of Japanese OTC Drugs',
  'KEGG: OTC drugs',
  'KEGG: Drug Groups',
  'KEGG: Drug Classes',
  'WHO ATC Classification System',
  'FDA Pharm Classes',
  'ChemIDplus',
  'CAMEO Chemicals',
  'IUPHAR/BPS Guide to PHARMACOLOGY Target Classification',
  'ChEMBL Target Tree',
  'UN GHS Classification',
  'EPA CPDat Classification',
  'NORMAN Suspect List Exchange Classification',
  'CCSBase Classification',
  'EPA DSSTox Classification',
  'LOTUS Tree',
  'FDA Drug Type and Pharmacologic Classification',
  'EPA Substance Registry Services Tree'
)
# Define UI for application that draws a histogram
ui = fluidPage(# Application title
  titlePanel("PubChem data extraction"),
  tags$head(tags$style(".shiny-notification {position: fixed; top: 45% ;left: 25%; width:50%; font-size: 36px;text-align: center;}")),
  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      fileInput(
        "ID_file",
        "ID_file:",
        accept = c('.csv', '.xls', '.xlsx','.txt'),
        placeholder = 'File of ID (name or CAS)'
      ),
      numericInput('skip', 'Lines of Column names', value = NULL),
      selectInput(
        'Identifiers',
        label = 'Identifiers',
        choices = list_identifiers,
        multiple = T
      ),
      checkboxInput('Synonyms', label = 'Include synonyms'),
      selectInput(
        'Formula',
        label = 'Computed Descriptors',
        choices = list_formula,
        multiple = T
      ),
      
      selectInput(
        'comp_prop',
        label = 'Computed Properties',
        choices = list_comp_prop,
        multiple = T
      ),
      selectInput(
        'exp_prop',
        label = 'Experimental Properties',
        choices = list_exp_prop,
        multiple = T
      ),
      actionButton('launch_search', label = 'Launch the search of info'),
      actionButton('save_output', label = 'Save the output'),
      actionButton('save_unrecovered', label = 'Save unrecovered molecules list')
    ),
    
    # Show a plot of the generated distribution
    mainPanel(textOutput('not_found'),
      DTOutput('tableau'))
  )
)

