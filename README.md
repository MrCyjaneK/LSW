# LSW - running Windows, the linux way in docker (on linux).

Linux (Windows) subsystem for Windows (for Linux)

> Also, am I the only person who thinks that a better name (for the competing product, WSL) would be Linux subsystem for Windows?

For the full story and setup instructions [come to my blog](https://mrcyjanek.net/p/linux-subsystem-for-windows/)

## Examples

```dockerfile
FROM windows:10iot_enterprise_ltsc2021

RUN Set-ExecutionPolicy Bypass -Scope Process -Force \
    ; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072 \
    ; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# <reboot takes place somewhere in here>

RUN choco install -y visualstudio2022community \
    && choco install -y visualstudio2022-workload-nativedesktop \
    && choco install -y git \
    && choco install -y flutter
```

or to get straight to the `docker run`:

```bash
$ uname -s -r
Linux 6.1.68
$ docker run --device=/dev/kvm --rm -it windows:10iot_enterprise_ltsc2021 systeminfo
Host Name:                 DESKTOP-GLPCL5M
OS Name:                   Microsoft Windows 10 IoT Enterprise LTSC
OS Version:                10.0.19044 N/A Build 19044
OS Manufacturer:           Microsoft Corporation
OS Configuration:          Standalone Workstation
OS Build Type:             Multiprocessor Free
{...}
```
