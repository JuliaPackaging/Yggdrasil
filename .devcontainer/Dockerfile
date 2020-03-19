FROM julia:1.3

RUN apt-get update && apt-get install -y xz-utils bzip2 sudo git unzip

RUN julia -e 'using Pkg; pkg"add BinaryBuilder#master"'
RUN julia -e 'using Pkg; Pkg.API.precompile()'
