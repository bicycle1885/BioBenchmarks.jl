using Bio.Seq
using BioBenchmarks

function searchall(seq, pat, k)
    query = ApproximateSearchQuery(pat)
    count = 0
    from = 0
    while (from = approxsearchindex(seq, query, k, from + 1)) > 0
        count += 1
    end
    return count
end

chrom = first(open(datafile("chr1.fa"), FASTA)).seq
@benchmark searchall(chrom, dna"ATTACGTGACGT", 2)
