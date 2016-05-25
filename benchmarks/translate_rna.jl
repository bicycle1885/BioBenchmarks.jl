using Bio.Seq
using BioBenchmarks

chrom = first(open(datafile("chr1.fa"), FASTA)).seq
@benchmark translate(RNASequence(chrom))
