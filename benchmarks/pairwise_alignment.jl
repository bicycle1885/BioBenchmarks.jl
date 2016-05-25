using Bio.Seq
using Bio.Align
using BioBenchmarks

seq1 = first(open(datafile("Q8WZ42.fasta"), FASTA)).seq
seq2 = first(open(datafile("A2ASS6.fasta"), FASTA)).seq
affinegap = AffineGapScoreModel(BLOSUM62, -10, -1)
@benchmark pairalign(GlobalAlignment(), seq1, seq2, affinegap)
