## Signing the pipeline

If you change files in this directory, you will need to re-sign the pipeline.
For this, we are using [`cryptic-buildkite-plugin`](https://github.com/staticfloat/cryptic-buildkite-plugin).
Install it locally by cloning the repo outside of the Yggdrasil tree:

```sh
git clone https://github.com/staticfloat/cryptic-buildkite-plugin
```

Optionally, you can also add `/path/to/cryptic-buildkite-plugin/bin` to the PATH environment variable:

```sh
PATH="/path/to/cryptic-buildkite-plugin/bin:${PATH}"
```

where `/path/to/cryptic-buildkite-plugin` is the path where you cloned the repository.

To sign the keys, you will need the repo keys, stored in the [`cryptic_repo_keys`](./cryptic_repo_keys) subdirectory.
You will also need the script [`shyaml`](https://github.com/luodongseu/shyaml).
You can install it by cloning the upstream repo, or also with `pip`, which also pulls the needed dependencies:

```sh
python -m venv env      # Optional, to create a Python virtual environment
source env/bin/activate # Optional, to activate the environment just created
pip install shyaml
```

Once you are all set, you can sign the modified pipeline with the command

```sh
sign_treehashes
```

if you had added the dir to the PATH, otherwise with the explicit absolute path

```sh
/path/to/cryptic-buildkite-plugin/bin/sign_treehashes
```

Remember that you will always need to have the `shyaml` script in `PATH`, which happens automatically if you activate the Python virtual environment created above.
