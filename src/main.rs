use std::io::Write;
use std::{collections::BTreeMap, fs::File};

static PROGRAMS: &[&str] = &[
    "nbody",
    "fannkuchredux",
    "spectralnorm",
    "mandelbrot",
    "fasta",
    "revcomp",
    "binarytrees",
    "knucleotide",
];

static IMPLS: &[&str] = &[
    "native",
    "wasmer-llvm",
    "wasmer-cranelift",
    // "wasmer-singlepass",
    "wasmtime",
    "c",
    "java",
];

#[derive(Clone, Debug, serde::Deserialize)]
struct Result {
    command: String,
    mean: f64,
    stddev: f64,
    median: f64,
    user: f64,
    system: f64,
    min: f64,
    max: f64,
    times: Vec<f64>,
}
#[derive(Debug, serde::Deserialize)]
struct Results {
    results: Vec<Result>,
}

fn main() -> anyhow::Result<()> {
    let rename = vec![("native", "rust-native")]
        .into_iter()
        .collect::<BTreeMap<&str, &str>>();
    let mut mm = BTreeMap::<String, Vec<f64>>::new();

    {
        let mut f = File::create("info.dat")?;

        writeln!(
            &mut f,
            "Program {}",
            IMPLS
                .iter()
                .map(|imp| rename.get(imp).map(|r| *r).unwrap_or(imp).to_string())
                .collect::<Vec<_>>()
                .join(" ")
        )?;

        for &progn in PROGRAMS.iter() {
            write!(&mut f, "{}", progn)?;

            let mut native_time = 0.0;

            for &imp in IMPLS.iter() {
                let path = format!("results/{}-{}.json", progn, imp);
                let res: Results = serde_json::from_reader(File::open(path)?)?;
                let res = res.results[0].clone();

                if imp == "native" {
                    native_time = res.mean;
                }

                write!(&mut f, " {}", res.mean / native_time)?;
                mm.entry(imp.to_string()).or_default().push(res.mean);
            }

            writeln!(&mut f)?;
        }
    }

    {
        let mut f = File::create("geomean.dat")?;
        writeln!(&mut f, "Language Geometric-mean")?;

        for &imp in IMPLS.iter() {
            let r = &mm[imp];
            let gm = r.iter().product::<f64>().powf(1.0 / r.len() as f64);
            let imp = rename.get(imp).map(|r| *r).unwrap_or(imp).to_string();
            writeln!(&mut f, "{} {}", imp, gm)?;
        }
    }

    Ok(())
}
