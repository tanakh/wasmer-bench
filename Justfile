export RUSTFLAGS := "-C opt-level=3 -C codegen-units=1"
export OMP_NUM_THREADS := "1"

WASI_DIR := "target/wasm32-wasi/release"

hf NAME +ARGS:
    hyperfine -w 3  \
        --export-json results/{{NAME}}.json \
        --export-markdown results/{{NAME}}.md \
        "{{ARGS}}"

make-input:
    cargo run --release --bin fasta 100000000 > input100000000.fasta
    cargo run --release --bin fasta 25000000  > input25000000.fasta
    cargo run --release --bin fasta 5000000   > input5000000.fasta

bench-rust-all:
    just bench-rust nbody 50000000
    just bench-rust fannkuchredux 12
    just bench-rust spectralnorm 5500
    just bench-rust mandelbrot 16000
    just bench-rust fasta 25000000
    just bench-rust revcomp 25000000 ../input100000000.fasta
    just bench-rust binarytrees 21
    just bench-rust knucleotide 0 ../input25000000.fasta

    # not working
    # just bench-rust pidigits 10000
    # just bench-rust regexredux 0 ../input5000000.fasta

build-wasi BIN:
    cd rust && cargo wasi build --release --bin {{BIN}}

bench-rust BIN ARG INPUT="/dev/null":
    just build-wasi {{BIN}}

    just hf {{BIN}}-native            cd rust "&&" cargo run --release --bin {{BIN}} {{ARG}} \< {{INPUT}} \> /dev/null
    just hf {{BIN}}-wasmer-llvm       cd rust "&&" wasmer --llvm {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null
    just hf {{BIN}}-wasmer-cranelift  cd rust "&&" wasmer --cranelift {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null
    just hf {{BIN}}-wasmer-singlepass cd rust "&&" wasmer --singlepass {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null
    just hf {{BIN}}-wasmtime          cd rust "&&" wasmtime run --enable-all {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null

    # same as cranelift?
    # just hf {{BIN}}-wasmer-default    cd rust "&&" wasmer {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null
    # just hf {{BIN}}-wasmer-jit        cd rust "&&" wasmer --jit {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null
    # just hf {{BIN}}-wasmer-native     cd rust "&&" wasmer --native {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null

bench-c-all:
    just bench-c nbody 50000000
    just bench-c fannkuchredux 12
    just bench-c spectralnorm 5500
    just bench-c mandelbrot 16000
    just bench-c fasta 25000000
    just bench-c revcomp 25000000 input100000000.fasta
    just bench-c binarytrees 21
    just bench-c knucleotide 0 input25000000.fasta

bench-c BIN ARG INPUT="/dev/null":
    gcc -Ic -O3 c/{{BIN}}.c -lm -o {{BIN}}.gcc_run $(apr-config --includes --link-ld --libs)
    just hf {{BIN}}-c ./{{BIN}}.gcc_run {{ARG}} \< {{INPUT}} \> /dev/null
    rm {{BIN}}.gcc_run

bench-java-all:
    just bench-java nbody 50000000
    just bench-java fannkuchredux 12
    just bench-java spectralnorm 5500
    just bench-java mandelbrot 16000
    just bench-java fasta 25000000
    just bench-java revcomp 25000000 input100000000.fasta
    just bench-java binarytrees 21
    just bench-java knucleotide 0 input25000000.fasta

bench-java BIN ARG INPUT="/dev/null":
    javac -cp java:/usr/share/java/fastutil.jar java/{{BIN}}.java
    just hf {{BIN}}-java java -cp java:/usr/share/java/fastutil.jar -XX:ActiveProcessorCount=1 {{BIN}} {{ARG}} \< {{INPUT}} \> /dev/null

make-graph:
    cargo run
    gnuplot plot.txt
    gnuplot plot-lim.txt
    gnuplot plot-gm.txt
