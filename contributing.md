# Contribution Guidelines

Please note that this project is released with a
[Contributor Code of Conduct](code-of-conduct.md). By participating in this
project you agree to abide by its terms.

---

### Add new item to the list

To add a new element, just edit the corresponding file inside the
[`src`](https://github.com/PandaFoss/Awesome-Arch/tree/master/src) directory,
respecting the format of the rest of the file. For example, if you want to
add a new *pacman wrapper*, insert it in
[`src/pacman-wrappers.md`](https://github.com/PandaFoss/Awesome-Arch/blob/master/src/pacman-wrappers.md).

You **don't** need to touch `readme.md` yourself: a GitHub Action
regenerates it automatically from the contents of `src/` once your change is
merged into `master`.

### Testing

Since the list is getting bigger and bigger, some scripts have been added to
the repository to make it easier to control it (inside the
[`tests`](https://github.com/PandaFoss/Awesome-Arch/tree/master/tests)
directory).

At the moment there is a Perl script that checks the links of the projects in
the listing in parallel, making it much less tedious. Note that, when an
error occurs, you must check the site manually to avoid false negatives (some
sites block automated clients).

We welcome all ideas and contributions in this regard.
