#!/usr/bin/env bash

eval "$(gnome-keyring-daemon --start --components=secrets,ssh,gpg)"
export SSH_AUTH_SOCK

dbus-update-activation-environment --all

exec i3
