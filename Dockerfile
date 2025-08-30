FROM ubuntu:20.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install build tools and dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    python3.8 \
    python3.8-dev \
    python3-pip \
    libgtk-3-dev \
    libnotify-dev \
    libsdl2-dev \
    libwebkit2gtk-4.0-dev \
    openjdk-11-jdk-headless \
    default-libmysqlclient-dev \
    libopenblas-dev \
    liblapack-dev \
    libblas-dev \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME and LD_LIBRARY_PATH so python-javabridge builds correctly
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV LD_LIBRARY_PATH=${JAVA_HOME}/lib/server

# Upgrade pip
RUN python3.8 -m pip install --upgrade pip

# Install versions compatible with CellProfiler build
RUN python3.8 -m pip install "numpy<1.23" "Cython==0.29.32" "setuptools<70"


# Clone CellProfiler
RUN git clone https://github.com/CellProfiler/CellProfiler.git /usr/local/src/CellProfiler
WORKDIR /usr/local/src/CellProfiler
RUN git checkout tags/v4.2.5

# Install CellProfiler with preinstalled deps
RUN pip3 install --no-build-isolation --editable .

# Clone CellProfiler-plugins
RUN git clone https://github.com/CellProfiler/CellProfiler-plugins.git /usr/local/src/CellProfiler-plugins
WORKDIR /usr/local/src/CellProfiler-plugins

# Remove setup.py to avoid conflicts
RUN rm -f setup.py

# Set plugin directory
ENV CELLPOROFILER_PLUGINS_DIR=/usr/local/src/CellProfiler-plugins/active_plugins

# Optionally install plugin deps
RUN pip3 install -e '.[runcellpose]' || true

# Back to CellProfiler
WORKDIR /usr/local/src/CellProfiler

# Entrypoint
ENTRYPOINT ["cellprofiler"]
CMD ["--run", "--run-headless", "--help"]
