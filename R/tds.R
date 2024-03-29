#' TopDownSet Example Data
#'
#' An example data set for `topdownr`. It is just a subset of the myoglobin
#' dataset available in
#' [topdownrdata::topdownrdata-package].
#'
#' It was created as
#' follows:
#'
#' ```
#' tds <- readTopDownFiles(
#'    topdownrdata::topDownDataPath("myoglobin"),
#'    ## Use an artifical pattern to load just the fasta
#'    ## file and files from m/z == 1211, ETD reagent
#'    ## target 1e6 and first replicate to keep runtime
#'    ## of the example short
#'    pattern=".*fasta.gz$|1211_.*1e6_1",
#'    adducts=data.frame(mass=1.008, name="zpH", to="z"),
#'    neutralLoss=PSMatch::defaultNeutralLoss(
#'        disableWaterLoss=c("Cterm", "D", "E", "S", "T")),
#'    tolerance=25e-6)
#' ```
#'
#' @format A [TopDownSet-class]
#' with 14901 fragments (1949 rows, 351 columns).
#' @source Subset taken from the
#' [topdownrdata::topdownrdata-package]
#' package.
"tds"
