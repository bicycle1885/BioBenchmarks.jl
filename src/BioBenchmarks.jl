module BioBenchmarks

export
    @benchmark,
    datafile


# Benchmark Runner
# ----------------

const benchmarkdir = Pkg.dir("BioBenchmarks", "benchmarks")

function run(commit; force=false, benchmark_scripts=readdir(benchmarkdir))
    revision = cd(Pkg.dir("Bio")) do
        Base.run(`git checkout $commit`)
        gitrevision()
    end

    outputfile = "result-$(revision).tsv"
    if isfile(outputfile) && !force
        info("use the existing benchmark results of $commit")
        return outputfile
    end

    out = open(outputfile, "w")
    print_header(out)
    flush(out)  # this seems to be necessary (but don't know why)
    for script in benchmark_scripts
        info("running $script")
        Base.run(pipeline(
            `julia $(joinpath(benchmarkdir, script))`,
            out))
    end
    close(out)
    return outputfile
end

function gitrevision()
    commit = chomp(readall(`git rev-parse HEAD`))
    branch = chomp(readall(`git rev-parse --abbrev-ref HEAD`))
    return string(branch, '(', commit[1:7], ')')
end

macro benchmark(ex)
    quote
        results = ResultSet(splitext(basename(@__FILE__))[1])
        $(esc(ex))  # JIT compiling
        for _ in 1:5
            gcstats = Base.gc_num()
            elapsedtime = Base.time_ns()
            $(esc(ex))
            elapsedtime = Base.time_ns() - elapsedtime
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
