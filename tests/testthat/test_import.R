context("import")

test_that(".listTopDownFiles", {
    fns <- tempfile(pattern=c("fileA_", "fileB_"))
    fasta <- tempfile(pattern="fileA_", fileext=".fasta")
    fns <- paste(rep(fns, each=3), c("experiments.csv", "mzML", "txt"),
                 sep=".")
    file.create(c(fasta, fns))
    fns <- normalizePath(fns)
    fasta <- normalizePath(fasta)
    r <- split(fns, c("csv", "mzML", "txt"))
    r$fasta <- fasta
    r <- r[order(names(r))]
    expect_equal(.listTopDownFiles(tempdir()), r)
    expect_equal(.listTopDownFiles(tempdir(), pattern="^fileA_.*"),
                 lapply(r, "[", 1L))
    expect_error(.listTopDownFiles(tempdir(), pattern="^fileB_.*"),
                 "Could not find any fasta files")
    expect_error(.listTopDownFiles(tempdir(), pattern="^fileC_.*"),
                 "Could not find any csv, fasta, mzML, txt files")
    fasta2 <- tempfile(pattern="fileB_", fileext=".fasta")
    file.create(fasta2)
    expect_error(.listTopDownFiles(tempdir()),
                 "More than one fasta file")
    fns2 <- tempfile("fileA_")
    fns2 <- paste(fns2, c("mzML", "txt"), sep=".")
    file.create(fns2)
    expect_error(.listTopDownFiles(tempdir(), pattern="^fileA_.*"),
                 paste0("There have to be the same number .*",
                        "Found: csv=1, mzML=2, txt=2", collapse=""))
    unlink(c(fasta, fasta2, fns, fns2))
})

test_that(".readExperimentCsv", {
    fn <- paste0(tempfile(), ".experiments.csv")
    d <- data.frame(MSLevel=c(1, 2, 2),
                    NaColumn=c("", "N/A", "NA"),
                    TargetedMassList=paste0("(mz=933.100", 1:3, " z=2 name=)"),
                    stringsAsFactors=FALSE)
    write.csv(d, file=fn, row.names=FALSE)
    expect_message(e <- .readExperimentCsv(fn, verbose=TRUE),
                   "Reading 3 experiment conditions from file")
    expect_equal(colnames(e),
                 c("MsLevel", "NaColumn", "TargetedMassList", "Condition",
                   "Mz", "File"))
    expect_equal(e$MsLevel, rep(2, 2))
    expect_equal(e$NaColumn, rep(NA, 2))
    expect_equal(e$Condition, 1:2)
    expect_equal(e$Mz, rep(933.1, 2))
    expect_equal(e$File, rep(gsub("\\.experiments.csv", "", basename(fn)), 2))
    unlink(fn)
})

test_that(".readFasta", {
    fn <- paste0(tempfile(), ".fasta")
    writeLines(c("> FOOBAR", "Sequence"), fn)
    expect_message(s <- .readFasta(fn, verbose=TRUE),
                   "Reading sequence from fasta file")
    expect_equal(s, AAString("Sequence"))
    writeLines(c("> FOOBAR", "> Sequence"), fn)
    expect_error(.readFasta(fn), "No sequence found")
    unlink(fn)
})

