# topdown

## workflow

```mermaid
graph TD
  subgraph Windows
    td(topdown) -- Create XML files for different fragmentation conditions --> exp[Run the MS2 Experiment]
    exp --> raw[Raw file]
    raw --> xcalibur(Xcalibur)
    raw --> sh(ScanHeadsman)
    sh --> txt["convoluted spectrum (.txt)"]
    xcalibur --> con["convoluted spectrum (.raw)"]
    con --> xtract(Xtract)
    xtract --> logfiles["log file(s)"]
    xtract -- Collect log files --> mono["monotopic spectrum"]
  end
    txt --> td2
    logfiles --> td2(topdown)
    td2 -- Link convoluted, deconvoluted and monoisotopic data<br/>using logfiles generated above --> fa[further analysis]

    classDef tdstyle fill:#00aa00,stroke:#00aa00
    classDef thermo fill:#f0f0f0,stroke:#aa0000
    classDef files fill:#ffffff,stroke:#000000
    classDef foreign fill:#f0f0f0,stroke:#0000aa
    class td,td2 tdstyle
    class xcalibur,xtract thermo
    class raw,txt,con,mono,logfiles files
    class sh foreign
```
