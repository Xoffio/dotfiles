#!/usr/bin/env bash
mode="$1"

export EDITOR=nvim
export VISUAL=nvim

read -erp "branch: " branch
[ -z "$branch" ] && exit 0

case "$mode" in
plain)
	workmux add "$branch"
	;;
prompt)
	read -erp "prompt: " prompt
	[ -z "$prompt" ] && exit 0
	workmux add "$branch" --prompt "$prompt"
	;;
editor)
	workmux add "$branch" --prompt-editor
	;;
esac
