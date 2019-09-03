#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
source("functions.R")

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Rsrat: Software Reliability Assessment Tool on R"),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
     sidebarPanel(
       fileInput("file", "Choose CSV File",
                 accept = c(
                   "text/csv",
                   "text/comma-separated-values,text/plain",
                   ".csv")
       ),
       radioButtons("type", "Data type", choices = c("Count", "General")),
       tags$hr(),
       htmlOutput("time"),
       htmlOutput("fault"),
       htmlOutput("indicator"),
       checkboxGroupInput("models", "Models:", choices = srm.models, selected = srm.models),
       actionButton("submit", "Estimate"),
       tags$hr(),
       actionButton("execeic", "Estimate and Compute EIC")
     ),
     
      # Show a plot of the generated distribution
      mainPanel(
        tabsetPanel(type = "tabs", id = "mantabs",
                    tabPanel("Data", value = "tab1", tableOutput('table')),
                    tabPanel("Result", value = "tab2", plotOutput('mvf'), dataTableOutput('result')),
                    tabPanel("Evaluation", value = "tab3", dataTableOutput('eval'))
        )
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {

  models <- reactive(c(input$models))
  
  csv_file <- reactive(read.csv(input$file$datapath))

  data <- reactive({
    if (input$type == "Count") {
      x <- csv_file()[[input$time]]
      y <- csv_file()[[input$fault]]
      faultdata(time=x, fault=y)
    } else if (input$type == "General") {
      x <- csv_file()[[input$time]]
      y <- csv_file()[[input$fault]]
      z <- csv_file()[[input$indicator]]
      faultdata(time=x, fault=y, type=z)
    }
  })

  estimate <- reactive({
    estimate.ordinary(data(), models())
    # result <- c(result, estimate.cph(data, 2:10))
  })

  observeEvent(input$file, {
    output$table <- renderTable(csv_file())

    output$time <- renderUI({
      selectInput("time", "Time interval", colnames(csv_file()))
    })
    
    output$fault <- renderUI({
      selectInput("fault", "# of faults", colnames(csv_file()))
    })
    
    output$indicator <- renderUI({
      if (input$type == "General") {
        selectInput("indicator", "Indicator", colnames(csv_file()))
      }
    })
  })
  
  observeEvent(input$submit, {
    result <- estimate()

    output$result <- renderDataTable(
      gof(result, eic = FALSE), options = list(paging = FALSE, searching = FALSE)
    )

    output$eval <- renderDataTable(
      reliab(lapply(models(), function(m) result[[m]])), options = list(paging = FALSE, searching = FALSE)
    )

    output$mvf <- renderPlot({
      mvfplot(data = data(), mvf=lapply(models(), function(m) result[[m]]$srm))
    })

    updateTabsetPanel(session, "mantabs", selected = "tab2")
  })

  observeEvent(input$execeic, {
    result <- estimate()

    output$result <- renderDataTable(
      gof(result, eic = TRUE), options = list(paging = FALSE, searching = FALSE)
    )
    
    output$eval <- renderDataTable(
      reliab(lapply(models(), function(m) result[[m]])), options = list(paging = FALSE, searching = FALSE)
    )
    
    output$mvf <- renderPlot({
      mvfplot(data = data(), mvf=lapply(models(), function(m) result[[m]]$srm))
    })
    
    updateTabsetPanel(session, "mantabs", selected = "tab2")
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

