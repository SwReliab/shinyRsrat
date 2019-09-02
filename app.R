#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(Rsrat)

result.table <- function(result) {
  ct <- sum(result[[1]]$srm$data$time)
  data.frame(
    name=sapply(result, function(x) x$srm$name),
    llf=sapply(result, function(x) x$llf),
    df=sapply(result, function(x) x$df),
    aic=sapply(result, function(x) x$aic),
    "Residual faults"=sapply(result, function(x) x$srm$residual(ct)),
    FFP=sapply(result, function(x) x$srm$ffp(ct))
  )
}

estimate.group <- function(x, y, models) {
  result <- fit.srm.nhpp(time=x, fault=y, srm.names=models, selection=NULL)
  if (length(models) == 1) {
    result <- list(result)
  }
  result
}

estimate.general <- function(x, y, z, models) {
  result <- fit.srm.nhpp(time=x, fault=y, type=z, srm.names=models, selection=NULL)
  if (length(models) == 1) {
    result <- list(result)
  }
  result
}

change.data.column <- function(input, output, csv_file) {
  output$time <- renderUI({ 
    selectInput("time", "Time interval", colnames(csv_file()))
  })
  output$fault <- renderUI({ 
    selectInput("fault", "# of faults", colnames(csv_file()))
  })
  if (input$type == "Count") {
    output$indicator <- renderUI({})
  } else if (input$type == "General") {
    output$indicator <- renderUI({ 
      selectInput("indicator", "Indicator", colnames(csv_file()))
    })
  }
}

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
       actionButton("submit", "Estimate")
     ),
     
      # Show a plot of the generated distribution
      mainPanel(
        tabsetPanel(type = "tabs", id = "mantabs",
                    tabPanel("Data", value = "tab1", tableOutput('table')),
                    tabPanel("Result", value = "tab2", plotOutput('mvf'), dataTableOutput('result'))
        )
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {

  observeEvent(input$file, {
    csv_file <- reactive(read.csv(input$file$datapath))
    output$table <- renderTable(csv_file())
    change.data.column(input, output, csv_file)
  })
  
  observeEvent(input$submit, {
    models <- c(input$models)
    csv_file <- reactive(read.csv(input$file$datapath))
    
    if (input$type == "Count") {
      x <- csv_file()[[input$time]]
      y <- csv_file()[[input$fault]]
      result <- estimate.group(x, y, models)
    } else if (input$type == "General") {
      x <- csv_file()[[input$time]]
      y <- csv_file()[[input$fault]]
      z <- csv_file()[[input$indicator]]
      result <- estimate.general(x, y, z, models)
    }

    output$result <- renderDataTable(
      result.table(result),
      options = list(paging = FALSE, searching = FALSE)
    )

    output$mvf <- renderPlot({
      mvfplot(data = result[[1]]$srm$data, mvf=sapply(result, function(x) x$srm))
    })

    updateTabsetPanel(session, "mantabs", selected = "tab2")
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

