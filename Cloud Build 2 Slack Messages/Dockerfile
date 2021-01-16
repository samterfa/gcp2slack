FROM rocker/tidyverse

RUN install2.r gargle
RUN installGithub.r rstudio/plumber

COPY [".", "./"]

ENTRYPOINT ["Rscript", "-e", "pr <- plumber::plumb(commandArgs()[9]); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')), swagger = F)"]

CMD ["Plumber.R"]