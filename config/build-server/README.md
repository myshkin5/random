1. Install typical packages: `sudo apt-get install build-essential direnv jq make net-tools protobuf-compiler zsh`
2. Set up the main user:
   1. `sudo adduser --shell /usr/bin/zsh --gecos 'me' --disabled-password dschultz`
   2. `sudo usermod -aG sudo dschultz`
   3. Append `dschultz ALL=(ALL) NOPASSWD:ALL` via `visudo`
   4. Copy `~ubuntu/.ssh/authorized_keys` to `~dschultz/.ssh/authorized_keys`
   5. Login as `dschultz` with agent forwarded ssh keys for github
3. Install go: https://go.dev/doc/install
4. Install ohmyzsh: `sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
5. Workspace: `mkdir workspace && cd workspace`
6. Set up random config:
   1. `git clone git@github.com:myshkin5/random.git`
   2. `ln -s $HOME/workspace/random/config/git/gitconfig $HOME/.gitconfig`
   3. [zsh custom](../zsh-custom/README.md)
7. Install docker:
   1. https://docs.docker.com/engine/install/ubuntu/#set-up-the-repository
   2. https://docs.docker.com/engine/install/ubuntu/#install-docker-engine
   3. https://docs.docker.com/engine/install/linux-postinstall/
      1. `sudo usermod -aG docker $USER`
8. Install bazel: https://docs.bazel.build/versions/main/install-ubuntu.html#install-on-ubuntu
9. Install gcloud: https://cloud.google.com/sdk/docs/install#deb
10. Install `gh`: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
11. Install helm: https://helm.sh/docs/intro/install/#from-apt-debianubuntu
