# Launching your GPU Instance and running a batch

STOP: Make sure you have completed the initial steps outlined [here](README.md) before continuing.

## Set up the GPU Instance

  Like last time, you will need to follow the same steps that you did during your initial build each time you want to run a workload.  Again, note that the "meter is running" once launched, and will continue to run until terminated.

  1. Visit the [Lambda Labs GPU Instances](https://lambdalabs.com/cloud/dashboard/instances) page.
  2. Click **Launch Instance**
  3. Select the **1x A6000 (48 GB)** option.  ($1.45/hr at the time of this writing.)
  4. For SSH key, select the SSH key you created.
  5. For filesystem, select the `disco-diffusion` filesystem you created.
  6. Click **Launch**.
  7. Read the EULA and click **I agree to the above.**


  ### Change the Docker persistance location to your filesystem

  This will allow us to save the image we are about to build in persistent filesystem, dramatically speeding up subsequent jobs you may wish to run later.

  1. In the **Cloud IDE** (aka Jupyter), click **Terminal** in the Launcher tab.  This will open a terminal session in your GPU Instance.

  2. Set up Lambda Stack (10 mins):
     ```
     LAMBDA_REPO=$(mktemp) && \
       wget -O${LAMBDA_REPO} https://lambdalabs.com/static/misc/lambda-stack-repo.deb && \
       sudo dpkg -i ${LAMBDA_REPO} && rm -f ${LAMBDA_REPO} && \
       sudo apt-get update && sudo apt-get install -y lambda-stack-cuda && \
       sudo apt install -y containerd && \
       sudo apt install -y docker.io nvidia-container-toolkit
     ```
  3. Reboot.
     ```
     sudo reboot
     ```
     Wait for about 5 mins and re-enter your **Cloud IDE**.
     
  4. Next, we need to switch back to our persistent disk for Docker that we can save between reboots:

     ```ssh
     sudo bash
     systemctl stop docker
     cd /var/lib/docker
     rm -Rf *
     mount -o loop /home/ubuntu/disco-diffusion/docker.img /var/lib/docker   
     systemctl start docker
     exit
     ```
   
  5. Confirm that your previously built images are still present by typing `sudo docker images`.  You should see something like this:

     ```
     REPOSITORY               TAG         IMAGE ID       CREATED          SIZE
     disco-diffusion          5.1         f2e41f2eb0c8   28 minutes ago   25.1GB
     disco-diffusion-prep     5.1         b325f54b06eb   36 minutes ago   24.7GB
     nvcr.io/nvidia/pytorch   21.08-py3   9f34357dd551   8 months ago     12.7GB
     ```
     
     Run the following test command:

     ```
     sudo docker run --rm -it \
        -v $(echo ~)/disco-diffusion/images_out:/workspace/code/images_out \
        -v $(echo ~)/disco-diffusion/init_images:/workspace/code/init_images \
        --gpus=all \
        --name="disco-diffusion" --ipc=host \
        --user $(id -u):$(id -g) \
        -e text_prompts='{"0":["cybernetic organism, artstation, Art by Beksinski, unreal engine"]}' \
        -e display_rate=20 \
        -e steps=500 \
        disco-diffusion:5.1 python disco-diffusion-1/disco.py
     ```
