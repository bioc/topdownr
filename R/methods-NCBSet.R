#' @describeIn NCBSet Best combination of conditions.
#'
#' Finds the best combination of conditions for highest coverage of fragments or
#' bonds. If there are two (or more conditions) that would add the same number
#' of fragments/bonds the one with the highest assigned intensity is used. Use
#' `n` to limit the number of iterations and combinations that should be
#' returned.
#' If `minN` is set at least `minN` fragments have to be added to the
#' combinations. The function returns a 7-column matrix. The first column
#' contains the index (`Index`) of the condition (column number). The next
#' columns contain the newly added number of fragments or bonds
#' (`FragmentsAddedToCombination`, `BondsAddedToCombination`), the fragments
#' or bonds in the condition (`FragmentsInCondition`, `BondsInCondition`), and
#' the cumulative coverage fragments or bonds (`FragmentCoverage`,
#' `BondCoverage`).
#'
#' @param object `NCBSet`
#' @param n `integer`, max number of combinations/iterations.
#' @param minN `integer`,
#' stop if there are less than `minN` additional fragments
#' @param maximise `character`, optimisation targeting for the highest number of
#' `"fragments"` (default) or `"bonds"`.
#' @param \ldots arguments passed to internal/other methods.
#' added.
## @return `matrix`, first column: index of condition (`Index`), second column: number of
## newly added fragments third column: number of newly covered bonds, fourth and
## fifth column: fragments/bonds in the condition; sixth and seventh column:
## fragment/bond coverage
#' @aliases bestConditions bestConditions,NCBSet-method
#' @export
setMethod("bestConditions", "NCBSet",
          function(object, n=ncol(object), minN=0L,
                   maximise=c("fragments", "bonds"), ...) {
    m <- .bestNcbCoverageCombination(
        object@assay,
        intensity=object@colData$AssignedIntensity,
        n=n,
        minN=minN,
        maximise=maximise
    )
    m <- cbind(
        m,
        .countFragments(object@assay[, m[, "index"], drop=FALSE]),
        .colCounts(object@assay[, m[, "index"], drop=FALSE]),
        cumsum(m[, "fragments"])/(2L * nrow(object@assay)),
        cumsum(m[, "bonds"])/nrow(object@assay)
    )
    dimnames(m) <- list(
        colnames(object)[m[, "index"]],
        c(
            "Index",
            paste0(
                c("Fragments", "Bonds"),
                rep(c("AddedToCombination", "InCondition"), each=2L)
            ),
            paste0(c("Fragment", "Bond"), "Coverage")
        )
    )
    m
})

