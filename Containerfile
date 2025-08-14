FROM ubuntu:25.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive

# Lock vcpkg version to avoid breaking changes
ARG VCPKG_VERSION=2025.07.25
# Disable metrics collection
ARG VCPKG_DISABLE_METRICS=1

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    zip \
    unzip \
    tar \
    git \
    cmake \
    make \
    g++ \
    build-essential \
    pkg-config \
    linux-libc-dev \
    python3-jinja2 \
    libtool \
    autoconf \
    automake \
    autoconf-archive \
    bison \
    flex \
    linux-libc-dev \
    ^libxcb.*-dev  \
    libx11-xcb-dev \
    libglu1-mesa-dev \
    libxrender-dev \
    libxi-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libegl1-mesa-dev \
    libxt-dev \
    zlib1g-dev \
    libdouble-conversion-dev \
    libb2-dev \
    libicu-dev \
    libpcre2-dev \
    libzstd-dev \
    libpng-dev \
    libharfbuzz-dev \
    libltdl-dev \
    libxmu-dev \
    libxi-dev \
    libgl-dev \
    libfontconfig-dev \
    libdbus-1-dev \
    libssl-dev \
    libglew-dev \
    libsqlite3-dev \
    libeigen3-dev \
    libjsoncpp-dev \
    libutfcpp-dev \
    libpqxx-dev \
    liblzma-dev \
    libjpeg-dev \
    libtiff-dev \
    libexprtk-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

# Install vcpkg
RUN git clone https://github.com/Microsoft/vcpkg.git && \
    cd vcpkg && \
    git checkout ${VCPKG_VERSION} && \
    ./bootstrap-vcpkg.sh && \
    ln -s $HOME/vcpkg/vcpkg /usr/local/bin/vcpkg

# FIX413: Patch the libmf3 port to successfully build
COPY lib3mf_fix413.patch .
RUN cat lib3mf_fix413.patch >> vcpkg/ports/lib3mf/lib3mf_vcpkg.patch

# Build lib3mf 2.x
RUN vcpkg install lib3mf && \
    rm -rf vcpkg/buildtrees vcpkg/downloads

# Build libzip
RUN vcpkg install libzip && \
    rm -rf vcpkg/buildtrees vcpkg/downloads

# Build VTK with Qt6
RUN vcpkg install vtk[qt] && \
    rm -rf vcpkg/buildtrees vcpkg/downloads

# Add Linux compatibility to the Strecs3D project
COPY strecs3d_linux.patch .

# Set the environment variables for the Strecs3D project
RUN export VCPKG_ROOT=$PWD/vcpkg && \
    export Qt6_DIR=$VCPKG_ROOT/installed/x64-linux/share/Qt6/ && \
    export libzip_DIR=$VCPKG_ROOT/installed/x64-linux/share/libzip/ && \
    export lib3mf_DIR=$VCPKG_ROOT/installed/x64-linux/share/lib3mf && \
    export VTK_DIR=$VCPKG_ROOT/installed/x64-linux/share/vtk/ && \
    export fmt_DIR=$VCPKG_ROOT/installed/x64-linux/share/fmt && \
    export nlohmann_json_DIR=$VCPKG_ROOT/installed/x64-linux/share/nlohmann_json/ && \
    export pugixml_DIR=$VCPKG_ROOT/installed/x64-linux/share/pugixml/ && \
    export LZ4_DIR=$VCPKG_ROOT/installed/x64-linux/share/lz4/ && \
    export FastFloat_DIR=$VCPKG_ROOT/installed/x64-linux/share/FastFloat/ && \
    export Verdict_DIR=$VCPKG_ROOT/installed/x64-linux/share/verdict/ && \

    # Build Strecs3D
    git clone https://github.com/tomohiron907/Strecs3D.git && \
    cd Strecs3D && \
    git apply ../strecs3d_linux.patch && \
    mkdir -p build && \
    cd build && \
    cmake .. && \
    cmake --build . --config Release && \
    strip Strecs3D


FROM ubuntu:25.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libxkbcommon-x11-0 \
    libxcb-cursor0 \
    libxcb-icccm4 \
    libxcb-keysyms1 \
    libxcb-shape0 \
    libsm6 \
    libxcb-xinput0 \
    libgl1 \
    libdbus-1-3 \
    libegl1 \
    libxrender1 \
    && rm -rf /var/lib/apt/lists/*

# Copy lib3mf 2.x from vcpkg
COPY --from=builder /root/vcpkg/installed/x64-linux/lib/lib3mf.so.2.4.1.0 /usr/lib/lib3mf.so.2.4.1.0
RUN ldconfig -v

# Copy the Strecs3D icon
COPY --from=builder /root/Strecs3D/resources/black_logo.png /usr/share/icons/hicolor/512x512/apps/Strecs3D.png

# Create the Strecs3D desktop entry
RUN mkdir -p /usr/share/applications && \
    echo "[Desktop Entry]\n\
Name=Strecs3D\n\
Exec=/usr/local/bin/Strecs3D\n\
Icon=Strecs3D\n\
Type=Application" > /usr/share/applications/Strecs3D.desktop

# Set the locale to UTF-8
ENV LANG=C.UTF-8
# As vcpgk builds vtk[qt] without Wayland support, we need to use X11
# Set the Qt platform to X11
ENV QT_QPA_PLATFORM=xcb

# Copy the Strecs3D binary
COPY --from=builder /root/Strecs3D/build/Strecs3D /usr/local/bin/Strecs3D

ENTRYPOINT ["/usr/local/bin/Strecs3D"]
