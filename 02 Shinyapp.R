# Load packages and data
# library(pacman)
# p_load(rio, 
#        shiny, 
#        shinydashboard, 
#        plotly, 
#        readr, 
#        tidyverse)

library(shiny)
library(shinydashboard)
library(plotly)
library(readr)
library(tidyverse)
library(rio)
    
KGIdata_original <- rio::import(file = "rsconnect/shinyapps.io/milanschroeder/KGI.Rdata")

# Define UI ----------------------------------------------------------------
header <- dashboardHeader(title = "How globalized is the world? The Kessler Globality Index",
                          titleWidth = 750)

sidebar <- dashboardSidebar(
    sidebarMenu(
        menuItem("About", 
                 tabName = "model", 
                 icon = icon("book"),
                 
                 menuItem("Method", 
                           href = "https://github.com/intro-to-data-science-21/data-project-globalization_dashboard/blob/main/README.md#kessler-globality-index-kgi",
                           newtab = F),
                 
                 menuItem("Full Report", 
                          href = "https://github.com/intro-to-data-science-21/data-project-globalization_dashboard/blob/main/README.md",
                          newtab = F),
                 
                 menuItem("Sources", 
                             menuSubItem(text = "Kessler (2016)", 
                                         href = "https://link.springer.com/book/10.1007/978-3-658-02388-1",
                                         newtab = F),
                             menuSubItem(text = "Schröder (2020)", 
                                         href = "https://hertieschool-my.sharepoint.com/:b:/g/personal/204856_hertie-school_org/EWp8tWUAvD5IjOmgbVoQjd8BaXL1bQNd_nuxH0u5ftVhoQ",
                                         newtab = F)),
                 
                 menuItem("Contributors", 
                             menuSubItem(text = "Francesco Danovi, Università Bocconi",
                                         href = "https://it.linkedin.com/in/francesco-danovi-189152186",
                                         newtab = F),
                             menuSubItem(text = "Federico Mammana, Università Bocconi",
                                         href = "https://www.linkedin.com/in/federico-mammana/",
                                         newtab = F),
                             menuSubItem(text = "Milan Schröder, Hertie School",
                                         href = "https://www.linkedin.com/in/milan-schroeder/",
                                         newtab = F))),
        
         menuItem("Controls", tabName = "model", icon = icon("mouse"), startExpanded = T,
                 sliderInput("year", "Select year", 1990, 2020, 2017, step = 1, sep = "", animate = T),
                 checkboxInput("small_include", 
                               "Include small countries? (pop. < 1 Mio.)", 
                               value = FALSE),
                 
                 sliderInput("min_vars", 
                             "Min. Number of Indicators", 
                             1, 7, 3),
                 
                 selectInput("version",
                             "KGI version:",
                             c("Kessler (2016)" = "KGI_original",
                               "Schröder (2020)" = "KGI_new"))),
        
        menuItem("Link to Code", 
                 href = "https://github.com/intro-to-data-science-21/data-project-globalization_dashboard",
                 icon = icon("code"),
                 newtab = F),
        menuItem("Download Data", 
                 icon = icon("save"),
                 menuItem(text = ".csv", 
                          href = "https://github.com/intro-to-data-science-21/data-project-globalization_dashboard/raw/main/data_processed/KGI.csv",
                          newtab = F),
                 menuItem(text = ".xlsx", 
                          href = "https://github.com/intro-to-data-science-21/data-project-globalization_dashboard/raw/main/data_processed/KGI.xlsx",
                          newtab = F),
                 menuItem(text = ".Rdata", 
                          href = "https://github.com/intro-to-data-science-21/data-project-globalization_dashboard/raw/main/data_processed/KGI.Rdata",
                          newtab = F)),
    collapsed = F
    ),
  width = 300
)

body <- dashboardBody(
    fluidRow(
       column(3,
              wellPanel(
                  h4("Most globalized countries"), 
                      tableOutput("ranking"))),
       column(9,
              plotlyOutput("world_map"))),

    fluidRow(
      wellPanel(
        htmlOutput("description"))),
    
    fluidRow(
      column(12,
             span("For detailled information consult our methods.",
                  align = "right"))),
    fluidRow(
      column(12,
             span("Note: Since all indicators are computed on a per capita basis, including small countries may produce an uniformative ranking.",
                  align = "right"))),
    fluidRow(
      column(12,
             span("Data for 2020 should tread lightly due to the effects of the COVID-19 pandemic.",
                  align = "right")))
)
    
ui <- dashboardPage(skin = "red",
                    header, 
                    sidebar, 
                    body
)

