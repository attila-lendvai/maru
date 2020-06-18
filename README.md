# Maru (stage 3 from Ian Piumarta's latest public version)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

This is the stripped down version of the *piumarta* branch to only contain the
stuff that is needed to successfully self-host, to bootstrap its version of
`eval.l`.

This stage is semantically equivalent with the head of the `maru.3` branch,
which has arrived to this point on a different path: by starting out first
from the minimal version of Maru, and then eventually getting the differences
between the minimal and the latest backported into it.

If this stage supported *modules* then it should be suitable to bootstrap
stage 4 in the `maru.4` branch.

## TODO

- Backport *modules* into this codebase and make it suitable to
bootstrap `maru.4`. It is not a huge task, but large enough for me to
rather work on more interesting stuff.
