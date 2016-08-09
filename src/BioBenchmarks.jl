module BioBenchmarks

export
    @benchmark,
    datafile


# Benchmark Runner
# ----------------

"""
    run(revision;
        force=false,
        stop_on_error=false,
        benchmark_directory=Pkg.dir("BioBenchmarks", "benchmarks"),
        benchmark_scripts=readdir(benchmark_directory))

Run benchmark scripts of `revision` and return the filepath of the results.

# Arguments
* `revision`: Git revision of Bio.jl (branch, tag, or hash).
* `force`: if `true`, run benchmarks even if the result file exists.
* `stop_one_error`: if `true`, immediately stop benchmarks when a script fails.
* `benchmark_directory`: directory of benchmark scripts.
* `benchmark_scripts`: benchmark script names in `benchmark_directory`.
"""
function run(revision;
             force=false,
             stop_on_error=false,
             benchmark_directory=Pkg.dir("BioBenchmarks", "benchmarks"),
             benchmark_scripts=readdir(benchmark_directory))
    suffix = cd(Pkg.dir("Bio")) do
        Base.run(`git checkout $revision`)
        gitrevision()
    end

    outputfile = "results_$(suffix).tsv"
    if isfile(outputfile) && !force
        info("use the existing benchmark results of $revision")
        return outputfile
    end

    out = open(outputfile, "w")
    print_header(out)
    flush(out)  # this seems to be necessary (but don't know why)
    for script in benchmark_scripts
        info("running $script")
        try
            Base.run(pipeline(
                `julia $(joinpath(benchmark_directory, script))`,
                out))
        catch ex
            if stop_on_error
                rethrow()
            else
                warn(ex)
            end
        end
    end
    close(out)

    return outputfile
end

function gitrevision()
    commit = chomp(readall(`git rev-parse HEAD`))
    branch = chomp(readall(`git rev-parse --abbrev-ref HEAD`))
    return string(branch, '_', commit[1:7])
end

macro benchmark(ex)
    quote
        results = ResultSet(splitext(basename(@__FILE__))[1])
        total_elapsedtime = UInt64(0)
        $(esc(ex))  # JIT compiling
        for _ in 1:5
            if total_elapsedtime > 60 * 10^9  # 60 sec
                break
            end
            gcstats = Base.gc_num()
            elapsedtime = Base.time_ns()
            $(esc(ex))
            elapsedtime = Base.time_ns() - elapsedtime
            total_elapsedtime += elapsedtime
            push!(results, Result(elapsedtime, Base.GC_Diff(Base.gc_num(), gcstats)))
        end
        BioBenchmarks.print_results(results)
    end
end


# Benchmark Result
# ----------------

immutable Result
    elapsed::UInt64
    diff::Base.GC_Diff

    Result(elapsed, diff) = new(elapsed, diff)
end

immutable ResultSet
    name::Symbol
    results::Vector{Result}

    ResultSet(name) = new(name, Result[])
end

function Base.push!(s::ResultSet, r::Result)
    push!(s.results, r)
    return s
end

function print_header(out)
    println(out, "name\ttrial\telapsed\tgc_time\tallocated")
end

function print_results(set::ResultSet)
    for (i, r) in enumerate(set.results)
        println(
            set.name,          '\t',
            i,                 '\t',
            r.elapsed,         '\t',
            r.diff.total_time, '\t',
            r.diff.allocd
        )
    end
end


# Utils for Data Files
# --------------------

function datafile(filename)
    datadir = Pkg.dir("BioBenchmarks", "data")
    if !isdir(datadir)
        mkdir(datadir)
    end

    filepath = joinpath(datadir, filename)
    if isfile(filepath)
        return filepath
    end

    if ismatch(r"^chr(\d{1,2}|[XYM])\.fa$", filename)
        # human chromosome
        recipe = pipeline(
            `curl http://hgdownload.cse.ucsc.edu/goldenPath/hg38/chromosomes/$filename.gz`,
            `gzip -cd`,
            filepath
        )
    elseif ismatch(r"^\w{6}\.fasta$", filename)
        # protein sequence of UniProt
        recipe = pipeline(
            `curl http://www.uniprot.org/uniprot/$filename`,
            filepath
        )
    else
        error("don't know how to get $filename")
    end

    Base.run(recipe)

    return filepath
end

end # module