# Define Server -----------------------------------------------------------
server <- function(input, output, session) {
    
  # creating temp vars here to filter:
  filtered_data <- reactive({
    year <- input$year
    small_include <- input$small_include
    min_vars <- input$min_vars
    version <- input$version
  
  # filtering data:
    KGIdata_filtered <- KGIdata_original %>% 
      mutate(KGI =  ifelse(version == "KGI_original",
                           KGI_original,
                           KGI_new),
             n_vars = ifelse(version == "KGI_original",
                             n_vars_original,
                             n_vars_new),
             indicators_max = ifelse(version == "KGI_original",
                                     7,
                                     6),
             hover = paste0(country, "\nKGI: ", KGI, "\nIndicators available: ", n_vars, "/", indicators_max)) %>%
      filter(ifelse(small_include == T,
                      !is.na(small), 
                      small == F),
             date == year,
             n_vars >= min_vars) %>% 
      # just to make sure:
      as.data.frame() %>% 
      arrange(desc(KGI))
    KGIdata_filtered
    })  
    
    # construct Top10 list:
    output$ranking <- renderTable({
        filtered_data() %>% 
            select(country, KGI) %>%
            arrange(desc(KGI)) %>% 
        head(10)
    })
    
    # construct worldmap:
    output$world_map <- renderPlotly({
        # Define plotly map's properties, font, labels, and layout
        graph_properties <- list(
        scope = 'world',
        showland = TRUE,
        landcolor = toRGB("lightgrey"),
        color = toRGB("lightgrey"))
        
        font = list(
        family = "DM Sans",
        size = 15,
        color = "black")
        
        label = list(
        bgcolor = "#EEEEEE",
        bordercolor = "gray",
        font = font)
        
        borders_layout <- list(color = toRGB("grey"), width = 0.5)
        
        map_layout <- list(
        showframe = FALSE,
        showcoastlines = TRUE,
        projection = list(type = 'Mercator'))
        # Build actual plotly map
        world_map = plot_geo(filtered_data(), 
                         locationmode = "world", 
                         frame = ~ date) %>%
            add_trace(locations = ~ iso3c,
                  z = ~ KGI,
                  zmin = 0,
                  zmax = 100,
                  color = ~ KGI,
                  colorscale = "Inferno",
                  text = ~ hover,
                  hoverinfo = 'text') %>%
            layout(geo = map_layout,
                   font = list(family = "DM Sans")) %>%
            style(hoverlabel = label) %>%
            config(displayModeBar = FALSE)
    })
  
    # include short description of chosen index:
    output$description <- renderText({
      ifelse(input$version == "KGI_original",
        "<p> The Kessler Globality Index (KGI) is a clear and effective measure of the level of globality, i.e. the level of transboarder interaction between people (see Kessler 2016). 
          <br> It comprises seven highly intercorrelated, theoretically valid indicators all loading strongly on one common factor: </p>
            <ul>
              <li> volume of international trade in goods and services (World Development Indicators)</li>
              <li> foreign direct investments, inflows and outflows (World Development Indicators)</li>
              <li> international tourism, arrivals and departures (World Development Indicators)</li>
              <li> international meetings (Union of International Associations)</li>
              <li> international arrivals and departures at commercial airports (International Civil Aviation Organization)</li>
              <li> international incoming and outgoing telephone traffic in minutes (International Telecommunications Union)</li>
              <li> share of individuals using the internet (International Telecommunications Union)</li>
            </ul>",
        
        "<p> The refined version of the Kessler Globality Index (KGI) is a clear and effective measure of the level of globality, i.e. the level of transboarder interaction between people (see Schröder 2020). 
          <br> It comprises six highly intercorrelated, theoretically valid indicators all loading strongly on one common factor: </p>
            <ul>
              <li> volume of international trade in goods, services, and primary income (World Development Indicators)</li>
              <li> foreign direct investments, inflows and outflows (World Development Indicators)</li>
              <li> international tourism, arrivals and departures (World Development Indicators)</li>
              <li> international meetings (Union of International Associations)</li>
              <li> internationally operated revenue passenger kilometres (International Civil Aviation Organization)</li>
              <li> a communication technology indicator, covering the shift in predominant communication tools, i.e.:
                <ul>
                  <li>until 2005: international incoming and outgoing telephone traffic in minutes (International Telecommunications Union)</li>
                  <li>from 2006: international bandwidth usage in Mbit/s (International Telecommunications Union)</li>
                </ul>
              </li>
            </ul>")
     })
}

# Run the app:
shinyApp(ui = ui, 
         server = server)
