# BioBenchmarks

Benchmark set of the Bio.jl package.


## How to run benchmarks

First of all, make sure that requirements in [REQUIRE](/REQUIRE) and the
following external tools are installed:
* The R language (https://www.r-project.org/)
* ggplot2 (http://ggplot2.org/)

Then run the `bin/runbenchmarks.jl` script.

## How to add new benchmarks

Benchmark scripts should be placed in the [benchmarks/](/benchmarks) directory.
As an example, the [fasta_parser.jl](/benchmarks/fasta_parser.jl) file, which
measures the performance of parsing a FASTA file, is defined as follows:
```julia
using Bio.Seq
using BioBenchmarks

@benchmark collect(open(datafile("chr1.fa"), FASTA))
```

The `@benchmark` macro and the `datafile` function is defined in the
`BioBenchmarks` module. `@benchmark` evaluates the given expression several
times and measures some metrics such as elapsed time and memory allocation.
Each evaluation is supposed to take at least a few seconds. `datafile` returns a
file path that is placed in `data/`. If the require files don't exist, it should
be automatically downloaded and cached in `data/`.
