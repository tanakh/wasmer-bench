export RUSTFLAGS := "-C opt-level=3 -C codegen-units=1"
export OMP_NUM_THREADS := "1"

WASI_DIR := "target/wasm32-wasi/release"

hf NAME +ARGS:
    hyperfine -w 3  \
        --export-json results/{{NAME}}.json \
        --export-markdown results/{{NAME}}.md \
        "{{ARGS}}"

build-wasi BIN:
    cargo wasi build --release --bin {{BIN}}

make-input:
    cargo run --release --bin fasta 100000000 > input100000000.fasta
    cargo run --release --bin fasta 25000000  > input25000000.fasta
    cargo run --release --bin fasta 5000000   > input5000000.fasta

bench-all-rust:
    just bench-revcomp
    just bench-binarytrees
    just bench-knucleotide
    just bench-mandelbrot
    just bench-nbody
    just bench-fannkuchredux
    just bench-spectralnorm
    just bench-fasta

    # not working
    # just bench-pidigits
    # just bench-regexredux

bench-nbody:
    just bench nbody 50000000

bench-fannkuchredux:
    just bench fannkuchredux 12

bench-spectralnorm:
    just bench spectralnorm 5500

bench-mandelbrot:
    just bench mandelbrot 16000

bench-fasta:
    just bench fasta 25000000

bench-revcomp:
    just bench revcomp 25000000 input100000000.fasta

bench-binarytrees:
    just bench binarytrees 21

bench-knucleotide:
    just bench knucleotide 0 input25000000.fasta

# bench-pidigits:
#     just bench pidigits 10000

# bench-regexredux:
#     just bench regexredux 0 input5000000.fasta

bench BIN ARG INPUT="/dev/null":
    just build-wasi {{BIN}}

    just hf {{BIN}}-native            cargo run --release --bin {{BIN}} {{ARG}} \< {{INPUT}} \> /dev/null
    just hf {{BIN}}-wasmer-llvm       wasmer --llvm {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null
    just hf {{BIN}}-wasmer-cranelift  wasmer --cranelift {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null
    just hf {{BIN}}-wasmer-singlepass wasmer --singlepass {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null
    just hf {{BIN}}-wasmtime          wasmtime run --enable-all {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null

    # just hf {{BIN}}-wasmer-default    wasmer {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null
    # just hf {{BIN}}-wasmer-jit        wasmer --jit {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null
    # just hf {{BIN}}-wasmer-native     wasmer --native {{WASI_DIR}}/{{BIN}}.wasm {{ARG}} \< {{INPUT}} \> /dev/null

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
