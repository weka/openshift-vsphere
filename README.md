# ironicbadger/ocp4

This repo contains code to deploy Openshift 4 for my homelab. It focuses on UPI with vSphere 6.7u3, a full write up is
available on [openshift.com](https://www.openshift.com/blog/how-to-install-openshift-4.6-on-vmware-with-upi).

> May 2021 - The code here is working against 4.7.

## Pre-reqs

On a Mac you will need to install a few packages via `brew`.

    brew install jq watch gsed

## Prerequisites

If on linux: install Brew (https://brew.sh/)

1. Install tfswitch  `brew install warrensbox/tap/tfswitch`
2. Install terraform 1.2.4 `tfswitch -b ~/bin` -> choose 1.2.4
3. Install govc 
   ```
   sudo curl -L -o - "https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz" | \
   sudo tar -C /usr/local/bin -xvzf - govc
   ```
4. Configure govc to use correct credentials 
   # TODO: TBD
5. On vSphere, create VM folder hierarchy coreos/ocp410


## Usage

Code for each OCP release lives on a numbered branch. The master branch represents the latest stable iteration and will
likely be behind branches. In otherwords, check the number branches first before looking at master.

> * This repo *requires* Terraform 0.13 or newer
> * Install `oc tools` with `./install-oc-tools.sh --latest 4.6`
> * This code use yamldecode -
    details [here](https://blog.ktz.me/store-terraform-secrets-in-yaml-files-with-yamldecode/)

0. Create `~/.config/ocp/vsphere.yaml` for `yamldecode` use, sample content:

```
alex@mooncake ~ % cat .config/ocp/vsphere.yaml
vsphere-user: administrator@vsphere.local
vsphere-password: "123!"
vsphere-server: 192.168.1.240
vsphere-dc: ktzdc
vsphere-cluster: ktzcluster
```

1. Configure DNS - https://blog.ktz.me/configure-unbound-dns-for-openshift-4/ - if using CoreDNS this is optional.
2. Create `install-config.yaml` and ensure `cluster_slug` matches `metadata: name:` below.
    
    ```
    apiVersion: v1
    baseDomain: openshift.lab.int
    compute:
    - hyperthreading: Enabled
      name: worker
      replicas: 0
    controlPlane:
      hyperthreading: Enabled
      name: master
      replicas: 3
    metadata:
      name: ocp4
    platform:
      vsphere:
        vcenter: 192.168.1.240
        username: administrator@vsphere.local
        password: supersecretpassword
        datacenter: ktzdc
        defaultDatastore: nvme
    fips: false 
    pullSecret: 'YOUR_PULL_SECRET'
    sshKey: 'YOUR_SSH_PUBKEY'
    ```

3. Customize `clusters/lab/terraform.tfvars` with any relevant configuration.
4. Run `./install-oc-tools.sh --version OCP_VERSION`
6. Run `make tfinit` to initialise Terraform modules
7. Run `make lab` to create the VMs and generate/install ignition configs
8. Monitor install progress with `make wait-for-bootstrap`
9. Check and approve pending CSRs with `make get-csr` and `make approve-csr`
10. Run `make bootstrap-complete` to destroy the bootstrap VM
11. Run `make wait-for-install` and wait for the cluster install to complete
12. Enjoy!
