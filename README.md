# pve-cloudinit
A quick script to spin up a Proxmox cloud-init template base

## Set Up Script
- Start a shell session on the Proxmox host
- Clone the script - `git clone https://github.com/brendanlees/pve-cloudinit`
- Edit the script and update the values under the `'# --- defaults'` area - `nano cloud-init.sh`
- Make it executable - `chmod +x cloud-init.sh`
- Run it! - `sudo sh cloud-init.sh`

## Post Script Run (Proxmox GUI)

*(optional)*
Under 'Options', set :
- `Use tablet for pointer` = No
- `CPU` = Host
- `Memory` = uncheck 'Ballooning Device' 

Under 'Cloud-Init' options, set:
- `IP Config` = DHCP
- `Upgrade Packages` = Yes
- Add you SSH pub key, user credentials
- Don't run the VM - right-click and `Convert To Template`

