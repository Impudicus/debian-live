# debian-live

## About
Debian Trixie Live Build, with a minimal gnome desktop environment and ClamAV installed. It's designed to be used as a stand alone, portable antivirus solution that can be booted from any USB drive or CD/DVD.

**Key Features:**
- Based on Debian Trixie
- Minimal Gnome desktop environment with only the necessary applications installed
- ClamAV antivirus software pre-installed and configured
- ClamAV Signatures included (build time) and manually updatable after build
- Can be booted from any USB drive or CD/DVD
- Boots entirely in RAM: leaving no trace on the host system, fast and efficient performance, free up usb slot
- All network interfaces are disabled by default (`modprobe`), preventing any data leaks
- Simple installation and build process, using `live-build` with cutom hooks and configuration

> [!IMPORTANT]
> If you have issues, questions or suggestions, please search through the documentation before opening an issue.
> The issue tracker is for issues, not for personal support. Make sure the version of the documentation matches the image version you're using!

## Getting Started

1. Clone the repository and navigate to the project directory
    ```bash
    git clone https://github.com/Impudicus/debian-live.git

    cd debian-live
    ```
2. Run the install-script to set up all necessary dependencies. This includes `live-build`, `apt-cacher-ng` and `qemu`.
    ```bash
    sudo ./install.sh
    ```
3. Run the build-script to create and build the live ISO. This will execute the `live-build` commands, apply custom hooks and configuration, include the specified packages and generate the final ISO image.
    ```bash
    sudo ./build.sh
    ```
4. Deploy the generated ISO to a USB drive or CD/DVD. You can use tools like `dd` for USB drives or any CD/DVD burning software for optical media.
    ```bash
    # Example using dd to write the ISO to a USB drive (replace /dev/sdX with your USB drive)
    sudo dd if=debian-live.iso of=/dev/sdX bs=4M status=progress && sync
    ```

**Optional:**
The install script also sets up `qemu` for testing the generated ISO in a virtual environment. Just run the following command to boot the ISO:
```bash
qemu-system-x86_64 -m 4096 -boot d -enable-kvm -vga virtio -cdrom live-build-YYYYMMDD-HHMMSS.iso
```

> [!TIP]
> The default username and password for the live environment are `debian` and `live`, respectively. You can change this in the `config/hooks/` directory by modifying the appropriate hook scripts before running the build script.

## Workflow
After booting into the live environment, you can use the pre-installed ClamAV to scan for viruses and malware. The antivirus signatures included in the build are up to date as of the build time, but you can also update them manually.

### Signature Updates
1. Download latest signatures on a separate, secure machine with internet access. 
    ```bash
    # You can use the following links to download the latest ClamAV signatures:

    wget https://packages.microsoft.com/clamav/bytecode.cvd
    wget https://packages.microsoft.com/clamav/daily.cvd
    wget https://packages.microsoft.com/clamav/main.cvd
    ```
2. Transfer signatures to a validated USB drive
3. Boot into the live environment
4. Mount the validated USB drive containing the signatures
5. Copy the signatures to /var/lib/clamav/ (a shortcut is provided in the nautilus file manager)
6. Unplug the validated USB drive
7. Open ClamAV, navigate to the "Update" tab and click "Update Signatures"

> [!TIP]
> Alternatively, rebuild the ISO to produce a fresh image with up-to-date databases bundled in. This is a more secure option, as it ensures that the signatures are included in the build process and reduces the risk of tampering during transfer.

### USB Sanitization
1. Boot into the live environment
2. Insert the USB drive you want to sanitize
3. Open ClamAV and scan its contents for viruses and malware.
4. Copy desired files to a temporary location (e.g. the desktop)
5. Unplug the USB drive
6. Insert a validated USB drive and copy the sanitized files to it
7. Unplug the validated USB drive and use it on your regular system
8. Reboot the live environment to restore a sanitized state for the next use

## Contributing

Contributions are welcome. Please open an issue before submitting a pull request for non-trivial changes. Ensure any modifications to `config/` are tested with a full `lb build` run before submission.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
