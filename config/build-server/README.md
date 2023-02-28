1. EC2 instance
   1. Name: dschultz, Team: twistio
   2. Ubuntu 20.04
   3. m6a.4xlarge
   4. dschultz ed25519 key-pair
   5. vpc-0aabd...
   6. Assign public IP (both IPv4 and IPv6)
   7. dschultz-build-server security group
   8. 500 GB gp3 root volume
2. Create an EIP and associate it with the instance
3. `sudo apt-get update`
4. Install typical packages: `sudo apt-get install build-essential clang direnv jq make net-tools protobuf-compiler zsh`
5. Set up the main user:
   1. `sudo adduser --shell /usr/bin/zsh --gecos 'me' --disabled-password dschultz`
   2. `sudo usermod -aG sudo dschultz`
   3. Append `dschultz ALL=(ALL) NOPASSWD:ALL` via `visudo`
   4. `sudo mkdir ~dschultz/.ssh`
   5. `sudo chmod go-rwx ~dschultz/.ssh`
   6. `sudo cp ~ubuntu/.ssh/authorized_keys ~dschultz/.ssh/authorized_keys`
   7. `sudo chown -R dschultz:dschultz ~dschultz/.ssh`
   8. Login as `dschultz` with agent forwarded ssh keys for github
6. Install ohmyzsh: `sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
7. Install go: https://go.dev/doc/install
8. Workspace: `mkdir workspace && cd workspace`
9. Set up random config:
   1. From laptop in random working dir `dev-sync.sh`
   2. `ln -s $HOME/workspace/random/config/git/gitconfig $HOME/.gitconfig`
   3. [zsh custom](../zsh-custom/README.md)
10. Install docker:
    1. https://docs.docker.com/engine/install/ubuntu/#set-up-the-repository
    2. https://docs.docker.com/engine/install/ubuntu/#install-docker-engine
    3. https://docs.docker.com/engine/install/linux-postinstall/
       1. `sudo usermod -aG docker $USER`
    4. https://docs.docker.com/engine/install/linux-postinstall/#configure-docker-to-start-on-boot
    5. https://docs.docker.com/config/daemon/ipv6/
11. Install bazel: https://docs.bazel.build/versions/main/install-ubuntu.html#install-on-ubuntu
12. Install gcloud: https://cloud.google.com/sdk/docs/install#deb
    1. `export AUTH_HEADER="Authorization: Bearer $(gcloud auth print-access-token)"`
13. Install `gh`: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
    1. `gh auth login`
14. Install helm: https://helm.sh/docs/intro/install/#from-apt-debianubuntu
15. Install KinD: https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries
16. Install `kubectl`: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
17. https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
