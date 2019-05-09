# Readme

## PackerWrapper

The PackerWrapper.ps1 script is a simple wrapper script which can be used either on its own, or as a function in other powershell scripts. PackerWrapper will insert variables into the Packer exe through the use of parameters (defined below).

 * OSName     -     The name of the Operating System for the new AMI. Current options are Win2012R2 or Win2016Std
 * AMIPrefix  -     The prefix to give the new AMI once created. Packer will append a timestampt to the end to ensure unique names are always assigned.  
 * jsonConfig -     The path to the json file containing the packer configuration for the new image.


## Packer

When creating a Windows AMI, we need to enable WinRm first so that Packer can establish a connection. 

This is specified in the Builder section of the instance deployment, not the provisioner.

The file "bootscript_win.txt" contains the required commands to enable WinRm within the new Windows instance. This is added to the 'User Data' script section of the newly deployed instance. Packer then uses this to connect to the instance and start the customisation.

A password will need to be added to the bootscript_win.txt, the password set here will then need to be added to the json config.


AMI Builer options:
    user_data_file          (string) - Path to a file that will be used for the user data when launching the instance.
    user_data               (string) - User data to apply when launching the instance. Note that you need to be careful about escaping characters due to the templates being in JSON format. It is often more convenient to use a user_data_file, instead.
    "communicator":         communicators are the mechanism Packer uses to upload files & execute scripts while the machine is being created. 3 options:
                                    SSH
                                    winrm
                                    none



### Provisioners:

#### PowerShell
The json config runs the scripts found in the script directory using a powershell provisioner...
  
There are two different ways of using the powerShell provisioner: inline & script.

inline - used to specify short snippets of code or commands and creates the script file for you.

script - allows you to run more complex code by providing the path to a script to run on the guest VM.

```JSON
{
"type":"powershell",
      "scripts": [
        "./webserver_new/scripts/winconfig.ps1",
        "./webserver_new/scripts/Ec2Config.ps1",
        "./webserver_new/scripts/BundleConfig.ps1"
        }
```        

#### file

The file provisioner is used to copy files to the new instance. The example here is copying the LAPSx64.msi file (a small application which resets the local administrator to a random password) to "C:\Windows\temp" directory.    *Notice the double backslashes in the path, this is deliberate and is required when writing a windows path.

```JSON
    {
      "type": "file",
      "source": "./provisioners/files/LAPSx64.msi",
      "destination": "c:\\windows\\temp\\LAPSx64.msi"
    },

```

## Example builds
Several child directories have been included in this repo, with example json configuration files for creating AMI images. These include:
 
 * webserver    - A configuration that will create a Windows EC2 AMI, withseveral windows roles & features enabled (IIS, .Net Framework etc).

These scripts are just examples but they do show how to perform some important tasks. 

 * Ec2Config.ps1        -   This re-enables elements, specifically used by ec2, that ensure that the the windows hostname is changed for each subsequent deployment.
 * BundleConfig.ps1     -   This script will perform a sysprep of the instance before the new AMI is created.
 * winconfig.ps1        -   This is really just a sample script to show how Windows can be configured. In this case, the script enables several Roles & Features and performs an installation of an application (LAPSx64.msi). The LAPSx64.msi is first copied to the Windows instance using the 'file' provisioner in the packer config (see ### file section above). 

## webserver-pts

Modified packer-core.json packer image with the server and IIS configuration based on PTS webserver configuration


 * provisioners/scripts/pts_winconfig.ps1       -    adds additional server features and services used on PTS
 * provisioners/scripts/mvc4_install.ps1        -    upgrades PowerShell, enables NuGet package manager and installs MVC 4.0.40804
 
## webserver-pts2aws
 
Modified packer-core.json packer image with the server and IIS configuration based on PTS webserver configuration with IIS configuration from PTS webserver restored

  * provisioners/scripts/clean_iis_conf.ps1     -    deletes default IIS site and application pools  
  * provisioners/scripts/restore_iis_conf.ps1   -    restores IIS configuration from PTS IIS configuration backup files
 
IIS configuration backup files:
  * provisioners/files/apppools.xml             -    application pool configuration backup from PTS
  * provisioners/files/ sites.xml               -    IIS sites configuration backup from PTS
 
