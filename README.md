# Disco Diffusion and Lambda Labs

The purpose of this documentation is to lay out the quickest steps to get Disco Diffusion running using Lambda Labs.

Dockerfile that is used can be found here: https://github.com/entmike/disco-diffusion-1/tree/main/docker

## Pre-requisites

  - A Lambda Labs account
  - Money

## Set up an SSH key

  Before creating a Lambda Labs GPU Instance, you will need to create an SSH key.  This is your private key that you will assign later to a GPU Instance.

  1. Visit the [Lambda Labs SSH keys](https://lambdalabs.com/cloud/ssh-keys) page.
  2. Click **Add SSH key**
  3. In the pop-up window, click **Generate a new SSH key** at the bottom.
  4. Provide a title for the key, and click **Create**.
  5. A file download dialog box will appear.  Save the `.pem` file somewhere safe on your computer.

## Create a Storage Filesystem

  A storage filesystem will allow you to attach it to your GPU instance, thus saving your DD renders in a permanent place.

  1. Visit the [Lambda Labs Filesystems](https://lambdalabs.com/cloud/filesystems) page.
  2. Click **Create filesystem**
  3. Provide a filesystem name of `disco-diffusion` and click **Create filesystem**

## Set up a GPU Instance

  The GPU Instance is a VM that will be assigned a GPU to handle your DD workloads.  Note that the "meter is running" once launched, and will continue to run until terminated.

  1. Visit the [Lambda Labs GPU Instances](https://lambdalabs.com/cloud/dashboard/instances) page.
  2. Click **Launch Instance**
  3. Select the **1x A6000 (48 GB)** option.  ($1.45/hr at the time of this writing.)
  4. For SSK key, select the SSH key you created.
  5. For filesystem, select the filesystem you created.
  6. Click **Launch**.
  7. Read the EULA and click **I agree to the above.**

  Once your instance has changed from status **Booting** to **?**, your GPU Instance is ready to use.

## Troubleshooting a GPU Instance

If you believe that your GPU Instance has become non-responsive, you can hard restart it.

  1. Visit the [Lambda Labs GPU Instances](https://lambdalabs.com/cloud/dashboard/instances) page.
  2. Checkmark the instance that you want to terminate, and then click the **Restart** button at the top-right of the page.

## Accessing your GPU Instance

There are a few different ways that you can connect to your instance.  For sake of simplicity, we will cover connecting to the **Cloud IDE**, as it requires no installation and can be accessed solely from a browser.

  1. Visit the [Lambda Labs GPU Instances](https://lambdalabs.com/cloud/dashboard/instances) page.
  2. Click the **Launch (Beta)** link next to your running instance.

This will launch in a new browser tab a Jupyter Notebook instance.  Once loaded, you will be able to run notebooks and Python script as you would on a normal Jupyter notebook.  In the lefthand side of the page, you should see your filesystem folder you created and assigned to your instance.  Make note of it, for sake of these instructions, the filesystem `disco-diffusion` will be used in examples.

## Setting up Docker Container Build containing DD (First Time Setup ONLY)

To quicken the setup time, a Docker image is recommended so that you do not have to battle Python/PIP/CUDA/Tensorflow dependencies.

### Change the Docker persistance location to your filesystem

  This will allow us to save the image we are about to build in persistent filesystem, dramatically speeding up subsequent jobs you may wish to run later.

  1. In the **Cloud IDE** (aka Jupyter), click **Terminal** in the Launcher tab.  This will open a terminal session in your GPU Instance.

  2. First, we need to create a persistent disk for Docker that we can save between reboots:

     ```ssh
     mkdir -p /home/ubuntu/disco-diffusion/init_images
     mkdir -p /home/ubuntu/disco-diffusion/images_out
     sudo bash
     systemctl stop docker
     mkdir -p /home/ubuntu/disco-diffusion/docker
     dd if=/dev/zero of=/home/ubuntu/disco-diffusion/docker.img iflag=fullblock bs=1M count=60000 && \
       sync && \
       sudo mkfs ext3 -F /home/ubuntu/disco-diffusion/docker.img
     mkdir -p /home/ubuntu/disks/docker
     mount -o loop /home/ubuntu/disco-diffusion/docker.img /home/ubuntu/disks/docker
     cd /var/lib/docker && mv * /home/ubuntu/disks/docker && cd -
     rmdir /var/lib/docker
     mkdir /var/lib/docker
     umount disks/docker/
     mount -o loop /home/ubuntu/disco-diffusion/docker.img /var/lib/docker
     systemctl start docker
     exit
     ```

### Clone the Git Repo and build the Docker Image

  1. Let's clone the Git repo that contains the Docker build we need:
     ```ssh
     cd ~/disco-diffusion
     git clone https://github.com/entmike/disco-diffusion-1.git
     cd disco-diffusion-1
     git checkout no-notebook
     cd docker/prep
     sudo docker build -t disco-diffusion-prep:5.1 .
     ```

  2. At this point, the Docker daemon will begin to download several image layers required by the Docker build, and then it will begin to build your prep image which may take up to 30 minutes to complete.  While this is going on, find some coffee or an adult beverage to sip on.  Once the build is complete, continue typing the next commands:
  
     ```ssh
     cd ../main
     sudo docker build -t disco-diffusion:5.1 .
     ```
     This step of the build will take the previous half of your build containing the downloaded model files, and then build the DD environment for you.  This step takes around 15 minutes, depending on internet speeds, etc.

  3. Once this part of the build is completed, the hard part is over.  Barring you completely tanking your `disco-diffusion` filesystem, or pulling a new Docker build spec, you will not have to run these initial steps again.  At this point, you may terminate your GPU instance.

  ## Terminating a GPU Instance

  It is important that you unmount your Docker volume and do a clean shutdown to avoid file corruption for your next Docker launch session.

  1. In the **Cloud IDE** (aka Jupyter), click **Terminal** in the Launcher tab.  Type the following:

     ```ssh
     sudo systemctl stop docker
     sudo umount /var/lib/docker
     sudo cp /home/ubuntu/disco-diffusion/docker.img /home/ubuntu/disco-diffusion/docker-backup.img
     sudo shutdown now
     ```
  1. Visit the [Lambda Labs GPU Instances](https://lambdalabs.com/cloud/dashboard/instances) page.
  2. Checkmark the instance that you want to terminate, and then click the **Terminate** button at the top-right of the page.

  For next steps, please read the [NEXT](NEXT.md) document.  At this point, you may terminate your GPU instance until you are ready to proceed with the next part.
