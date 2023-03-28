# Customizing zsh
1. Set as default shell (already default in latest)
2. Install oh my zsh
3. Install iterm2 shell integration
4. Edit `$HOME/.zshrc`
   1. Set `ZSH_THEME` to `dwayne`
   2. Add `(direnv git pyenv ssh-agent z)` to `plugins` list

      NOTE: DO NOT use `ssh-agent` on hosts that will be ssh'ed to (it overwrites forwarded keys)
   3. Comment out iterm integration (handled below)
5. Link in the custom scripts:
    ```shell
    ln -s $HOME/workspace/random/config/zsh-custom/aliases.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/aws.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/bash-it-01-command_exists.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/bash-it-02-base.theme.bash.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/bash-it-03-githelpers.theme.bash.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/env.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/iterm2.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/idle-shutdown.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/themes/dwayne.zsh-theme $HOME/.oh-my-zsh/custom/themes
    ```
6. Create `$HOME/.oh-my-zsh/custom/openstack.zsh`:
    ```shell
    export OS_AUTH_URL=< Project -> API Access -> Identity >
    export OS_PROJECT_ID=< Identity -> Projects -> Project ID >
    export OS_USER_ID=< Identity -> Users -> User ID >
    ```
