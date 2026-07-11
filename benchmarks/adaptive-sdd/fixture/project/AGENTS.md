# Fixture project instructions

- Keep the project compatible with Windows PowerShell 5.1.
- Use only built-in PowerShell and .NET APIs.
- Keep catalog results deterministic and ordered by `Id`.
- Tests are standalone scripts: they must throw on failure and print one `PASS:` line on success.
- Do not write runtime or test data into the source tree.
