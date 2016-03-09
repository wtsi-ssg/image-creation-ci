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


