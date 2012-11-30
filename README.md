Git prompt for zsh
==============================


A function to include git status information (current branch etc) in your zsh prompt.

Inspired by this [blog post], and by Olivier Verdier's
[zsh-git-prompt], from which I took the UTF character used for
untracked status.

Unlike https://github.com/olivierverdier/zsh-git-prompt this version **does not use Python**.

[blog post]: http://sebastiancelis.com/2009/nov/16/zsh-prompt-git-users/
[zsh-git-prompt]: https://github.com/olivierverdier/zsh-git-prompt/

Usage
-----

* Source `git-prompt.zsh` from your `~/.zshrc` config file,
* configure your prompt, say

```shell
source local/zfunc/path/git-prompt.zsh
# your own prompt definition
PROMPT='%B%m%~%b$(git_prompt_info) %# '
```
