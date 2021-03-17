# Contribution Guidelines

Please note that this project is released with a
[Contributor Code of Conduct](code-of-conduct.md). By participating in this
project you agree to abide by its terms.

---

### Add new item to the list

To add a new element, you must take into account to do it both in the [`readme.md`](https://github.com/PandaFoss/Awesome-Arch/blob/master/readme.md) file and in the respective file inside the [`src`](https://github.com/PandaFoss/Awesome-Arch/tree/master/src) directory. For example, if you want to add a new *pacman wrapper*, you should insert it in the `readme.md` mentioned above and in the file [`src/pacman-wrappers.md`](https://github.com/PandaFoss/Awesome-Arch/blob/master/src/pacman-wrappers.md), respecting the format of the rest of the file.
*Note: this task may be scripted in the future to avoid having to add the same line twice. But for the moment it must be done manually.*

### Testing

Since the list is getting bigger and bigger, I decided to add some scripts to the repository to make it easier to control it (inside the [`tests`](https://github.com/PandaFoss/Awesome-Arch/tree/master/tests) directory).
At the moment there is only a Perl script that checks one by one the links of the projects in the listing, making it much less tedious. Note that, when an error occurs, you must check the site manually to avoid false negatives.
We welcome all ideas and contributions in this regard.
