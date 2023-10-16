### EC2 instance creation
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

### UTM instance creation
1. https://docs.getutm.app/settings-qemu/system/#cpu
2. 500 GB storage
3. `$HOME/workspace/utm-shared` shared directory
4. Update to newer installer
5. Username `ubuntu` (password will be disabled later)
6. Install OpenSSH server
7. No featured server snaps

### Required
1. `sudo apt-get update && sudo apt-get upgrade`
2. Install typical packages: `sudo apt-get install build-essential clang direnv jq make net-tools protobuf-compiler zsh`
3. Set up the main user:
    1. Commands:
        ```shell
        sudo adduser --shell /usr/bin/zsh --gecos 'me' --disabled-password dschultz
        sudo usermod -aG sudo dschultz
        sudo mkdir ~dschultz/.ssh
        sudo chmod go-rwx ~dschultz/.ssh
        sudo cp ~ubuntu/.ssh/authorized_keys ~dschultz/.ssh/authorized_keys
        sudo chown -R dschultz:dschultz ~dschultz/.ssh
        ```
    2. (UTM only) `sudo vi ~dschultz/.ssh/authorized_keys` and paste in public key
    3. Append `dschultz ALL=(ALL) NOPASSWD:ALL` via `visudo`
    4. Login as `dschultz` with agent forwarded ssh keys for github
    5. (UTM only) `sudo deluser ubuntu`
4. Install ohmyzsh: `sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
5. Set up random config:
    1. From laptop in random working dir `dev-sync.sh`
    2. `ln -s $HOME/workspace/random/config/git/gitconfig $HOME/.gitconfig`
    3. [zsh custom](../zsh-custom/README.md)
6. Install docker:
    1. https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
    2. https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
        1. `sudo usermod -aG docker $USER`
    3. https://docs.docker.com/engine/install/linux-postinstall/#configure-docker-to-start-on-boot-with-systemd
    4. https://docs.docker.com/config/daemon/ipv6/
        1. Need to use non-conflicting IPv4 address pools in some environments
    5. `sudo reboot`
    6. `docker run hello-world`
7. Install gcloud: https://cloud.google.com/sdk/docs/install#deb
    1. `export AUTH_HEADER="Authorization: Bearer $(gcloud auth print-access-token)"`
8. Install `kubectl`: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
9. https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
10. Install helm: https://helm.sh/docs/intro/install/#from-apt-debianubuntu
11. Add idle shutdown crontab:
    * `echo "*/10 * * * * /home/dschultz/workspace/random/scripts/build-server/idle-shutdown.sh >> /home/dschultz/idle-shutdown.log 2>&1" | crontab`

### Optional
1. Install `gh`: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
    1. `gh auth login`
2. https://github.com/git-ecosystem/git-credential-manager/blob/release/docs/install.md
3. Install go: https://go.dev/doc/install
4. `touch ~/go && chmod ugo-rwx ~/go`
5. Install bazel: https://docs.bazel.build/versions/main/install-ubuntu.html#install-on-ubuntu
6. Link Wireshark command line tools on macOS:
    `ln -s /Applications/Wireshark.app/Contents/MacOS/* /usr/local/bin`
