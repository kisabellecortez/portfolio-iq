CMD FROM rocker/shiny:latest

WORKDIR /srv/shiny-server/portfolioiq

RUN apt-get update && apt-get install -y \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c( \
    'shiny', \
    'bslib', \
    'plotly', \
    'dplyr', \
    'lubridate', \
    'DBI', \
    'RPostgres', \
    'scales' \
), repos='https://cloud.r-project.org')"

COPY . .

CMD ["sh", "-c", "R -e \"shiny::runApp(host='0.0.0.0', port=as.integer(Sys.getenv('PORT', '3838')))\""]