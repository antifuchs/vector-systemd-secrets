use std::collections::HashMap;
use std::path::PathBuf;
use std::{env, fs, io};

use anyhow::Context as _;
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
struct Input {
    version: String,
    secrets: Vec<String>,
}

#[derive(Debug, Default, Serialize)]
struct SecretValue {
    value: String,
    error: Option<String>,
}

type Output = HashMap<String, SecretValue>;

fn read_secret(secret: PathBuf) -> SecretValue {
    match fs::read_to_string(&secret) {
        Ok(value) => SecretValue {
            value,
            ..Default::default()
        },
        Err(e) => SecretValue {
            error: Some(format!("Could not read {:?}: {}", secret, e)),
            ..Default::default()
        },
    }
}

fn main() -> anyhow::Result<()> {
    let creds_base = PathBuf::from(
        env::var_os("CREDENTIALS_DIRECTORY").context("CREDENTIALS_DIRECTORY needs to be set")?,
    );
    let input: Input =
        serde_json::from_reader(io::stdin()).context("reading secrets from stdin")?;
    if input.version != "1.0" {
        anyhow::bail!("Expected input version 1.0, got {:?}", input.version);
    }

    let output: Output = input
        .secrets
        .iter()
        .map(|name| (name.to_string(), read_secret(creds_base.join(name))))
        .collect();
    serde_json::to_writer_pretty(io::stdout(), &output)
        .with_context(|| format!("writing secrets {:?}", input.secrets))?;
    Ok(())
}
