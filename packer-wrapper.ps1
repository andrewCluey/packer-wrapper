<#
.SYNOPSIS
 Powershell script which wraps around Packer to build a new AMI image in AWS. Packer.exe should be defined in the system PATH for easier execution.
.DESCRIPTION
 The paramaters entered when launching PackerWrapper.ps1 are passed into the Packer.exe command line. For example, $OSName is a validated parameter and can be either Win2012R2 or Win2016Std. 
 If Win2012R2 then the $OSData variable is set as:

  $osData = @{
           os_name = "Windows_Server-2012-R2_RTM-English-64Bit-Base*"
            full_os_name = "Windows2012R2"
        }

 When packer.exe is run with the defined arguments,
 'OS_Name' becomes "Windows_Server-2012-R2_RTM-Englisg-64Bit-Base" 
 packer passes this into the json customisation file. The *.json config file uses this variable to create a filter
 query to find the correct AMI in AWS.

.PARAMETER OSName
 Mandatory parameter. Instruct packer to create an AMI of specific Operating System. Must be either "Win2012R2" or "Win2016Std". 
.PARAMETER AMIPrefix
 Mandatory parameter. Used to set the prefix for the name of the New AMI that will be created. Packer will append a timestamp to this prefix to create a unique name.
.PARAMETER jsonConfig
 Mandatory parameter. Specify the json config file to use to create the packer image. Use the full UNC path.
.NOTES
FileName                : PackerWrapper.ps1
Author                  : Andrew Clure
Prerequisite            : PowerShell v4+ and Packer.exe
Version                 : 0.1

The Win-FirstRun16.json file is an example packer json which configures WinRm, sets the local admin password
and performs some simple boot commands in the form of PowerShell provisioners.
For the scripts to work succesfully, the following script block must be added to the JSON config file when creating a Windows image.

Bootstrap_win.txt file also has to be located in the same directory where the .json config is located.
    "
        {
    "variables": {
      "aws_access_key": "",
      "aws_secret_key": "",
      "region":         "eu-west-2",
      "OS_Name": "",
      "AMIPrefix": ""
    },
    "builders": [
      {
        "type": "amazon-ebs",
        "access_key": "{{ user `aws_access_key` }}",
        "secret_key": "{{ user `aws_secret_key` }}",
        "region": "{{ user `region` }}",
        "instance_type": "t2.micro",
        "source_ami_filter": {
          "filters": {
            "virtualization-type": "hvm",
            "name": "{{ user `OS_Name` }}",
            "root-device-type": "ebs"
          },
          "most_recent": true,
          "owners": "amazon"
        },
        "ami_name": "{{user `AMIPrefix` }}-{{timestamp}}",
        "user_data_file": "./bootstrap_win.txt",
        "communicator": "winrm",
        "winrm_username": "Administrator",
        "winrm_password": ""
      }
    ]
    }
    "

.OUTPUTS
Packer.exe will write all returned text to a file named 'out.txt' in the directory where packer.exe was executed from
.EXAMPLE
./PackerWrapper.ps1 -OSName Win2012R2 -AMIPrefix win2012R2 -jsonConfig C:\packer\config\rdgw.json
#>

[cmdletbinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Win2012R2", "Win2016Std")]
    $OSName,
    [parameter(Mandatory=$true)]$AMIPrefix,
    [Parameter(Mandatory=$true)]$jsonConfig
)

# finds an AMI image in AWS 
$key = Read-Host -Prompt "Enter AWS access key"
$secretKey = Read-Host -Prompt "Enter AWS secret key"

switch ($OSName)
{
    'Win2012R2' {
        $osData = @{
            os_name = "Windows_Server-2012-R2_RTM-English-64Bit-Base*"
            full_os_name = "Windows2012R2"
        }
    }

    'Win2016StdCore' {
        $osData = @{
            os_name = "Windows_Server-2016-English-Full-Base*"
            full_os_name = "Windows2016Std"
        }
    }
}

# Base Image

start-process -FilePath 'packer.exe' -wait -ArgumentList "build  -var `"OS_Name=$($osData.os_name)`" -var `"aws_access_key=$($key)`" -var `"aws_secret_key=$($secretkey)`" -var `"AMIPrefix=$($AMIPrefix)`" $jsonConfig" -RedirectStandardoutput .\out.txt