test_that(".readScanHeadsTable", {
    fn <- paste0(tempfile(), ".txt")
    d <- data.frame(MSOrder=c(1, 2, 2, 2, 2),
                    FilterString=c("ms2 100.0001@etd", "ms2 100.0001@hcd",
                                   "ms2 100.0001@hcd", "ms2 100.0007@cid",
                                   "ms2 100.0009@hcd"),
                    Activation1=c("ETD", "ETD", "ETD", "HCD", "CID"),
                    Activation2=c(NA, "HCD", "HCD", "CID", "HCD"),
                    Energy1=c(10, 50, 50, NA, 20),
                    Energy2=c(NA, 30, 30, 20, 10),
                    stringsAsFactors=FALSE)
    write.csv(d, file=fn, row.names=FALSE)
    on.exit(unlink(fn))
    expect_message(h <- .readScanHeadsTable(fn, conditions="FilterString",
                                            verbose=TRUE),
                   "Reading 5 header information from file")
    expect_equal(colnames(h),
                 c("MsOrder", "FilterString", "Activation1", "Activation2",
                   "Energy1", "Energy2", "Condition",
                   "EtdActivation", "CidActivation", "HcdActivation",
                   "UvpdActivation", "Activation", "File"))
    expect_equal(h$MsOrder, rep(2, 4))
    expect_equal(h$EtdActivation, c(50, 50, NA, NA))
    expect_equal(h$CidActivation, c(NA, NA, 20, 20))
    expect_equal(h$HcdActivation, c(30, 30, NA, 10))
    expect_equal(h$Condition, c(1, 1, 7, 9))
    expect_equal(h$File, rep(gsub("\\.txt$", "", basename(fn)), 4))

    ## .fixFilterString needed
    d <- data.frame(MSOrder=c(1, 2, 2, 2, 2),
                    FilterString=c("ms2 100.0001@etd", "ms2 100.0001@hcd",
                                   "ms2 100.0001@hcd", "ms2 100.0001@cid",
                                   "ms2 100.0003@hcd"),
                    Activation1=c("ETD", "ETD", "ETD", "HCD", "CID"),
                    Activation2=c(NA, "HCD", "HCD", "CID", "HCD"),
                    Energy1=c(10, 50, 50, NA, 20),
                    Energy2=c(NA, 30, 30, 20, 10),
                    stringsAsFactors=FALSE)
    write.csv(d, file=fn, row.names=FALSE)
    expect_warning(h <- .readScanHeadsTable(fn, conditions="FilterString",
                                            verbose=TRUE),
                   "1 FilterString entries modified")
    expect_equal(h$Condition, c(1, 1:3))

    ## .fixFilterString needed;
    ## https://github.com/sgibb/topdownr/issues/25
    d <- data.frame(MSOrder=c(1, 2, 2, 2, 2),
                    FilterString=c("ms2 100.0001@etd", "ms2 100.0001@hcd",
                                   "ms2 100.0001@hcd", "ms2 100.0001@cid",
                                   "ms2 100.0003@hcd"),
                    Activation1=c("ETD", "ETD", "ETD", "HCD", "CID"),
                    Activation2=c(NA, "HCD", "HCD", "CID", "HCD"),
                    Energy1=c(10, 50, 50, NA, 20),
                    Energy2=c(NA, 30, 30, 20, 10),
                    stringsAsFactors=FALSE)
    write.csv(d, file=fn, row.names=FALSE)
    expect_warning(h <- .readScanHeadsTable(fn, conditions="FilterString",
                                            verbose=TRUE),
                   "1 FilterString entries modified")
    expect_equal(h$Condition, c(1, 1:3))

    ## duplicated IDs in different order (missing scans files)
    ## https://github.com/sgibb/topdownr/issues/14
    d <- data.frame(MSOrder=c(1, 2, 2, 2, 2),
                    FilterString=c("ms2 100.0001@etd", "ms2 100.0001@hcd",
                                   "ms2 100.0001@hcd", "ms2 100.0007@cid",
                                   "ms2 100.0001@hcd"),
                    Activation1=c("ETD", "ETD", "ETD", "HCD", "CID"),
                    Activation2=c(NA, "HCD", "HCD", "CID", "HCD"),
                    Energy1=c(10, 50, 50, NA, 20),
                    Energy2=c(NA, 30, 30, 20, 10),
                    ScanDescription=paste0("C0", c(1, 1:4)),
                    stringsAsFactors=FALSE)
    write.csv(d, file=fn, row.names=FALSE)
    expect_warning(h <- .readScanHeadsTable(fn, conditions="FilterString",
                                            verbose=FALSE),
                   "not sorted in ascending order")
    expect_equal(h$Condition, c(1, 1:3))

    ## test conditions argument
    expect_error(.readScanHeadsTable(
                    fn, conditions="FOO", verbose=FALSE),
                 "should be one of .*FilterString.*")
    expect_error(.readScanHeadsTable(
        fn, conditions=TRUE, verbose=FALSE),
                 "'conditions' has to be a 'character' or 'numeric'")
    expect_error(.readScanHeadsTable(
        fn, conditions=1:2, verbose=FALSE),
                 "'conditions' has to be a 'character' or 'numeric'")
    expect_warning(h <- .readScanHeadsTable(
                        fn, conditions="FilterString", verbose=FALSE),
                   "not sorted in ascending order")
    expect_equal(h$Condition, c(1, 1:3))
    expect_equal(.readScanHeadsTable(
        fn, conditions="ScanDescription", verbose=FALSE)$Condition, 1:4)
    expect_equal(.readScanHeadsTable(
        fn, conditions=4, verbose=FALSE)$Condition, 1:4)
    expect_equal(.readScanHeadsTable(
        fn, conditions=2, verbose=FALSE)$Condition, c(1:2, 1:2))
})

