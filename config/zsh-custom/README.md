# Customizing zsh
1. Set as default shell
1. Install oh my zsh
1. Link in the custom scripts:
    ```shell
    ln -s $HOME/workspace/random/config/zsh-custom/themes/dwayne.zsh-theme $HOME/.oh-my-zsh/custom/themes
    ln -s $HOME/workspace/random/config/zsh-custom/aliases.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/bash-it-01-command_exists.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/bash-it-02-base.theme.bash.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/bash-it-03-githelpers.theme.bash.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/env.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/iterm2.zsh $HOME/.oh-my-zsh/custom
    ```
1. Edit `$HOME/.zshrc`
   1. Set `ZSH_THEME` to `dwayne`
   1. Add `pyenv` and `Z` to `plugins` list
   1. Comment out iterm integration (handled above)
   1. Add `unsetopt share_history` to keep each shell with its own history
