systemctl stop docker
umount /var/lib/docker
apt install -y nvidia-container-toolkit
systemctl restart docker.service
systemctl stop docker
cd /var/lib/docker
rm -Rf *
mount -o loop /home/ubuntu/disco-diffusion/docker.img /var/lib/docker   
systemctl start docker
docker images
