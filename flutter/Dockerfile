FROM windows:10iot_enterprise_ltsc2021

# Install chocolatey
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# do a reboot (each RUN is a full boot -> execute -> shutdown) cycle.

# install software
RUN choco install -y visualstudio2022community \
    && choco install -y visualstudio2022-workload-nativedesktop \
    && choco install -y git \
    && choco install -y flutter
