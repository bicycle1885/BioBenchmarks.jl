using Bio.Seq
using BioBenchmarks

@benchmark collect(open(datafile("chr1.fa"), FASTA))
