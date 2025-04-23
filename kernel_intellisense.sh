#!/bin/bash
set -e

#used by config and build
KERNEL_VERSION="6.9.9" # Example kernel version
KERNEL_DIR="linux-$KERNEL_VERSION"

message(){
    echo @######################################################################@
    echo  $1
    echo @######################################################################@
}

install_dependencies(){
    # Update package lists
    sudo apt update
    # Install build dependencies
    sudo apt install -y build-essential libncurses-dev flex bison openssl \
                        libssl-dev dkms libelf-dev libudev-dev libpci-dev \
                        libiberty-dev autoconf bc dwarves bear gcc-arm*   \
                        cpio xz-utils lz4 ccache
    # Beaglebone dependencies
    sudo apt-get install gettext libmpc-dev u-boot-tools lz4
}

download_kernel(){
    # Download kernel source (replace with your desired version)
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz"
    tar -xf "linux-$KERNEL_VERSION.tar.xz"
    rm "linux-$KERNEL_VERSION.tar.xz"
    cd "$KERNEL_DIR" || exit
}

# beaglebone black kernel
download_kernel_beagle(){
    git clone https://git.beagleboard.org/RobertCNelson/ti-linux-kernel-dev linux-beagle
    cd linux-beagle
    git checkout ti-linux-5.10.y
    ./build_deb.sh
}

# Ubuntu packages do not contain ARM toolchain
download_gcc_arm(){
    mkdir -p ~/toolchain
    cd ~/toolchain
    wget "https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz?rev=adb0c0238c934aeeaa12c09609c5e6fc&hash=B119DA50CEFE6EE8E0E98B4ADCA4C55F" -O armgcc.tar.xz
    tar -xvf armgcc.tar.xz
    # add this to your .bashrc
    echo export PATH=\"\$HOME/toolchain/arm-gnu-toolchain-13.2.rel1-x86_64-arm-none-linux-gnueabihf/bin:\$PATH\"
    echo alias armmake=\"make ARCH=arm CROSS_COMPILE='ccache arm-none-linux-gnueabihf-'\"
}

configure_kernel(){
    message "configure the kernel (using defconfig as a starting point)"
    make defconfig
    message "enable debugging configs"
    sleep 1

    ./scripts/config --enable CONFIG_DEBUG_INFO
    ./scripts/config --enable CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
    ./scripts/config --disable CONFIG_DEBUG_INFO_NONE
    ./scripts/config --set-val DEBUG_INFO_REDUCED n
    ./scripts/config --set-val DEBUG_INFO_COMPRESSED_ZLIB 2
    ./scripts/config --set-val DEBUG_INFO_SPLIT y
    ./scripts/config --enable CONFIG_GDB_SCRIPTS
    ./scripts/config --enable CONFIG_FRAME_POINTER
    ./scripts/config --set-val CONFIG_RANDOMIZE_BASE n
    ./scripts/config --enable CONFIG_KGDB
    ./scripts/config --enable CONFIG_KGDB_SERIAL_CONSOLE
    #./scripts/config --enable CONFIG_DEBUG_SLAB
}

build(){
    message "BUILD THE KERNEL"
    time make -j$(nproc)
    message "KERNEL BUILD COMPLETED"
    
    message  "BUILD ALL MODULES"
    time make modules -j$(nproc)
    
    message  "GENERATE COMPILE_COMMANDS.JSON"
    ./scripts/clang-tools/gen_compile_commands.py

    message "BUILD GDB SCRIPTS"
    make scripts_gdb

    echo "Kernel build process completed (or started). compile_commands.json generated."
    echo "Kernel source is located in: $PWD"
}

quemu(){
    qemu-system-x86_64 -s -kernel ./arch/x86_64/boot/bzImage -initrd ../busybox-1.34.1/initramfs.cpio.gz 
}

kgdb(){
    cd $KERNEL_DIR || echo "cannot enter $KERNEL_DIR"
    # enable lx-* functions such as lx-symbols
    gdb -iex "add-auto-load-safe-path $PWD" vmlinux
}

# function to download, configure and build the kernel

