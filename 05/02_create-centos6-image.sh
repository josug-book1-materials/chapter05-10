qemu-img create -f qcow2 /tmp/centos6.qcow2 10G
virt-install --virt-type kvm --name centos6 \
--ram 1024 --os-type=linux --os-variant=rhel6 \
--nographics --noautoconsole \
--disk /tmp/centos6.qcow2,format=qcow2 \
--network network=default \
--location=http://ftp.iij.ad.jp/pub/linux/centos/6.5/os/x86_64/ \
--initrd-inject centos6-ks.cfg \
--extra-args="ks=file:/centos6-ks.cfg console=tty0 console=ttyS0,115200n8 serial"
