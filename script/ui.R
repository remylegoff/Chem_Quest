#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking "Run App" above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DT)
list_identifiers = c(
  "CAS",
  "European Community (EC) Number",
  "ICSC Number",
  "NSC Number",
  "UN Number",
  "Pharos Ligand ID",
  "UNII",
  "DSSTox Substance ID",
  "Nikkaji Number",
  "Wikidata",
  "Wikipedia",
  "RXCUI",
  "Metabolomic Workbench ID",
  "ChEMBL ID",
  "NCI Thesaurus Code"
)
list_formula = c("IUPAC Name", "InChI", "InChIKey", "Canonical SMILES")
list_comp_prop = c(
  "Molecular Weight",
  "XLogP3",
  "Hydrogen Bond Donor Count",
  "Hydrogen Bond Acceptor Count",
  "Rotatable Bond Count",
  "Exact Mass",
  "Monoisotopic Mass",
  "Topological Polar Surface Area",
  "Heavy Atom Count",
  "Formal Charge",
  "Complexity",
  "Isotope Atom Count",
  "Defined Atom Stereocenter Count",
  "Undefined Atom Stereocenter Count",
  "Defined Bond Stereocenter Count",
  "Undefined Bond Stereocenter Count",
  "Covalently-Bonded Unit Count",
  "Compound Is Canonicalized"
)
list_exp_prop = c(
  "Physical Description",
  "Color/Form",
  "Odor",
  "Boiling Point",
  "Melting Point",
  "Flash Point",
  "Solubility",
  "Density",
  "Vapor Density",
  "Vapor Pressure",
  "LogP",
  "Henry's Law Constant",
  "Stability / Shelf Life",
  "Decomposition",
  "Corrosivity",
  "Odor Threshold",
  "Other Experimental Properties",
  "Chemical Classes"
)
list_classification = c(
  "MeSH Tree",
  "NCI Thesaurus Tree",
  "ChEBI Ontology",
  "KEGG: Drug",
  "KEGG: ATC",
  "KEGG: Target-based Classification of Drugs",
  "KEGG: JP15",
  "KEGG: Risk Category of Japanese OTC Drugs",
  "KEGG: OTC drugs",
  "KEGG: Drug Groups",
  "KEGG: Drug Classes",
  "WHO ATC Classification System",
  "FDA Pharm Classes",
  "ChemIDplus",
  "CAMEO Chemicals",
  "IUPHAR/BPS Guide to PHARMACOLOGY Target Classification",
  "ChEMBL Target Tree",
  "UN GHS Classification",
  "EPA CPDat Classification",
  "NORMAN Suspect List Exchange Classification",
  "CCSBase Classification",
  "EPA DSSTox Classification",
  "LOTUS Tree",
  "FDA Drug Type and Pharmacologic Classification",
  "EPA Substance Registry Services Tree"
)
# Define UI for application that draws a histogram
ui = fluidPage(
  # Application title
  titlePanel(title = h1(strong("Chem Quest"), align = "center"),windowTitle = 'Chem Quest'),
  tags$head(
    tags$style(
      ".shiny-notification {position: fixed; top: 45% ;left: 25%; width:50%; font-size: 36px;text-align: center;}"
    )
  ),
  navbarPage(
    "",
    tabPanel(
      "Home",
      h2("Table of contents"),
      tags$nav(tags$ul(
        tags$li(tags$a("What is this ?", href = "#section0")),
        tags$li(tags$a("Format of the input", href = "#section1")),
        tags$li(tags$a("Which features can be extracted ", href = "#section2")),
        tags$li(tags$a("Output format", href = "#section3")),
        tags$li(tags$a("Github Link ", href = "#section4"))
      )),
      tags$section(
        id='section0',
        h2('What is this ?'),
        'This app is a command from some chemistry PhD students to easily and rapidly extract data from PubChem. '
      ),
      tags$section(
        id = "section1",
        h2("Format of the input"),
          "The input can be anything of",
          tags$code(".csv"),
          tags$code(".txt"),
          tags$code(".xls"),
          tags$code(".xlsx"),
          "."
        ,
        tags$br(
          "It must includes a column named ",
          tags$code("Molecules"),
          " in which the ID of the molecules are. This ID can be either the name or the CAS. All other columns are not used."
        ),
          "If the CAS is used then there is a highly probability to recover all molecules."
        ,
        tags$br(
          "Using the name, the chance to recover the properties is highly variable due to mispelling, additional white space. A list of unrecovered molecules would be possible to download to check why there are not recovered."
        )
      ),
      tags$section(id = "section2", 
                   h2("Which features can be extracted"),
                   "Most of the Pubchem features can be extract but here is the exhaustive list",
                   tags$li(tags$b("Synonyms")),
                   tags$li(tags$b("Identifiers : "),
                     tags$code(paste(list_identifiers,collapse = ", "))),
                   tags$li(tags$b("Formula : "),
                     tags$code(paste(list_formula,collapse = ", "))),
                   tags$li(tags$b("Experimental properties : "),
                     tags$code(paste(list_exp_prop,collapse = ", "))),
                   tags$li(tags$b("Computed properties : "),
                     tags$code(paste(list_comp_prop,collapse = ", "))),
                   tags$br("A feature can be extract only if it exists on PubChem. No features can be computed here or scrap from another database."),
                   "For experimental properties, only the first one to appear on the website of each category is extracted (clean extraction and output are under work)"),
      tags$section(id = "section3", 
                   h2("Output"),
                   "Chem Quest output first a view as a datatable with the input name, the CAS, the 2D formula and then the selected features. This datatable can be dowload in a", tags$code("csv"),"format. The 2D formula will appear as the html code to display the image.",
                   tags$br("If any molecules is not recovered for any reason, the unrecovered list can be dowloaded as a",tags$code("csv"), "file, containing the molecules input ID.")),
      
      tags$section(
        id = "section4",
        h2("Github link"),
        tags$a(
          href = "https://github.com/remylegoff/Chem_Quest",
          tags$img(src = "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png",
                   width  = 100, alt = "Github Logo"),
          "Git repository of the project \n"
        ),
        tags$br(),
        "If you have any comment, issue, features to add : ",
        tags$a(href = "https://github.com/remylegoff/Chem_Quest/issues",
               "click here and open an issue"),
      )
    ),
    # Sidebar with a slider input for number of bins
    tabPanel(
      "Features Extraction",
      sidebarLayout(
        sidebarPanel(
          fileInput(
            "ID_file",
            "ID_file:",
            accept = c(".csv", ".xls", ".xlsx", ".txt"),
            placeholder = "File containing IDs (name or CAS) (.csv, .txt, .xlsx, .xls)"
          ),
          numericInput("skip", "Line of Column names", value = NULL),
          h6("One column must be named \"Molecules\" and contains the IDs"),
          selectInput(
            "Identifiers",
            label = "Identifiers",
            choices = list_identifiers,
            multiple = T
          ),
          tags$b(checkboxInput("Synonyms", label = "Include synonyms")),
          selectInput(
            "Formula",
            label = "Computed Descriptors",
            choices = list_formula,
            multiple = T
          ),
          
          selectInput(
            "comp_prop",
            label = "Computed Properties",
            choices = list_comp_prop,
            multiple = T
          ),
          selectInput(
            "exp_prop",
            label = "Experimental Properties",
            choices = list_exp_prop,
            multiple = T
          ),
          actionButton("launch_search", label = "Launch the search of info"),
          actionButton("save_output", label = "Save the output"),
          actionButton("save_unrecovered", label = "Save unrecovered molecules list")
        ),
        
        # Show a plot of the generated distribution
        mainPanel(textOutput("not_found"),
                  DTOutput("tableau"))
      )
    )
  )
)
