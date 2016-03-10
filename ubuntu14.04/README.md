# Packer Ubuntu 14.04-4 builder

These are scripts to build base image of Ubuntu 14.04-4 for 
- Virtual Box
- VMWare
- Openstack

## Usage

./packer.sh (build|validate) (virtualbox|vmware|openstack|all)

This will build images for the supplied platform(s) or all. If the option validate is issued then the template will only be checked for syntax.

## ESX password

If a vmware build is requested & the environment variable **VMWARE_PASSWORD** is not set then the password to connect to the ESX server will be requested. This is required for the creation of the output OVF file. It can be supplied in the VMWARE_PASSWORD environment variable if required.

## VMWare private key

Communication with the ESX server is via SSH a private key is required to connect to the server, this should be placed in the file **vmware_private_key.pem** 

## Openstack Credentials

The packer.sh script should be modified with the appropriate openstack credentials in the variables:-

- OS_USERNAME
- OS_PASSWORD
- OS_TENANT_NAME


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


