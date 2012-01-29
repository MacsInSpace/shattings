#!/bin/bash
#
# IMPORTANT
# =========
#
# The author of the original version of this file is currently unknown.
# As such, the license terms for using this file are unclear.
#
# This file has been heavily modified by Robert Quattlebaum <darco@deepdarc.com>.
#
# The original version of this file can be found here:
#
#  * <https://github.com/nesono/nesono-bin/blob/master/bashtils/ps1status>
#

# Prompt setup, with SCM status
function parse_git_branch() {
	local DIRTY STATUS BRANCH MODE TOPLEVEL

	# If this environment variable is set, we skip this part.
	[ "${DISABLE_GIT_PROMPT}" = "" ] || return

	PROMPT_TYPE=$(git config gitprompt.type)
	[ "$PROMPT_TYPE" = "0" ] && return
	[ "$PROMPT_TYPE" = "disabled" ] && return
	[ "${PROMPT_TYPE:0:1}" = "f" ] && return
	[ "${PROMPT_TYPE:0:1}" = "F" ] && return

	TOPLEVEL="$(git rev-parse --show-toplevel 2>/dev/null)"
	[ "$TOPLEVEL" = "" ] && return
	[ "$TOPLEVEL" = "/.git" ] && return
	[ "$TOPLEVEL" = "/" ] && return
	[ "$TOPLEVEL" = "--show-toplevel" ] && {
		# Older versions of GIT.
		TOPLEVEL="$(git rev-parse --show-cdup 2>/dev/null)./"
	}

	BRANCH="$(sed -n '/ref: /!{a\
<detached>
};/ref: /{s/ref: //;s:^refs/heads/::;p;};' "$TOPLEVEL"/.git/HEAD)"

	#Too slow!
	#BRANCH="$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* //')"

	[ "${PROMPT_TYPE}" != "simple" ] && {
		STATUS=$(git status --porcelain 2>/dev/null)
		[ $? -eq 128 ] && return
		[ -z "$(echo "$STATUS" | grep -e '^ [RDMA]')"    ] || DIRTY="*"
		[ -z "$(echo "$STATUS" | grep -e '^?? ')"    ] || DIRTY="${DIRTY}?"
		[ -z "$(echo "$STATUS" | grep -e '^[RMDA]')" ] || DIRTY="${DIRTY}+"
		[ -z "$(git stash list)" ]                    || DIRTY="${DIRTY}^"
		if [ -f "${TOPLEVEL}/.git/rebase-merge/interactive" ]
		then
			BRANCH='['$(basename `cat "${TOPLEVEL}/.git/rebase-merge/head-name"`)']'
			MODE="<rebase-i>"
		elif [ -f "${TOPLEVEL}/.git/rebase-apply/rebasing" ]
		then MODE="<rebase>"
		elif [ -f "${TOPLEVEL}/.git/rebase-apply/applying" ]
		then MODE="<am>"
		elif [ -d "${TOPLEVEL}/.git/rebase-apply" ]
		then MODE="<rebase?>"
		elif [ -f "${TOPLEVEL}/.git/MERGE_HEAD" ]
		then MODE="<merge>"
		elif [ -f "${TOPLEVEL}/.git/CHERRY_PICK_HEAD" ]
		then MODE="<cherry-pick>"
		elif [ -f "${TOPLEVEL}/.git/BISECT_LOG" ]
		then MODE="<bisect>"
		fi
	}

	echo -n '('${MODE}${BRANCH}${DIRTY}')'
}

function parse_svn_revision() {
	# If this environment variable is set, we skip this part.
	[ "${DISABLE_SVN_PROMPT}" = "" ] || return
	[ -d .svn ] || return
	local DIRTY REV=$(svn info 2>/dev/null | grep Revision | sed -e 's/Revision: //')
	[ "$REV" ] || return
	[ "$(svn st | grep -e '^ \?[M?] ')" ] && DIRTY='*'
	echo "(r$REV$DIRTY)"
}

if [ `whoami` = root ]
then
	PS1_PREFIX='\[\033[1;31m\]\h:\[\033[1;34m\]\W \[\033[33m\]'
	PS1_SUFFIX='\[\033[0m\]\$ '
else
	PS1_PREFIX='\[\033[1;32m\]\h:\[\033[1;34m\]\W \[\033[33m\]'
	PS1_SUFFIX='\[\033[0m\]\$ '
fi

PS1="$PS1_PREFIX"
( which git 2> /dev/null > /dev/null ) && PS1="$PS1"'$(parse_git_branch)'
( which svn 2> /dev/null > /dev/null ) && PS1="$PS1"'$(parse_svn_revision)'
PS1="$PS1$PS1_SUFFIX"


