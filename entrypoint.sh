#!/bin/bash
if [[ "x$1" == "x--linux" ]];
then
    exec bash
    exit 255
fi

if [[ "x$1" == "--disk-optimize" ]];
then
    echo "Optimizing disk storage. Resulting disk will be placed in /opt/disk-shrink.img"
    echo "This procedure should only be ran in Dockerfile."
    echo "To speedup the process you may want to run it with --device /dev/kvm"
    echo "or RUN --security=insecure"
    echo "This will reduce amount of time that is required for this operation by at least 10x"
    sleep 5
    mkdir $HOME/.cache
    TMPDIR=$HOME/.cache virt-sparsify \
        --compress \
        --convert qcow2 \
        --verbose \
        /opt/disk.img \
        /opt/disk-shrink.img
    echo "Replacing source disk with optimized one"
    rm /opt/disk.img
    mv /opt/disk-shrink.img /opt/disk.img
    rm -rf $HOME/.cache
    exit 0
fi

if [[ ! -f "/cdrom.iso" ]];
then
    echo "[ISO] Creating cdrom.iso"
    genisoimage -o /cdrom.iso -V LSW -R -J /cdrom
fi

exit_script() {
    echo "[OUTPUTS] Moving C:\\outputs to /outputs"
    mkdir /outputs
    scp -p '' -r -P22 user@127.0.0.1:/outputs/'*' /outputs/
    ssh user@127.0.0.1 -p22 rd /s /q "C:\\outputs"
    sshpass ssh -o StrictHostKeyChecking=no user@127.0.0.1 -p22 shutdown -s -t 1 || (killall -9 qemu-system-x86_64)
    echo "[QEMU] Shutting down guest"
    until ! killall -0 qemu-system-x86_64;
    do
        sleep 1
    done
    echo "[QEMU] Guest offline"
    echo "[ISO] Cleaning up iso"
    rm -f /cdrom.iso
    trap - SIGINT SIGTERM # clear the trap
    exit $EXITCODE
    # kill -- -$$ # Sends SIGTERM to child/sub processes
}
trap exit_script SIGINT SIGTERM

QEMU_KVM_FLAGS=""
kvm-ok && QEMU_KVM_FLAGS="$QEMU_KVM_FLAGS -enable-kvm -cpu host" || QEMU_KVM_FLAGS=""

FORWARD_PORTS="22 $FORWARD_PORTS"


for i in $FORWARD_PORTS;
do
    EXTRA_FWD="$EXTRA_FWD,hostfwd=tcp::$i-:$i"
done


if ! killall -0 qemu-system-x86_64 &>/dev/null;
then
    echo "[QEMU] Booting guest"
    qemu-system-x86_64 \
        $QEMU_KVM_FLAGS \
        -drive file=/opt/disk.img,if=virtio \
        -drive file=/cdrom.iso,media=cdrom \
        -net user"$EXTRA_FWD" \
        -net nic,model=rtl8139 -m "$QEMU_RAM_LIMIT" \
        -daemonize -display none
    echo "[QEMU] Waiting for connection"
    # Timeout added just in case when ssh connection could hang..
    until timeout 30 sshpass ssh -o StrictHostKeyChecking=no user@127.0.0.1 -p22 echo ok &>/dev/null
    do
        sleep 1
    done
fi
if [[ "x$@" == "x" ]];
then
    sshpass ssh -o StrictHostKeyChecking=no user@127.0.0.1 -p22
    EXITCODE=$?
else
    sshpass ssh -o StrictHostKeyChecking=no user@127.0.0.1 -p22 powershell -command "$@"
    EXITCODE=$?
fi

exit_script
