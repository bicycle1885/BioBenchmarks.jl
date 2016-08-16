#!/usr/bin/env julia

using DocOpt
using DataFrames
using RCall
using Glob
import BioBenchmarks

args = docopt("Usage: runbenchmarks.jl <revision>...")
revisions = args["<revision>"]

results = DataFrame()
for revision in revisions
    filepath = BioBenchmarks.run(revision)
    r = readtable(filepath)
    r[:revision] = filepath[9:end-4]
    results = vcat(results, r)
end

# 64-bit integers may overflow in R
for f in [:elapsed, :gc_time, :allocated]
    results[f] = map(Float64, results[f])
end

serial = maximum(vcat(0, [parse(Int, splitext(fn)[1][12:end]) for fn in glob("benchmarks_*.png")]))
plotfile = string("benchmarks_", serial + 1, ".png")
@rput plotfile

R"""
library(ggplot2)

ggplot($(results), aes(x=revision, y=elapsed, color=revision)) +
  geom_boxplot() +
  geom_point(position=position_jitterdodge()) +
  facet_wrap(~name, scales="free") + 
  theme(axis.text.x=element_blank()) +
  expand_limits(y=0)

ggsave(plotfile)
"""
