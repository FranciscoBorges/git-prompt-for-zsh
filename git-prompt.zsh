#!/bin/zsh

# -----------------------------------------------------
# Script to add git status information to a ZSH prompt.
#
# INSTALLATION:
## # 1. Source the script:
##
## source local/zfunc/path/git-prompt.zsh
##
## # 2. Adapt your own prompt definition
##
## PROMPT='%~$(git_prompt_info) %# '
# -----------------------------------------------------

# Perform function/command substitutions in the prompt.
setopt PROMPT_SUBST
#setopt XTRACE

autoload -U add-zsh-hook

## Git status variables are updated due to:
# directory change
add-zsh-hook chpwd git_prompt_update_vars
# issuing a git command
add-zsh-hook preexec git_prompt_preexec_is_git_command
add-zsh-hook precmd git_prompt_precmd_update

#-------------------------------------------------------------------
# In case, you're wondering: isn't it better to have a hook inside
# git instead of these two `pre*` functions?
#
# Well, AFAIK git has /many/ hooks but not a simple 'repo modified
# hook'. Besides any hook usage that would turn this into a 3-step
# install (zsh source/set prompt/add git hooks) instead of just (zsh
# source/set prompt).
#-------------------------------------------------------------------
function git_prompt_preexec_is_git_command() {
    if [[ $2 =~ git* ]]; then
        RAN_GIT_COMMAND=1
    fi
}

function git_prompt_precmd_update() {
    if [ $RAN_GIT_COMMAND ]; then
        if [ $INSIDE_GIT_REPOSITORY ]; then
            # echo git-prompt-debug: ran inside 1>&2
            git_prompt_update_vars
        fi
        unset RAN_GIT_COMMAND
    fi
}
#-------------------------------------------------------------------

#-------------------------------------------------------------------
# Function taken from git-1.8.0/contrib/completion/git-prompt.sh
#-------------------------------------------------------------------
# __gitdir accepts 0 or 1 arguments (i.e., location)
# returns location of .git repo
__gitdir ()
{
        # Note: this function is duplicated in git-completion.bash
        # When updating it, make sure you update the other one to match.
        if [ -z "${1-}" ]; then
                if [ -n "${__git_dir-}" ]; then
                        echo "$__git_dir"
                elif [ -n "${GIT_DIR-}" ]; then
                        test -d "${GIT_DIR-}" || return 1
                        echo "$GIT_DIR"
                elif [ -d .git ]; then
                        echo .git
                else
                        git rev-parse --git-dir 2>/dev/null
                fi
        elif [ -d "$1/.git" ]; then
                echo "$1/.git"
        else
                echo "$1"
        fi
}
#-------------------------------------------------------------------

# Returns 0 if the specified string contains the specified substring,
# otherwise returns 1.
function contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}

# Updates the git status variables.
#
# It is executed on every directory change and so it controls
# $INSIDE_GIT_REPOSITORY.  Also as it updates the variables, it is
# responsible to unset GIT_STATUS
function git_prompt_update_vars() {
    unset INSIDE_GIT_REPOSITORY
    GIT_BRANCH=` git rev-parse --abbrev-ref=strict HEAD 2>/dev/null `
    # echo $pipestatus
    #echo git-prompt-debug: $GIT_BRANCH 1>&2
    if [[ -z $GIT_BRANCH ]]; then
	# not in a git repo
        return
    fi

    # Don't run if inside .git
    if contains $PWD .git; then return; fi

    if [[ $GIT_BRANCH == '(no branch)' ]]; then
        GIT_BRANCH=` git log --no-color -1 --oneline | cut -f 1 -d ' ' `
        local dir="$(__gitdir)"
        if [ -d "$dir"/rebase-apply ] || [ -d "$dir"/rebase-merge ]; then
            GIT_BRANCH=$GIT_BRANCH":REBASE"
        fi
    fi
    INSIDE_GIT_REPOSITORY=1
    unset GIT_PROMPT_INFO
    # ACDMRTXB
    GIT_STAGED=`git diff --no-color --staged --name-status --diff-filter=ACDMRTXB 2> /dev/null | wc -l `
    GIT_CHANGED=`git diff --no-color --name-status --diff-filter=ACDMRTXB 2> /dev/null | wc -l `
    GIT_CONFLICTS=`git diff --no-color --name-status --diff-filter=U 2> /dev/null | wc -l `
    GIT_UNTRACKED=`git ls-files --others --exclude-standard 2> /dev/null | wc -l `
    GIT_STASH=`git stash list | wc -l`
}

# Initialize colors.
autoload -U colors
colors

function git_prompt_update_status() {
    local reset
    reset="%{${reset_color}%}"

    BRANCH=$ZSH_GIT_PROMPT_THEME_BRANCH$GIT_BRANCH$reset
    if [ $GIT_STAGED -ne 0 ]; then
	DETAILS=$DETAILS$ZSH_GIT_PROMPT_THEME_STAGED$GIT_STAGED$reset
    fi
    if [ $GIT_CONFLICTS -ne 0 ]; then
	DETAILS=$DETAILS$ZSH_GIT_PROMPT_THEME_CONFLICTS$GIT_CONFLICTS$reset
    fi
    if [ $GIT_CHANGED -ne 0 ]; then
	DETAILS=$DETAILS$ZSH_GIT_PROMPT_THEME_CHANGED$GIT_CHANGED$reset
    fi
    if [ $GIT_STASH -ne 0 ]; then
        DETAILS=$DETAILS$ZSH_GIT_PROMPT_THEME_STASH$GIT_STASH$reset
    fi
    if [ $GIT_UNTRACKED -ne 0 ]; then
        DETAILS=$DETAILS$ZSH_GIT_PROMPT_THEME_UNTRACKED$reset
    fi
    if [[ ! ( -z $DETAILS ) ]]; then
        BRANCH=$BRANCH$ZSH_GIT_PROMPT_THEME_SEPARATOR$DETAILS$reset
    fi
    GIT_PROMPT_INFO=$ZSH_GIT_PROMPT_THEME_PREFIX$BRANCH$reset$ZSH_GIT_PROMPT_THEME_SUFFIX
}

git_prompt_info() {
    if [ $INSIDE_GIT_REPOSITORY ]; then
        if [[ -z $GIT_PROMPT_INFO ]]; then
            git_prompt_update_status
        fi
        echo $GIT_PROMPT_INFO
    fi
}

# Default values for the appearance of the prompt.
ZSH_GIT_PROMPT_THEME_PREFIX="("
ZSH_GIT_PROMPT_THEME_SUFFIX=")"
ZSH_GIT_PROMPT_THEME_SEPARATOR="|"
ZSH_GIT_PROMPT_THEME_UNTRACKED="…"

# add colors to these themes if you wish...
ZSH_GIT_PROMPT_THEME_BRANCH=""
ZSH_GIT_PROMPT_THEME_STAGED="."
ZSH_GIT_PROMPT_THEME_STASH="s"
ZSH_GIT_PROMPT_THEME_CONFLICTS="x"
ZSH_GIT_PROMPT_THEME_CHANGED="+"
