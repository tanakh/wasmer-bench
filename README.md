# Benchmark programs for wasmer/wasmtime

# How to run

Run benchmark programs:

```sh
$ just make-input # make input files for some benchmarks
$ mkdir results
$ just bench-rust-all
$ just bench-c-all
$ just bench-java-all
```

Collect benchmark results and generate graphs:

```sh
$ just make-graph
```

Images are generated:

```sh
$ ls *.png
all.png gm.png lim.png
```

* `all.png` -- All results
* `lim.png` -- Results except slow implementations
* `gm.png` -- Geometric means
