tags$html(
  tags$head(
    tags$title('About page')
  ),
  tags$body(
    tags$h2('About the Package'),
    tags$p('The AmerifluxR package provides functions to easily query Ameriflux data from the Ameriflux servers. Data will be downloaded if available (gap filled or raw). If no data is available, please contact the site PI if the site is listed. Presence in the table does not constitute available open access data.'),
    tags$h3('FAQ / remarks'),
    tags$ul(
      tags$li('Windows support does not exist - due to limited access to a development machine (I\'m looking for contributors to the project on Windows)'),
      tags$li('The sites can be constrained by clicking top left / bottom right on the map'),
      tags$li('The map might load slowly as it pulls in data from the Ameriflux server\'s javascript based site table (no API?)'),
      tags$li('Currently only the non gap filled data is shown (raw data)')
    )
    
    )
)
