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

## Images

If you don't want to spend hours preparing the image and hours on building the image, I get it - you can use one of the following images that I've built. Note that these are unactivated copies of windows - you need to activate them on your own.

To download the torrent you need a functional I2P-capable bittorrent client. Easiest way to download them is to download [Java I2P client](https://geti2p.net/en/) or to use [I2PSnark with i2pd](https://i2pd.readthedocs.io/en/latest/tutorials/filesharing/). Others options are also available but are not tested by me - therefore are not endorsed.


| Name    | Base | Dockerfile | I2P Torrent |
| --- | --- | --- | --- |
| `windows:10iot_enterprise_ltsc2021-flutter` | `windows:10iot_enterprise_ltsc2021` | `flutter/Dockerfile.10iot_enterprise_ltsc2021` | **soon** |
| `windows:10iot_enterprise_ltsc2021` | manual | manual | **soon** |

To import the given docker image run 
```bash
$ zcat windows-10iot_enterprise_ltsc2021.tar.gz | docker import
```


> NOTE: `manual` was build manually [using these instructions](https://mrcyjanek.net/p/linux-subsystem-for-windows/) and following files (last one being resulting, manually configured disk image):
> `2463b19beac328290e6a8adcedb7533a  windows_10_iot_enterprise_ltsc_2021_257ad90f.iso`
> `e5d3f689e99fb56add9705baf408d34c  virtio-win-0.1.240.iso`
> `98e6bdb99a6fce96612d6425e087950e  ../windows10iot_enterprise_ltsc2021.img`

As you may notice in the `$ docker history` output, there is.. no history. Reason for that is the fact that during my work with images docker had the tendency to slow down with each layer, for this reason each flavor copies everything onto `scratch` image after shrinking the disk image (which also increases size if we take layers into account):

```dockerfile
RUN '..disk-optimize'

FROM scratch
COPY --from=stage00 / /

ENV QEMU_KVM_FLAGS=""
ENV QEMU_RAM_LIMIT=4G
ENV FORWARD_PORTS="8080"

ENTRYPOINT [ "/entrypoint.sh" ]
SHELL [ "/entrypoint.sh" ]
```

| IMAGE          | CREATED     | CREATED BY                       | SIZE       | COMMENT                  |
| -------------- | ----------- | -------------------------------- | ---------- | ------------------------ |
| `61102a4c0185` | 4 hours ago | `SHELL [/entrypoint.sh]`         | `0B`       | `buildkit.dockerfile.v0` |
| `<missing>`    | 4 hours ago | `ENTRYPOINT ["/entrypoint.sh"]`  | `0B`       | `buildkit.dockerfile.v0` |
| `<missing>`    | 4 hours ago | `ENV FORWARD_PORTS=8080`         | `0B`       | `buildkit.dockerfile.v0` |
| `<missing>`    | 4 hours ago | `ENV QEMU_RAM_LIMIT=4G`          | `0B`       | `buildkit.dockerfile.v0` |
| `<missing>`    | 4 hours ago | `ENV QEMU_KVM_FLAGS=`            | `0B`       | `buildkit.dockerfile.v0` |
| `<missing>`    | 4 hours ago | `COPY / / # buildkit`            | `9.94GB`   | `buildkit.dockerfile.v0` |


Note that this indeed raises some security concerns about the reproducibility and stuff.. but I'm not going to address them, at least not now. First I'll prepare a dockerfile that is capable of building windows from scratch inside of docker (without the need of manually enabling ssh and performing installation).