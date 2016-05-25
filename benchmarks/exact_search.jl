using Bio.Seq
using BioBenchmarks

function searchall(seq, pat)
    query = ExactSearchQuery(pat)
    count = 0
    from = 0
    while (from = searchindex(seq, query, from + 1)) > 0
        count += 1
    end
    return count
end

chrom = first(open(datafile("chr1.fa"), FASTA)).seq
@benchmark searchall(chrom, dna"ATTACGTGACGT")
