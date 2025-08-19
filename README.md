# My dotfiles

My dotfiles, keep it simple.

### Install Starship

> [Gruvbox Rainbow Preset](https://starship.rs/presets/gruvbox-rainbow)

```bash
curl -sS https://starship.rs/install.sh | sh

starship preset gruvbox-rainbow -o ~/.config/starship.toml

sed -i '1s/^/eval "$(starship init bash)"\n/' ~/.bashrc

source ~/.bashrc
```