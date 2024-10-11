# vector-systemd-secrets - a vector secrets provider for systemd credentials

If you're running vector under systemd, you might need to make secrets
available to the vector, and unless you use aws-secrets-manager, you
have to write an exec provider. This tool serves as one such provider,
translating vector's `SECRET[systemd.some-name]` into the contents of
a systemd credential file named `some-name`.

## Installing

Two methods: Either use nix via the provided nix flake (which is what
I do), or `cargo build` the rust code here and install that into a
directory that vector can access.

## Configuring credentials in Vector's systemd unit

To make credentials available to the provider, you add them to vector's systemd service unit:

```ini
[Service]
...
LoadCredential=user:/run/agenix/log-collector-user
LoadCredential=password:/run/agenix/log-collector-password
```

The left part is the name that you're going to refer to the secret in
vector's config, the right part is the file whose contents will be
used in place of that secret.

See
[systemd.service#LoadCredential=](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#LoadCredential=ID:PATH)
for details.

## Configuring vector

Once you have the tool installed at a path, this is the configuration
snippet you need to add to your vector config:

```toml
[secret.systemd]
command = ["path/to/vector-systemd-secrets"]
type = "exec"
```

Then, refer to secrets in config like so:

```toml
[sinks.some-sink.auth]
strategy = "basic"
password = "SECRET[systemd.password]"
user = "SECRET[systemd.user]"
```

See [vector's global secret option](https://vector.dev/docs/reference/configuration/global-options/#secret.exec) for a reference.

## Limitations

Currently, this tool supports only secrets whose contents can be
represented as UTF-8. I'm not sure how vector wants binary secrets
represented, or if it even supports them. Please file a bug or
(preferably!) a pull request once you find out!
