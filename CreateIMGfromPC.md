Steps:
1. Log in to Prism Element
2. Click on Gear icon -> Filesystem Whitelists , add Prism Central IP to the list.
3. Log in to one of the CVMs of the cluster where the VM resides.
4. acli vm.list
5. vm.get <vm name> include_vmdisk_paths=true 6. Look for 'vmdisk_nfs_path' for each disk in the output.
7. Log in to Prism Central web UI
8. Click on Explore -> images -> Add Image -> URL 9. Enter " nfs://<cluster_IP>/<NFS_path_from_step_4> 
