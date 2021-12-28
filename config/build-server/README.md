1. `sudo apt-get install build-essential direnv make protobuf-compiler zsh`
2. `sudo adduser --shell /usr/bin/zsh --gecos 'me' --disabled-password dschultz`
3. `sudo usermod -aG sudo dschultz`
4. Append `dschultz ALL=(ALL) NOPASSWD:ALL` via `visudo`
5. Copy `~ubuntu/.ssh/authorized_keys` to `~dschultz/.ssh/authorized_keys`
6. https://go.dev/doc/install
7. Login as `dschultz` with agent forwarded ssh keys for github
8. `sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
9. `mkdir workspace && cd workspace`
10. `git clone git@github.com:myshkin5/random.git`
11. `ln -s $HOME/workspace/random/config/git/gitconfig $HOME/.gitconfig`
12. [zsh custom](../zsh-custom/README.md)
