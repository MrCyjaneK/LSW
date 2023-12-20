#!/bin/bash
set -xe
# ./docker_prep.sh windows-win10_22h2_engint_x64v1-current.img win10_22h2_engint_x64v1-current

IMG_FILE="$1"
if [[ ! -f "$IMG_FILE" ]];
then
    echo "File doesn't exist."
    exit 1
fi
DOCKER_TAG="$2"

if [[ "x$DOCKER_TAG" == "x" ]];
then
    echo "invalid docker tag."
    exit 1
fi

BUILD_DIR="$DOCKER_TAG"

rm -rf "$BUILD_DIR"
mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

ln "../$IMG_FILE" disk.img

ln ../entrypoint.sh .
ln ../FILES_README.txt .
echo '# syntax=docker/dockerfile:1-labs' > Dockerfile
echo 'FROM debian:stable as stage00' >> Dockerfile
echo >> Dockerfile
echo "RUN apt update \\" >> Dockerfile
echo "    && apt install -y qemu-system ssh sshpass cpu-checker genisoimage libguestfs-tools \\" >> Dockerfile
echo "    && apt clean" >> Dockerfile
echo >> Dockerfile
echo "COPY disk.img /opt/disk.img" >> Dockerfile
echo >> Dockerfile

echo "RUN --security=insecure mkdir \$HOME/.cache \\" >> Dockerfile
echo "    ; TMPDIR=\$HOME/.cache virt-sparsify \\" >> Dockerfile
echo "        --compress \\" >> Dockerfile
echo "        --convert qcow2 \\" >> Dockerfile
echo "        --verbose \\" >> Dockerfile
echo "        /opt/disk.img \\" >> Dockerfile
echo "        /opt/disk-shrink.img \\" >> Dockerfile
echo "    && echo 'Replacing source disk with optimized one' \\" >> Dockerfile
echo "    && rm /opt/disk.img \\" >> Dockerfile
echo "    && mv /opt/disk-shrink.img /opt/disk.img \\" >> Dockerfile
echo "    && rm -rf \$HOME/.cache" >> Dockerfile
echo >> Dockerfile
echo "COPY entrypoint.sh /entrypoint.sh" >> Dockerfile
echo "COPY FILES_README.txt /cdrom/README.txt" >> Dockerfile
echo >> Dockerfile
echo "RUN chmod +x /entrypoint.sh" >> Dockerfile
echo >> Dockerfile
echo 'FROM scratch' >> Dockerfile
echo 'COPY --from=stage00 / /' >> Dockerfile
echo  >> Dockerfile
echo 'ENV QEMU_KVM_FLAGS=""' >> Dockerfile
echo 'ENV QEMU_KVM_FLAGS=" -enable-kvm -cpu host"' >> Dockerfile
echo 'ENV QEMU_RAM_LIMIT=4G' >> Dockerfile
echo 'ENV FORWARD_PORTS="8080"' >> Dockerfile
echo >> Dockerfile
echo 'ENTRYPOINT [ "/entrypoint.sh" ]' >> Dockerfile
echo 'SHELL [ "/entrypoint.sh" ]' >> Dockerfile
