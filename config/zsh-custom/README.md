# Customizing zsh
1. Set as default shell (already default in latest)
2. Install oh my zsh
3. Install iterm2 shell integration
4. Edit `$HOME/.zshrc`
   1. Set `ZSH_THEME` to `dwayne`
   2. Add `(direnv git pyenv ssh-agent z)` to `plugins` list

      NOTE: DO NOT use `ssh-agent` on hosts that will be ssh'ed to (it overwrites forwarded keys)
5. Link in the custom scripts:
    ```shell
    ln -s $HOME/workspace/random/config/zsh-custom/aliases.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/aws.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/bash-it-01-command_exists.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/bash-it-02-base.theme.bash.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/bash-it-03-githelpers.theme.bash.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/env.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/idea.zsh $HOME/.oh-my-zsh/custom
    ln -s $HOME/workspace/random/config/zsh-custom/themes/dwayne.zsh-theme $HOME/.oh-my-zsh/custom/themes
    ```
6. Another script for cloud-based build servers:
    ```shell
    ln -s $HOME/workspace/random/config/zsh-custom/idle-shutdown.zsh $HOME/.oh-my-zsh/custom
    ```

# Additional customization for desktops
1. Create `$HOME/.oh-my-zsh/custom/build-server.zsh`:
    ```shell
    export BUILD_USER=dschultz

    #. $HOME/workspace/scratch/build-servers/inactive-server1.sh
    #. $HOME/workspace/scratch/build-servers/inactive-server2.sh
    . $HOME/workspace/scratch/build-servers/active-server.sh
    ```
    Each file has the format:
    ```shell
    export BUILD_INSTANCE_ID=<cloud instance id (instance name for openstack)>
    export BUILD_SERVER_SHORT_NAME="<identifying emoji>"
    export BUILD_SERVER=<ip address>
    export BUILD_SERVER_SSH_KEY_FILE=<ssh private key>
    ```
2. Create `$HOME/.oh-my-zsh/custom/openstack.zsh`:
    ```shell
    export OS_AUTH_URL=< Project -> API Access -> Identity >
    export OS_PROJECT_ID=< Identity -> Projects -> Project ID >
    export OS_USER_ID=< Identity -> Users -> User ID >
    ```
3. Link in `~/bin` scripts:
    ```shell
    mkdir $HOME/bin
    ln -s $HOME/workspace/random/scripts/build-server/dev-diff.sh $HOME/bin
    ln -s $HOME/workspace/random/scripts/build-server/dev-sync.sh $HOME/bin
    ln -s $HOME/workspace/twistio-docs/docs/_static/helper-scripts/download-release.sh $HOME/bin
    ln -s $HOME/workspace/random/scripts/git/open-pr.sh $HOME/bin
    ln -s $HOME/workspace/random/scripts/openstack/os-login.sh $HOME/bin
    ln -s $HOME/workspace/random/scripts/aws/sso-login.sh $HOME/bin
    ln -s $HOME/workspace/random/scripts/aws/sso-minutes-remaining.sh $HOME/bin
    ```
