#' aggregate data.frame (combine numeric columns by fun, and take the
#' first row for non-numeric columns
#'
#' @param x `data.frame`
#' @param f `character`, grouping value
#' @param ignoreNumCols `character`, column names that won't be aggregated by
#' fun
#' @param fun `function`, aggregation function
#' @return `data.frame`
#' @noRd
.aggregateDataFrame <- function(x, f, ignoreNumCols=character(),
                                fun=mean, na.rm=TRUE) {
    fun <- match.fun(fun)

    cn <- colnames(x)

    isNumCol <- .isNumCol(x) & !cn %in% ignoreNumCols

    nonNum <- x[!duplicated(f), !isNumCol, drop=FALSE]
    rn <- rownames(nonNum)
    num <- aggregate(
        x[, isNumCol, drop=FALSE], by=list(f), FUN=fun, na.rm=na.rm, drop=FALSE
    )
    ## resort (aggregate turns "by" into a factor (locale depended sorting))
    num <- num[match(unique(f), num[["Group.1"]]),, drop=FALSE]
    x <- .colsToRle(cbind(nonNum, num)[, cn])
    rownames(x) <- rn
    x
}

#' Convert DataFrame columns to logical
#'
#' @param x `DataFrame`
#' @return `DataFrame`
#' @noRd
.colsToLogical <- function(x) {
    toConvert <- .isCharacterCol(x)
    x[toConvert] <- lapply(x[toConvert], .characterToLogical)
    x
}

#' Convert DataFrame columns to Rle
#'
#' @param x `DataFrame`
#' @return `DataFrame`
#' @noRd
.colsToRle <- function(x) {
    r <- lapply(x, Rle)
    toConvert <- .vapply1l(r, function(rr)length(rr) >= 2L * nrun(rr))
    x[toConvert] <- r[toConvert]
    x
}

#' droplevels for Rle/factor columns
#'
#' @param x `DataFrame`
#' @return `DataFrame`
#' @noRd
.droplevels <- function(x) {
    isFactorColumn <- .vapply1l(x, function(column) {
        is.factor(column) || (is(column, "Rle") && is.factor(runValue(column)))
    })
    x[isFactorColumn] <- droplevels(x[isFactorColumn])
    x
}

#' Drop NA only columns (all rows are NA)
#'
#' @param x `data.frame`/`DataFrame`
#' @return x, without columns that are NA
#' @noRd
.dropNaColumns <- function(x) {
    keep <- !.vapply1l(x, function(xx)all(is.na(xx)))
    x[, keep, drop=FALSE]
}

#' Drop non informative columns (all rows are identical)
#'
#' @param x `data.frame`/`DataFrame`
#' @param keep `character` column names that should never be dropped.
#' @return x, without columns that are identical
#' @noRd
.dropNonInformativeColumns <- function(x, keep="Mz") {
    keep <- !.vapply1l(x, .allIdentical) | colnames(x) %in% keep
    x[, keep, drop=FALSE]
}

#' Test for character columns
#'
#' @param x `data.frame`
#' @return `logical`
#' @noRd
.isCharacterCol <- function(x) {
    .vapply1l(x, function(column) {
        is.character(column) ||
            (is(column, "Rle") && is.character(runValue(column)))
    })
}

#' Test for numeric columns
#'
#' @param x `data.frame`
#' @return `logical`
#' @noRd
.isNumCol <- function(x) {
    .vapply1l(x, function(column) {
        is.numeric(column) ||
            (is(column, "Rle") && is.numeric(runValue(column)))
    })
}

#' Make row.names
#'
#' @param x `data.frame`
#' @return `character`
#' @noRd
.makeRowNames <- function(x, prefix="C") {
    if (!is.data.frame(x) && !inherits(x, "DataFrame"))
        stop("'x' has to be a 'data.frame' or 'DataFrame'")
    x <- .dropNonInformativeColumns(x, keep=character())

    if (ncol(x)) {
        isNumCol <- .isNumCol(x)
        x[isNumCol] <- lapply(x[isNumCol], .formatNumbers, na2zero=TRUE)
        .makeNames(.groupByLabels(x, sep="_"), prefix=prefix, sep="_")
    } else {
        paste0("C", .formatNumbers(seq_len(nrow(x))))
    }
}

#' Order data.frame by multiple columns given as character vector
#'
#' @param x `data.frame`
#' @param cols `character`, column names
#' @return `integer`
#' @noRd
.orderByColumns <- function(x, cols) {
    if (!is.data.frame(x) && !inherits(x, "DataFrame"))
        stop("'x' has to be a 'data.frame' or 'DataFrame'")
    if (!all(cols %in% colnames(x)))
        stop("Some 'cols' are not valid column names of 'x'")
    do.call(order, x[cols])
}

#' Combine data.frames rowwise, similar to base::rbind but creates missing
#' columns
#'
#' @param ... `data.frame`s
#' @noRd
.rbind <- function(...) {
    l <- list(...)

    if (length(l) == 1L) {
        l <- l[[1L]]
    }

    ## do nothing for a single data.frame
    if (is.data.frame(l) || inherits(l, "DFrame")) {
        return(l)
    }

    if (
        any(!.vapply1l(l, function(ll) {
            is.data.frame(ll) || inherits(ll, "DFrame")
        }))
    )
        stop("One or more elments of 'l' are not a 'data.frame' or 'DFrame'")

    ## If `l` contains `data.frame` and `DataFrame`, and the first is a
    ## `data.frame` the following error is thrown:
    ## Error in rep(xi, length.out = nvar) :
    ##  attempt to replicate an object of type 'S4'
    if (any(.vapply1l(l, inherits, "DFrame"))) {
        l <- lapply(l, as, "DataFrame")
    }

    nms <- lapply(l, names)
    allcn <- unique(unlist(nms))

    for (i in seq(along=l)) {
        diffcn <- setdiff(allcn, nms[[i]])
        if (length(diffcn)) {
            l[[i]][, diffcn] <- NA
        }
        ## rbind,DataFrame-method doesn't sort columns and will throw an error
        ## about non-matching names
        l[[i]] <- l[[i]][allcn]
    }
    do.call(rbind, l)
}
