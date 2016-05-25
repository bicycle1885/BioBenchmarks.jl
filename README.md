# BioBenchmarks

Benchmark set of the Bio.jl package.

Script files in [/benchmarks] are benchmark scripts that will take about 1--60
seconds per run.

When you run a benchmark, copy [template.ipynb](/template.ipynb) in your
directory and start the Jupyter Notebook server:
```
$ cp template.ipynb super-performance-improvement.ipynb
$ jupyter notebook
```

Then replace `revA` and `revB` variables in the notebook with your
interested revision names to compare:
```
revA = "master"
revB = "super-performance-improvement"
```

Finally, click "Run All" in the "Cell" menu:
![Run All](/RunAll.png)


## Requirements not included in REQUIRE

* Jupyter Notebook (http://jupyter.org/)
* The R language (https://www.r-project.org/)
* ggplot2 (http://ggplot2.org/)
