# Packer Ubuntu 14.04-4 builder

These are scripts to build base image of Ubuntu 14.04-4 for 
- Virtual Box
- VMWare
- Openstack




## Usage

./packer.sh (build|validate) (virtualbox|vmware|openstack|all)

This will build images for the supplied platform(s) or all. If the option validate is issued then the template will only be checked for syntax.

## Prequisites

- Packer version 0.9.0 (or later) (assumed to be in ${HOME}/bin/packer)
- Openstack packages
-- python-glanceclient
-- python-novaclient
- Qemu

## ESX password

If a vmware build is requested & the environment variable **VMWARE_PASSWORD** is not set then the password to connect to the ESX server will be requested. This is required for the creation of the output OVF file. It can be supplied in the VMWARE_PASSWORD environment variable if required.

## VMWare private key

Communication with the ESX server is via SSH a private key is required to connect to the server, this should be placed in the file **vmware_private_key.pem** 

## Openstack Credentials

The openstack.sh script should be modified with the appropriate openstack credentials & environment in the variables:-


- COMPUTE_API_VERSION

Version required to support openstack clients (1.1 minimum)

- OS_CLOUDNAME

Name of the cloud to connect to (in the event of multiple cloud environments)

- OS_AUTH_URL

URL of the API endpoint

- NOVA_VERSION

Should match the COMPUTE_API_VERSION above.

- OS_USERNAME

Username to connect to the openstack environment with

- OS_PASSWORD

Password for the above user

- OS_TENANT_NAME

Tenant within openstack to use for the build

- OS_BASE_IMAGE

Base image ID to use for the build

- OS_SECURITY_GRP

Security group to apply to the build (must allow SSH access to the booted image)

## 


## Scripts

The scripts directory contains provisioner scripts that are called by packer to customize the image.

- compiler_tools.sh

Installs the packages require to bulid software & linux kernel

- sudoers.sh

Updates the sudoers file

- update.sh

Updates all packages to the latest version (apt-get ugrade / dist-upgrade) and purges the cache

- install_cloud-init.sh

Installs the cloud-init package used for per-instance configuration of the machine.

This script also patches the cc_disk_setup.py module of cloud init to fix a bug in version 0.7.5. The script will check that the file is the correct one before attempting to patch.

The Cloud-init configuration is updated to cause the initialization & mounting of the first extra disk (the name of this is dependant on the hypervisor in use - vdb for openstack or sdb for vmware/virtualbox)

- install_vmtools.sh (only run on vmware build)

Installs the vmwaretools provided by the hypervisor. Note these are the vmware supplied tools not the "recommended" opensource tools - these would not install cleanly at the time of writing (16/3/2016)

## VMWare cleanup

If the vmware build fails it can leave residue behind on the ESX host. This will prevent future builds from working. 

To clean up:-

- Login to the esxi host:-
```
ssh -i vmware_private_key.pem vmbuildadmin@wtgc-vmbd-01.internal.sanger.ac.uk
cd /vmfs/volumes/wtgc-vmbd-01:datastore1
```

- Check to see if there are any registered vms:-
	
```	
vim-cmd vmsvc/getallvms
Vmid         Name                                        File                                    Guest OS      Version   Annotation
40     packer-vmware-iso   [wtgc-vmbd-01:datastore1] packer-vmware-iso/packer-vmware-iso.vmx   ubuntu64Guest   vmx-08              
```

_Here 40 is the VM identifier, that will be used for the further examples, this will be different._

- If there are any registered under **'packer-vmware-iso'** then check their power state:-

```
vim-cmd vmsvc/power.getstate 40
Retrieved runtime info
Powered off
```

- If running power off with `vim-cmd vmsvc/power.off 40` 
- Unregister the VM with `vim-cmd vmsvc/unregister 40`
- Finally delete the directory 'packer-vmware-iso' (if it exists)


