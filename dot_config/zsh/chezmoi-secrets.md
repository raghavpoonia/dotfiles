# chezmoi-secrets.md
# Setting up chezmoi encrypted secrets with age
# For vars that need to follow you across machines
# ruwgxo/dotfiles


## When to use this vs Keychain

Keychain (secret-helpers.zsh)
- Best for: project secrets that live on one machine
- Values entered manually per machine
- Never leaves the machine

chezmoi + age encryption
- Best for: vars you want on every machine automatically
- Encrypted in the dotfiles repo — safe to commit
- Decrypted locally on each machine with your age key
- Good for: personal API tokens, global tool configs


## Setup

1. Install age

    brew install age

2. Generate your age key (once, ever)

    age-keygen -o ~/.config/chezmoi/key.txt

    This creates a key pair. The public key is printed — copy it.
    The private key is in key.txt — never share or commit this file.

3. Tell chezmoi to use age

    Add to ~/.config/chezmoi/chezmoi.toml:

    [age]
      identity = "~/.config/chezmoi/key.txt"
      recipient = "age1YOUR_PUBLIC_KEY_HERE"

4. Add an encrypted secret to chezmoi

    chezmoi secret keyring set --service=myservice --user=myuser

    Or encrypt a file:

    chezmoi add --encrypt ~/.config/sometool/config


## Storing cross-machine env vars

Create an encrypted template in chezmoi:

    chezmoi edit ~/.config/zsh/global-secrets.zsh

Inside that file (chezmoi encrypts it):

    export GITHUB_TOKEN="{{ (index (chezmoi secret keyring get --service=github --user=token) "password") }}"
    export ANTHROPIC_API_KEY="{{ ... }}"

Then source it in .zshrc:

    source ~/.config/zsh/global-secrets.zsh


## Key safety rules

- ~/.config/chezmoi/key.txt — never commit, never share
- Add to .gitignore: key.txt
- Back it up to a hardware key or password manager
- If lost, re-encrypt all secrets with a new key
- Age encrypted files in the repo are safe to commit and make public