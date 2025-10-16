# topdownr

<!-- badges: start -->
[![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![license](https://img.shields.io/badge/license-GPL%20%28%3E=%203%29-brightgreen.svg?style=flat)](https://www.gnu.org/licenses/gpl-3.0.html)

[![years in bioc](https://bioconductor.org/shields/years-in-bioc/topdownr.svg)](https://bioconductor.org/packages/release/bioc/html/topdownr.html)
[![bioc downloads](https://bioconductor.org/shields/downloads/topdownr.svg)](https://bioconductor.org/packages/stats/bioc/topdownr/)
Release: [![build release](https://bioconductor.org/shields/build/release/bioc/topdownr.svg)](https://bioconductor.org/checkResults/release/bioc-LATEST/topdownr/)
Devel: [![build devel](https://bioconductor.org/shields/build/devel/bioc/topdownr.svg)](https://bioconductor.org/checkResults/devel/bioc-LATEST/topdownr/)
<!-- badges: end -->

## Installation

```r
if (!require("BiocManager"))
    install.packages("BiocManager")
BiocManager::install("topdownr")
```

If you want to install the development version from codeberg
(not recommended unless you know what you are doing):

```r
if (!require("BiocManager"))
    install.packages("BiocManager")
BiocManager::install("https://codeberg.org/sgibb/topdownr")
```

## Documentation

To get started:

```r
?"topdownr-package"
vignette("data-generation", package="topdownr")
vignette("analysis", package="topdownr")
```

## Questions

General questions should be asked on
the [Bioconductor support forum](https://support.bioconductor.org/),
using `topdownr` to tag the question. Feel also free to open a
codeberg [issue](https://codeberg.org/sgibb/topdownr/issues), in
particular for bug reports.

## Contribution

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Support

See [SUPPORT.md](SUPPORT.md).