FROM julia:1.4

RUN apt-get update && apt-get install -y xz-utils bzip2 sudo git unzip

RUN julia -e 'using Pkg; Pkg.add("BinaryBuilder")'

RUN julia -e 'using Pkg; Pkg.API.precompile()'