#' @describeIn NCBSet Plot fragmentation map.
#'
#' Plots a fragmentation map of the Protein.
#' Use `nCombinations` to add another
#' plot with `nCombinations` combined conditions.
#' If `cumCoverage` is `TRUE` (default)
#' these combinations increase the coverage cumulatively.
#'
## @param object `NCBSet`
#' @param nCombinations `integer`,
#' number of combinations to show (0 to avoid plotting them at all).
#' @param cumCoverage `logical`,
#' if `TRUE` (default) cumulative coverage of combinations is shown.
## @param maximise `character`, optimisation targeting for the highest number of
## `"fragments"` (default) or `"bonds"`.
#' @param labels `character`, overwrite x-axis labels.
#' @param alphaIntensity `logical`, if `TRUE` (default) the alpha level of the
#' color is used to show the `colData(object)$AssignedIntensity`. If `FALSE` the
#' alpha is set to `1`.
#' @aliases fragmentationMap fragmentationMap,NCBSet-method
#' @export
setMethod("fragmentationMap", "NCBSet",
          function(object, nCombinations=10, cumCoverage=TRUE,
                   maximise=c("fragments", "bonds"), labels=colnames(object),
                   alphaIntensity=TRUE, ...) {

    if (length(labels) != ncol(object)) {
        stop("The number of elements in 'labels' has to be the same as ",
            "the number of columns in 'object'.")
    }
    d <- .dgCMatrix2data.frame(object@assay)
    d$Activation <- as.character(object$Activation[d$col])
    d$AssignedIntensity <- object$AssignedIntensity[d$col]

    if (nCombinations) {
        i <- bestConditions(object, n=nCombinations,
                            maximise=maximise)[, "Index"]
        combinations <- object[, i]
        labels <- c(labels, labels[i])

        if (cumCoverage) {
            cmb <- .dgCMatrix2data.frame(.cumComb(combinations@assay))
        } else {
            cmb <- .dgCMatrix2data.frame(combinations@assay)
        }
        ## overwrite col (.dgCMatrix2data.frame creates 1:nCombinations)
        i <- i[cmb$col]
        cmb$AssignedIntensity <- object$AssignedIntensity[i]
        ## ggplot doesn't accept duplicated col for a facet
        cmb$col <- cmb$col + ncol(object)
        cmb$Activation <- "Cmb"
        d <- rbind(d, cmb)
    }

    ## tell ggplot that we have an already ordered factor
    d$col <- as.ordered(d$col)
    d$x <- as.factor(d$x)
    d$Activation <-
        factor(
            d$Activation,
            levels=c("CID", "HCD", "ETD", "ETcid", "EThcd", "UVPD", "Cmb"),
            ordered=TRUE
        )
    names(labels) <- seq_along(labels)

    gg <- ggplot(data=d)
        if (alphaIntensity) {
            gg <- gg +
                geom_raster(
                    aes_string(
                        x="col",
                        y="row",
                        fill="x",
                        alpha="AssignedIntensity"
                    )
                ) + scale_alpha(name="Assigned Intensity")
        } else {
           gg <- gg + geom_raster(aes_string(x="col", y="row", fill="x"))
        }
    gg  <- gg +
        facet_grid(. ~ Activation, scales="free_x", space="free_x") +
        scale_fill_manual(
            name="Observed Fragments",
            labels=c("N-terminal", "C-terminal", "Bidirectional"),
            values=c("#1b9e77", "#d95f02", "#7570b3")
        ) +
        scale_x_discrete(
            name="Condition", expand=c(0L, 0L), labels=labels
        ) +
        scale_y_continuous(
            name=expression(paste("Bonds (", N-terminal %->% C-termnial, ")")),
            breaks=seq_len(nrow(object)),
            expand=c(0L, 0L)
        ) +
        geom_vline(
            xintercept=c(0L, seq_len(ncol(object))) + 0.5,
            colour="#808080", size=0.1
        ) +
        geom_hline(
            yintercept=c(0L, seq_len(nrow(object))) + 0.5,
            colour="#808080", size=0.1
        ) +
        ggtitle("fragmentation map") +
        theme(
            axis.text.x=element_text(angle=90, hjust=1, vjust=0.4),
            plot.title=element_text(hjust=0.5, face="bold"),
            panel.grid.major=element_blank(),
            panel.border=element_blank(),
            panel.background=element_blank(),
            strip.background=element_rect(fill="#f0f0f0", colour="#ffffff")
        )
    gg
})

#' @rdname NCBSet-class
#' @aliases show,NCBSet-method
#' @export
setMethod("show", "NCBSet", function(object) {
    callNextMethod()

    if (length(object@rowViews)) {
        cat("- - - Fragment data - - -\n")
        cat0(
            paste0(
                "Number of ",
                c("N-terminal", "C-terminal", "N- and C-terminal"),
                " fragments: ", tabulate(object@assay@x, nbins=3L),
            "\n")
        )
    }

    if (nrow(object@colData)) {
        cat("- - - Condition data - - -\n")
        cat("Number of conditions:", length(unique(object$Sample)), "\n")
        cat("Number of scans:", nrow(object@colData), "\n")
        cat0("Condition variables (", ncol(object@colData), "): ",
            paste0(.hft(colnames(object@colData), n=2), collapse=", "), "\n")
    }

    if (all(dim(object))) {
        cat("- - - Assay data - - -\n")
        cat(sprintf(
                "Size of array: %dx%d (%.2f%% != 0)\n",
                nrow(object@assay), ncol(object@assay),
                nnzero(object@assay) / length(object@assay) * 100L
            )
        )
    }

    if (length(object@processing)) {
        cat("- - - Processing information - - -\n")
        cat(paste0(object@processing, collapse="\n"), "\n")
    }

    invisible(NULL)
})

#' @describeIn NCBSet Summary statistics.
#'
#' Returns a `matrix` with some statistics: number of fragments,
#' total/min/first quartile/median/mean/third quartile/maximum of intensity
#' values.
#'
## @param object `NCBSet`
#' @param what `character`,
#' specifies whether `"conditions"` (columns; default) or
#' `"bonds"` (rows) should be summarized.
#' @aliases summary,NCBSet-method
#' @export
setMethod("summary", "NCBSet",
          function(object, what=c("conditions", "bonds"), ...) {
    what <- if (match.arg(what) == "conditions") { "columns" } else { "rows" }
    callNextMethod(object=object, what=what)
})
