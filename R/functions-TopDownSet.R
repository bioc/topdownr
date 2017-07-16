#' Read TopDown files.
#'
#' Read all TopDown files:
#'  - .fasta (peptide sequence)
#'  - .mzML (spectra)
#'  - .experiments.csv (fragmentation conditions)
#'  - .txt (header information)
#'
#' This is the regular \code{\linkS4class{TopDownSet}} constructor.
#'
#' @param path character, file path
#' @param pattern character, filename pattern
#' @param onDisk logical, return MSnExp or (if TRUE) OnDiskMSnExp
#' @param verbose logical, verbose output?
#' @return list (splitted by file extension) with file path
#' @noRd
readTopDownFiles <- function(path, pattern=".*",
                             type=c("a", "b", "c", "x", "y", "z"),
                             modifications=c(C=57.02146),
                             neutralLoss=defaultNeutralLoss(),
                             tolerance=10e-6,
                             verbose=interactive(), ...) {

  files <- .listTopDownFiles(path, pattern=pattern)

  if (any(lengths(files)) == 0L) {
    ext <- c("experiments.csv", "fasta", "mzML", "txt")
    stop("Could not found any ", paste0(ext[lengths(files) == 0L],
                                        collapse=" or "), " files!")
  }

  sequence <- .readFasta(files$fasta, verbose=verbose)

  fragmentViews <- .calculateFragments(sequence=sequence,
                                       type=type,
                                       modifications=modifications,
                                       neutralLoss=neutralLoss)

  scanConditions <- do.call(rbind, lapply(files$txt, .readScanHeadsTable,
                                          verbose=verbose))

  headerInformation <- do.call(rbind, lapply(files$csv, .readExperimentCsv,
                                             verbose=verbose))

  mzml <- mapply(.readMzMl,
                 file=files$mzML,
                 scans=split(scanConditions$Scan, scanConditions$File),
                 MoreArgs=list(fmass=elementMetadata(fragmentViews)$mass,
                               tolerance=tolerance),
                 SIMPLIFY=FALSE)

  assay <- do.call(cbind, lapply(mzml, "[[", "m"))

  mzmlHeader <- do.call(rbind, lapply(mzml, "[[", "hd"))

  scanHeadsman <- .mergeScanConditionAndHeaderInformation(scanConditions,
                                                          headerInformation)

  header <- .mergeSpectraAndHeaderInformation(mzmlHeader, scanHeadsman)

  new("TopDownSet",
      rowViews=fragmentViews,
      colData=.colsToRle(as(header, "DataFrame")),
      assays=assay,
      files=basename(unlist(unname(files))),
      processing=.logmsg("Data loaded."))
}

#' Test for TopDownSet class
#'
#' @param object object to test
#' @return TRUE if object is a TopDownSet otherwise fails with an error
#' @noRd
.isTopDownSet <- function(object) {
  if (!isTRUE(is(object, "TopDownSet"))) {
    stop("'object' has to be an 'TopDownSet' object.")
  }
  TRUE
}

#' @noRd
fragmentMass <- function(object) {
  .isTopDownSet(object)
  elementMetadata(object@rowViews)$mass
}

#' @noRd
fragmentType <- function(object) {
  .isTopDownSet(object)
  elementMetadata(object@rowViews)$type
}

#' Validate TopDownSet
#'
#' @param object TopDownSet
#' @return TRUE (if valid) else character with msg what was incorrect
#' @noRd
.validateTopDownSet <- function(object) {
  msg <- character()

  if (nrow(object@assays) != length(object@rowViews)) {
    msg <- c(msg, "Mismatch between fragment data in 'rowViews' and 'assays'.")
  }

  if (ncol(object@assays) != nrow(object@colData)) {
    msg <- c(msg, "Mismatch between condition data in 'colData' and 'assays'.")
  }

  if (length(msg)) {
    msg
  } else {
    TRUE
  }
}