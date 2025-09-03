# Use a standard Ubuntu LTS base image for a non-GPU machine.
# This image is lighter and more general-purpose than the CUDA image.
FROM nvcr.io/nvidia/tensorrt:23.08-py3

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV NO_AT_BRIDGE=1
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV LD_LIBRARY_PATH=${JAVA_HOME}/jre/lib/amd64/server
# Set build flags for any source compilations
ENV CFLAGS="-O2"
ENV CPPFLAGS="-O2"

# === Install system dependencies in one efficient layer ===
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa && apt-get update \
    && apt-get install -y --no-install-recommends \
    python3.8 \
    python3.8-dev \
    python3.8-venv \
    python3-distutils \
    python3-pip \
    locales \
    dbus-x11 \
    x11-utils \
    libgtk-3-dev \
    libnotify-dev \
    libsdl2-dev \
    libwebkit2gtk-4.0-dev \
    openjdk-8-jdk-headless \
    default-libmysqlclient-dev \
    libopenblas-dev \
    liblapack-dev \
    libblas-dev \
    gfortran \
    pkg-config \
    # Clean up apt cache to keep the image size small
    && rm -rf /var/lib/apt/lists/*

# Configure UTF-8 locale
RUN locale-gen en_US.UTF-8

# Upgrade pip and setuptools
RUN python3.8 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# === Install build dependencies to pin versions ===
RUN python3.8 -m pip install --no-cache-dir \
    "Cython==0.29.36" \
    "numpy==1.24.4"

# === Install application dependencies including the CPU version of TensorFlow ===
RUN python3.8 -m pip install --no-cache-dir \
    --no-build-isolation \
    "scipy" \
    "matplotlib" \
    "Pillow" \
    "h5py" \
    "JPype1" \
    "pyimagej" \
    "stardist" \
    "Imageio" \
    "omnipose" \
    "tensorflow" \
    "cellpose-omni" \
    "Scikit-image" \
    "wxPython==4.1.1" \
    "centrosome==1.2.1" \
    "prokaryote==2.4.4" \
    "inflect==5.6.2" \
    "docutils==0.18.1" \
    "javabridge==1.0.19" \
    "python-bioformats==4.0.7" \
    "mahotas==1.4.12" \
    "cellpose>=1.0.2"

# === Clone and install CellProfiler and its plugins ===
RUN git clone https://github.com/CellProfiler/CellProfiler.git /usr/local/src/CellProfiler
WORKDIR /usr/local/src/CellProfiler
RUN git checkout tags/v4.2.5
# Install CellProfiler (it will use the already-installed dependencies)
RUN python3.8 -m pip install --no-cache-dir .

# Clone and install CellProfiler-plugins
RUN git clone https://github.com/CellProfiler/CellProfiler-plugins.git /usr/local/src/CellProfiler-plugins
WORKDIR /usr/local/src/CellProfiler-plugins
# Install plugins in editable mode with 'all' extras
RUN python3.8 -m pip install --no-cache-dir -e '.[all]'

# Set default workdir and entrypoint
WORKDIR /usr/local/src/CellProfiler
ENTRYPOINT ["cellprofiler", "--plugins-directory", "/usr/local/src/CellProfiler-plugins/active_plugins"]
CMD ["--run"]
