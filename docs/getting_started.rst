Getting Started
###############

What is NSTD
************

NSTD stands for Non-Standard. This means that the set of projects diverges from
the traditional Ada runtime by adopting modern design principles, naming
conventions, and performance optimizations inspired by languages like Go,
Python, and Rust.

Installation
************

Each project is located in a dedicated subdirectory whose name is the basename
of the project file. For example, the core functionalities are located in the
``nstd`` subfolder. The project name is :file:`nstd.gpr`.

Each project also provides a dedicated Python script :file:`PROJECT.gpr.py` that
can be used to automatically configure project settings, such as build options.
To use the script for configuration, run it with Python. Note that the script
does not have any other dependencies aside from a Python >= 3.9 interpreter.

The simplest way to install a given project is to run the dedicated Python
script in the location of your choice. For example to build the core project
nstd.gpr::

    $ mkdir MY_BUILD_DIR
    $ cd MY_BUILD_DIR
    $ SRC_DIR/nstd/nstd.gpr.py build --install --prefix=INSTALL_DIR

Then to use it, just add to your GPR_PROJECT_PATH environment variable
:file:`INSTALL_DIR/share/gpr` directory.