test_that(".readSpectrum", {
    expect_error(.readSpectrum(tempfile()), "File .* not found")

    skip_if_not_installed("topdownrdata", "0.2")
    f <- file.path(topdownrdata::topDownDataPath("myoglobin"),
                   "mzml", "myo_1211_ETDReagentTarget_1e6_1.mzML.gz")
    expect_error(.readSpectrum(f, 0L), "Invalid .* 1:351")
    expect_error(.readSpectrum(f, 1e3L), "Invalid .* 1:351")
    expect_equal(.readSpectrum(f, 1L),
                 matrix(
                    c(16941.06087, 18979506.00),
                    nrow=1, dimnames = list(c(), c("mz", "intensity"))
                 )
    )
})

test_that(".mergeScanConditionAndHeaderInformation", {
    sc <- data.frame(FOO=1:3, Condition=c(1:2, 1), Both=1,
                     File=c("foo", "foo", "bar"),
                     CidActivation=1:3,
                     HcdActivation=NA,
                     Energy2=1:3)
    hi <- data.frame(BAR=1:5, Condition=c(1, 1, 2, 2, 1), Both=2,
                     File=c("bar", "bar", "bar", "foo", "foo"),
                     SupplementalActivationCe=c(3, 3, 3, 2:1))
    r <- data.frame(File=rep(c("bar", "foo"), each=2),
                    Condition=c(1, 1, 1, 2), FOO=c(3, 3, 1, 2),
                    Both.ScanCondition=c(1, 1, 1, 1),
                    CidActivation=c(3, 3, 1:2),
                    HcdActivation=NA,
                    Energy2=c(3, 3, 1:2),
                    BAR=c(1:2, 5:4),
                    Both.HeaderInformation=2,
                    SupplementalActivationCe=c(3, 3, 1, 2))
    expect_equal(.mergeScanConditionAndHeaderInformation(sc, hi), r)
    sc$CidActivation <- 0
    sc$HcdActivation <- 11:13
    expect_error(.mergeScanConditionAndHeaderInformation(sc, hi),
                 "Merging of header and method information failed")
})

test_that(".mergeSpectraAndHeaderInformation", {
    fd <- data.frame(x=1:2, Scan=1:2, File="foo", spectrum=1:2, z=1:2,
                     RetentionTime=1:2)
    hi <- data.frame(File="foo", Scan=1:2, y=3:4, z=3:4, RtMin=1:2,
                     stringsAsFactors=FALSE)

    expect_error(.mergeSpectraAndHeaderInformation(fd, hi),
                 "The retention times .* differ.")
    fd$RetentionTime <- (1:2) * 60
    r <- fd
    r$Scan <- 1:2
    r$y <- 3:4
    r$z.SpectraInformation <- r$z
    r$z.HeaderInformation <- 3:4
    r$RtMin <- 1:2
    r <- r[, c("File", "Scan", "x", "spectrum",
               "z.SpectraInformation", "RetentionTime",
               "y", "z.HeaderInformation", "RtMin")]
    expect_equal(.mergeSpectraAndHeaderInformation(fd, hi), r)
})
