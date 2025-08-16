# Strecs3D-Linux
Unofficial build and release of  tomohiron907 / Strecs3D for Linux

Strecs3D is a preprocessing software that generates optimized infill for 3D printing based on structural analysis results.  
It automatically sets dense infill for areas under stress and sparse infill for areas without stress, achieving both material savings and strength optimization.


## Usage

**Using [`distrobox`](https://distrobox.it/) is recommended for easy desktop integration.**  
(Directly using `podman`, `docker` or other engines could work as well, but requires more configuration.)

### One-time usage

```bash
distrobox ephemeral --image ghcr.io/erovia/strecs3d-linux:latest -- Strecs3D
```

This command will create a new container and run Strecs3D.  
Once the application is closed, the container is terminated and cleaned up.


### Desktop integration for long-term usage

```bash
# Create the container
distrobox create --image ghcr.io/erovia/strecs3d-linux:latest --name strecs3d-linux
# Enter the container
distrobox enter strecs3d-linux

# Export Strecs3D to the host (this needs to be executed *inside* the container)
distrobox-export --app Strecs3D
```

These commands will create a new container called `strecs3d-linux` and create a new desktop entry on the host that will show up next to the other installed applications.  
Launching Strecs3D this way does not require opening the terminal or starting the container as `distrobox` will take care of that automatically.


### Clean-up

```bash
# Remove the container (and desktop entry if created)
distrobox rm -f strecs3d-linux
```

Use the appropriate engine, such as `podman` or `docker` to remove the image.

```bash
# Remove the image
podman rmi ghcr.io/erovia/strecs3d-linux:latest
```


## Building

As this is a long process with **a lot** of sources downloaded and compiled, I recommended having at least **32GB of RAM and 120GB of storage**.  
Less might work, but it's best not to risk an OOM and filling up rootfs.  

Any container engine or builder that can do multi-stage builds should work, here is `podman` for example:  
```bash
git clone https://github.com/Erovia/Strecs3D-Linux.git
cd Strecs3D-Linux
podman build -t strecs3d:dev .
```


## Known issues

- Text rendering issues (black on black):  
  I suspect this might have something to do with the fact that `vcpgk` compiles `vtk[qt]` without Wayland support, but I've also seen this [reported on an official release that was running on a non-Linux platform](https://www.reddit.com/r/3Dprinting/comments/1mls4lq/comment/n7tiush/)
 as well, so idk.


## Todo

- [] Arm64 support: Largely depends on the dependency (and as such the vcpkg) situation. Looked into it a bit, but no image built yet.
- [] Automated build with Github Actions: Attempts already done on the `gh_actions` branch, but this is a large and long-running build that seems to be really pushing the limitations of the free, hosted builders.
- [] Using Flatpak instead: I don't have the time or know-how to tackle this at the moment.
