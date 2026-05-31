#!/usr/bin/env bash
#
# gpg-git-configurator.sh
# Interactively select a GPG key and configure Git with color-coded output

set -euo pipefail
IFS=$'\n\t'

#–– ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

#–– Dependencies check
if ! command -v gpg &>/dev/null; then
  echo -e "${RED}❌ Error:${RESET} gpg not found. Please install GPG."
  exit 1
fi

if ! command -v git &>/dev/null; then
  echo -e "${RED}❌ Error:${RESET} git not found. Please install Git."
  exit 1
fi

#–– Get secret keys (no trust filter to avoid false negatives)
mapfile -t keys < <(
  gpg --list-secret-keys --with-colons \
    | awk -F: '$1=="sec" { print $5 }'
)

if [ ${#keys[@]} -eq 0 ]; then
  echo -e "${RED}No secret GPG keys found.${RESET}"
  exit 1
fi

#–– Show selection menu
echo -e "${BOLD}${CYAN}Select a GPG key to configure Git:${RESET}"
for i in "${!keys[@]}"; do
  key="${keys[i]}"
  uid=$(gpg --list-secret-keys --keyid-format=long "$key" \
        | awk '/^uid/ { sub(/.*] /, ""); print; exit }')
  printf "${YELLOW}%2d)${RESET} %s ${GREEN}[%s]${RESET}\n" $((i+1)) "$uid" "$key"
done

read -rp "$(echo -e "${CYAN}👉 Enter choice [1-${#keys[@]}]: ${RESET}")" choice
if ! [[ $choice =~ ^[1-9][0-9]*$ ]] || (( choice < 1 || choice > ${#keys[@]} )); then
  echo -e "${RED}Invalid selection.${RESET}"
  exit 1
fi

selected_key="${keys[choice-1]}"
uid_line=$(gpg --list-secret-keys --keyid-format=long "$selected_key" \
           | awk '/^uid/ { print; exit }')
name=$(echo "$uid_line" | sed -E 's/^.*] //; s/<.*>//; s/[[:space:]]+$//')
email=$(echo "$uid_line" | grep -oP '(?<=<).*(?=>)')

#–– Prepare Git commands
cmds=(
  "git config user.name \"$name\""
  "git config user.email \"$email\""
  "git config commit.gpgsign true"
  "git config user.signingkey $selected_key"
)

echo
echo -e "${BOLD}${CYAN}🛠 Suggested Git configuration commands:${RESET}"
for cmd in "${cmds[@]}"; do
  echo -e "  ${GREEN}$cmd${RESET}"
done

echo
read -rp "$(echo -e "${CYAN}🚀 Apply these settings now? (y/N): ${RESET}")" apply
if [[ $apply =~ ^[Yy]$ ]]; then
  for cmd in "${cmds[@]}"; do
    eval "$cmd"
  done
  echo -e "${GREEN}✅ Git configuration updated.${RESET}"
else
  echo -e "${YELLOW}⚠️ No changes applied.${RESET} You can copy & paste the commands later."
fi

