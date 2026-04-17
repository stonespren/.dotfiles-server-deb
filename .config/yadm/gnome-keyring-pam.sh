#!/usr/bin/env bash
set -euo pipefail

PAM_FILE="/etc/pam.d/login"
BACKUP_FILE="/etc/pam.d/login.bak.$(date +%Y%m%d%H%M%S)"

if [[ $EUID -ne 0 ]]; then
    echo "Run as root."
    exit 1
fi

if [[ ! -f "$PAM_FILE" ]]; then
    echo "Missing $PAM_FILE"
    exit 1
fi

cp "$PAM_FILE" "$BACKUP_FILE"
echo "Backup created at $BACKUP_FILE"

if ! grep -Eq '^[[:space:]]*auth[[:space:]]+optional[[:space:]]+pam_gnome_keyring\.so([[:space:]]|$)' "$PAM_FILE"; then
    awk '
        BEGIN { added = 0 }
        {
            print
            if (!added && $1 == "auth" && $2 == "include") {
                print "auth       optional     pam_gnome_keyring.so"
                added = 1
            }
        }
        END {
            if (!added) {
                print "auth       optional     pam_gnome_keyring.so"
            }
        }
    ' "$PAM_FILE" >"$PAM_FILE.tmp"
    mv "$PAM_FILE.tmp" "$PAM_FILE"
    echo "Added auth hook."
else
    echo "Auth hook already present."
fi

if ! grep -Eq '^[[:space:]]*session[[:space:]]+optional[[:space:]]+pam_gnome_keyring\.so[[:space:]]+auto_start([[:space:]]|$)' "$PAM_FILE"; then
    awk '
        BEGIN { added = 0 }
        {
            print
            if (!added && $1 == "session" && $2 == "include") {
                print "session    optional     pam_gnome_keyring.so auto_start"
                added = 1
            }
        }
        END {
            if (!added) {
                print "session    optional     pam_gnome_keyring.so auto_start"
            }
        }
    ' "$PAM_FILE" >"$PAM_FILE.tmp"
    mv "$PAM_FILE.tmp" "$PAM_FILE"
    echo "Added session hook."
else
    echo "Session hook already present."
fi

echo
echo "Done."
echo
echo "Your keyring password must match your login password for auto-unlock to work."
echo "Log out fully and log back in to test."
