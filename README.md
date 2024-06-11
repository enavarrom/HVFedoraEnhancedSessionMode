# Fedora 4x Enhanced Session Mode 

Script to configure Hyper-V Enhanced Session Mode on Fedora 40+.



1. Run the script with root privilegies:

```
sudo chmod +x install_esm_fedora4x.sh
sudo ./install_esm_fedora4x.sh
```


2. Enable XRPD on your Hyper-V Machine. Run in PowerShell with Administrator privilegies.

```
Set-VM -VMName "Fedora VM Name" -EnhancedSessionTransportType HvSocket
```
