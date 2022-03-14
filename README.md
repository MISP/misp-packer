# Build Automated Machine Images for MISP

Fork of misp-packer

Works with ubuntu 20.04.4 iso

Changes:

-   .json packer file converted to hcl2 with builtin packer converter.
-   required_plugins defined to allow installation with packer init.
-   Variables seperated into "variables.pkr.hcl" file.
-   Other common settings between builders turned into variables and defaults set.
-   Default variable overides in "variables.auto.pkrvars.hcl" file.
-   VirtualBox modifyvm variables moved to main source block where compatible.
-   Removed VirtualBox modifyvm variables that are setting a value that is already the default.
-   Created seperate `user-data` files as ubunu 20.04 uses `enp0s3` interface in virtualbox and `ens33` in vmware.
-   Created seperate issue files for virtualbox and vmware due to different networking interfaces.
-   Removed VirtualBox port forwards for Jupyter as it seems it is no longer installed.
-   Removed VirtualBox port forwards for Viper and Misp Dashboard as current Install script staes they are broken and not installed.
-   Boot command changed as was not working while testing.
-   Cloud config files are now mounted as cidata instead of using http.
-   INSTALL.sh needs placing in scripts folder as build scripts which download the file have not been updated.
-   Output directory has changed to "output/${var.vm_name}_{{ .Builder }}/". Easy enough to change back if wanted.
-   Post Processor checksum is used to create checksums for boxes.

To-do:

-   Update .sh scripts (This was not done as I wasn't too familiar with what a lot of them did).
-   Full Testing as I have limited experience with misp.

Instructions:
-   Read Notes
-   Run `packer init .` to install required plugins.
-   Place latest [INSTALL.sh]("https://raw.githubusercontent.com/MISP/MISP/2.4/INSTALL/INSTALL.sh") in scripts folder.
-   Run `Packer build -only=vmware-iso .` for vmware build. `Packer build -only=vmware-iso.ubuntu .` on mac.
-   Run `Packer build -only=virtualbox-iso .` for virtualbox build. `Packer build -only=virtualbox-iso.ubuntu .` on mac
-   Run `Packer build .` to build both.

Notes:
-   Timing is important, different hosts load at different speeds, boot_wait needs changing to suit the build host. Seperate variables exist for Virtualbox and VMWare.
