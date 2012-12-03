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

# Updates the git status variables.
#
# It is executed on every directory change and so it controls
# $INSIDE_GIT_REPOSITORY.  Also as it updates the variables, it is
# responsible to unset GIT_STATUS
function git_prompt_update_vars() {
    unset INSIDE_GIT_REPOSITORY
    GIT_BRANCH=` git branch --no-color 2> /dev/null | \grep --color=never "^\* " | sed 's/^\* //' `
    #echo git-prompt-debug: $GIT_BRANCH 1>&2
    if [[ -z $GIT_BRANCH ]]; then
	# not in a git repo
        return
    fi
    if [[ $GIT_BRANCH == '(no branch)' ]]; then
        GIT_BRANCH=` git log --no-color -1 --oneline | cut -f 1 -d ' ' `
    fi
    INSIDE_GIT_REPOSITORY=1
    unset GIT_PROMPT_INFO
    # ACDMRTXB
    GIT_STAGED=`git diff --no-color --staged --name-status --diff-filter=ACDMRTXB 2> /dev/null | wc -l `
    GIT_CHANGED=`git diff --no-color --name-status --diff-filter=ACDMRTXB 2> /dev/null | wc -l `
    GIT_CONFLICTS=`git diff --no-color --name-status --diff-filter=U 2> /dev/null | wc -l `
    GIT_UNTRACKED=`git ls-files --others --exclude-standard 2> /dev/null | wc -l `
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
ZSH_GIT_PROMPT_THEME_CONFLICTS="x"
ZSH_GIT_PROMPT_THEME_CHANGED="+"
