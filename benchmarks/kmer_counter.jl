using Bio.Seq
using BioBenchmarks

chrom = first(open(datafile("chr1.fa"), FASTA)).seq
@benchmark DNAKmerCounts{3}(chrom)
