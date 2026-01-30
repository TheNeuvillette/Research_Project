# Function running the R shiny app:
runFstShiny <- function(fst_file) {
  # ----------------------------------------------------
  # 1. Load the required libraries:
  # ----------------------------------------------------
  library(shiny)        # R shiny library, for the interactive web app
  library(data.table)   # Fast file loading and data manipulation
  library(ggplot2)      # Plotting using ggplot
  
  # ----------------------------------------------------
  # 2. Load and clean data:
  # ----------------------------------------------------
  # Load per-site Fst file:
  fst_data <- fread(fst_file)
  # Data cleaning: Removes NaN values only, while keeping negative numbers.
  fst_data <- fst_data[!is.nan(WEIR_AND_COCKERHAM_FST)]

  # ----------------------------------------------------
  # 3. Function computing the sliding-window Fst using
  #    the arithmetic mean of the per-site Fst:
  # ----------------------------------------------------
  window_fst <- function(fst_data, window_size, step_size) {
    # Find the maximum genomic position:
    max_pos <- max(fst_data$POS)
    # Create window start positions spaced by step-size:
    bins <- seq(1, max_pos, by = step_size)

    # Create a table of window boundaries:
    result <- data.table(
      BIN_START = bins,
      BIN_END = pmin(bins + window_size - 1, max_pos) # Ensures the last window does not exceed max_pos
    )
    
    # Compute the arithmetic mean of the per-site Fst per window:
    result[, MEAN_FST := sapply(1:nrow(result), function(i) {     # Adds a new column WEIGHTED_FST, iterates over all windows and computes the mean Fst using sapply
      subset <- fst_data[POS >= result$BIN_START[i] & POS <= result$BIN_END[i]]        # For each window, extracts all SNPs that fall inside the window.
      if (nrow(subset) == 0) return(NA_real_)                                          # Handles empty windows.
      mean(subset$WEIR_AND_COCKERHAM_FST, na.rm = TRUE)           # Computes the mean per-site Fst of the window:
    })]
    
    return(result)
  }
  # ----------------------------------------------------
  # 4. Shiny UI definition:
  # ----------------------------------------------------
  # Creates a fluid page layout, thus automatically adjusting the UI size to the browser window size.
  ui <- fluidPage(
    titlePanel("Interactive Fst Viewer"),                                                               # Title
    # Split the page two sections, with a main panel (outputs) and a sidebar (controls)
    sidebarLayout(
      # Sidebar:
      sidebarPanel(
        sliderInput("window", "Window size (bp):", min = 100, max = 5000, value = 200, step = 100),       # Sliders controlling window size
        sliderInput("step", "Step size (bp):", min = 50, max = 2500, value = 100, step = 50),           # Sliders controlling window step
        checkboxInput("lockRatio", "Lock window/step ratio", value = TRUE)                              # Lock ratio checkbox
      ),
      # Main panel:
      mainPanel(plotOutput("fstPlot"),    # Interactive plot of windowed Fst
      hr(),                               # Horizontal line
      h4("Summary"),                      # Summary header
      verbatimTextOutput("summaryText"))  # Summary statistics below the plot
    )
  )
  
  # ----------------------------------------------------
  # 5. Shiny server logic:
  #    This part handles the interactivity of the app,
  #    including updating ratio, plotting and summaries:
  # ----------------------------------------------------
  # Define the Shiny server:
  server <- function(input, output, session) {

    # ----------------------------------------------------
    # 5.1. Update window size & step when ratio is locked:
    # ----------------------------------------------------
    # Create a reactable window size/step ratio storage and initialize it to NULL (no ratio stored yet):
    ratio_val <- reactiveVal(NULL)

    # Store current ratio if ratio toggle is turned on:
    observeEvent(input$lockRatio, {                       # ObserveEvent creates an observer that runs every time lockRatio is toggled on or off.
      if (input$lockRatio) {                              # Checks whether the lock is turned on.
        ratio_val(isolate(input$window / input$step))     # Updates the ratio with current window size/step.
      }                                                   # Isolate prevents this observer from reacting to future changes in window or step, remembering the current window size/step ratio.
    })

    # Update window step when window size changes while locked
    observeEvent(input$window, {                                    # Observer on window size, runs every time window size changes.
      if (isTRUE(input$lockRatio) && !is.null(ratio_val())) {       # Checks if lock is turned on (and has a ratio stored).
        new_step <- round(isolate(input$window / ratio_val()))      # Calculates the new window step based on window size and stored ratio.
        session$sendInputMessage("step", list(value = new_step))    # Tells the Shiny to update the value of step with new_step (but doesn't recompute the sliding-window Fst).
      }
    }, priority = 100)  # Higher priority for faster execution
    
    
    # Update window size when window step changes while locked (reverse logic from previously)
    observeEvent(input$step, {
      if (isTRUE(input$lockRatio) && !is.null(ratio_val())) {
        new_window <- round(isolate(input$step * ratio_val()))
        session$sendInputMessage("window", list(value = new_window))
      }
    }, priority = 100)  # Higher priority for faster execution

    # Reactive sliding-window Fst recalculation when window size or step are changed:
    windowed_data <- reactive({
      window_fst(fst_data, input$window, input$step)
    })

    # ----------------------------------------------------
    # 5.2. Plotting sliding-window Fst using ggplot2:
    # ----------------------------------------------------
    # Generates the Fst plot on the server that should be re-rendered automatically whenever window size or step are changed:
    output$fstPlot <- renderPlot({
      plot_data <- windowed_data()

      # Using ggplot, plots the Fst as a function of the position along the chromosome:
      ggplot(plot_data, aes(BIN_START, MEAN_FST)) +
        geom_line(color = "#0072B2") +
        # Plot axes, theme, color, style, etc.:
        labs(
          x = "Position (bp)",
          y = "Windowed Fst",
          title = paste0("Windowed Fst — Window = ", input$window,
                         " bp, Step = ", input$step, " bp")
        ) +
        theme_minimal(base_size = 14) +
        theme(
          panel.grid.minor = element_blank(),
          panel.border = element_rect(color = "black", fill = NA)
        )
    })

    # ----------------------------------------------------
    # 5.3. Display numeric summary:
    # ----------------------------------------------------
    # Generates the numeric summary as a text that should be re-rendered automatically whenever window size or step are changed:
    output$summaryText <- renderText({
      d <- windowed_data()
      # Create a formatted string using sprintf() containing the number of windows, mean and max Fst values
      sprintf("Number of windows: %d | Mean Fst: %.4f | Max Fst: %.4f",
              sum(!is.na(d$MEAN_FST)),
              mean(d$MEAN_FST, na.rm = TRUE),
              max(d$MEAN_FST, na.rm = TRUE))
    })
  }
  # ----------------------------------------------------
  # 6. Launch Shiny app:
  # ----------------------------------------------------
  shinyApp(ui, server)
}

# ----------------------------------------------------
# Command-line / Snakmake entry point:
# ----------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
runFstShiny(args[1])
