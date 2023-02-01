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
       textInput("query", "Query for ASF JIRA", value =""),
       actionButton("getdata", "Get Data"),
       tags$hr(),
       checkboxGroupInput("usemodels", "Use:", choices = srm.models, selected = NULL),
       textInput("nphase", "Phase:"),
       checkboxInput("useeic", "Use EIC", value = FALSE),
       actionButton("submit", "Estimate"),
       tags$hr(),
       htmlOutput("mm")
     ),
     
      # Show a plot of the generated distribution
      mainPanel(
        tabsetPanel(type = "tabs", id = "mantabs",
                    tabPanel("Data", value = "tab1", dataTableOutput('table')),
                    tabPanel("Result", value = "tab2", plotOutput('mvf'), plotOutput('dmvf'), plotOutput('rate'), dataTableOutput('result')),
                    tabPanel("Evaluation", value = "tab3", dataTableOutput('eval'))
        )
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  data <- reactive({
    q <- input$query
    ddd <- get.opendate.jira(query=q)
    list(data=faultdata(time=ddd$time, fault=ddd$counts), table=data.frame(date=ddd$date, time=ddd$time, fault=ddd$counts))
  })

  estmodels <- reactive(input$usemodels)

  models <- reactive(input$models)
  
  phases <- reactive(eval(parse(text=paste("c(", input$nphase, ")"))))
  
  estimate <- reactive({
    result <- list()
    if (length(estmodels()) != 0) {
      result <- c(result, estimate.ordinary(data()$data, estmodels()))
    }
    if (!is.null(phases())) {
      result <- c(result, estimate.cph(data()$data, phases()))
    }
    result
  })

  checkeic <- reactive({
    input$useeic
  })
  
  observeEvent(input$getdata, {
    showModal(modalDialog("Getting bug data...", footer=NULL))
    output$table <- renderDataTable(data()$table, options = list(paging = FALSE, searching = FALSE))
    removeModal()
  })
  
  observeEvent(input$submit, {
    showModal(modalDialog("Estimating...", footer=NULL))
    result <- estimate()
    output$maxtime <- cat(sum(data()$data$time))
    mname <- lapply(result, function(m) m$srm$name)
    output$mm <- renderUI({
      checkboxGroupInput("models", "Models:", choices = mname, selected = mname)
    })
    vv <- checkeic()
    output$result <- renderDataTable(gof(result, eic = vv), options = list(paging = FALSE, searching = FALSE))
    output$eval <- renderDataTable(reliab(lapply(models(), function(m) result[[m]])), options = list(paging = FALSE, searching = FALSE))
    output$mvf <- renderPlot(mvfplot(data = data()$data, srms=lapply(models(), function(m) result[[m]])))
    output$dmvf <- renderPlot(dmvfplot(data = data()$data, srms=lapply(models(), function(m) result[[m]])))
    output$rate <- renderPlot(rateplot(data = data()$data, srms=lapply(models(), function(m) result[[m]])))
    updateTabsetPanel(session, "mantabs", selected = "tab2")
    removeModal()
  })
}

# Run the application 
shinyApp(options = list(host = "0.0.0.0", port = "3838"), ui = ui, server = server)

