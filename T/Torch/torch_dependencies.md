# Torch dependencies


Torch/PyTorch has a rather complex set of dependencies, which are to a
large extent unversioned. The present document serves to document these
dependencies, their versions, and their inter-dependencies.

As an example of the complexity, the following shows the dependencies of
Torch v1.11.0:

    "pytorch @ v1.11.0"
    ├─ "XNNPACK @ 79cd5f9e"
    │  ├─ "FP16 @ 0a92994d"
    │  ├─ "FXdiv @ b408327a"
    │  ├─ "pthreadpool @ 545ebe9f"
    │  │  └─ "cpuinfo @ 19b9316c"
    │  └─ "cpuinfo @ d5e37adf"
    ├─ "FP16 @ 0a92994d"
    ├─ "FXdiv @ b408327a"
    ├─ "pthreadpool @ 545ebe9f"
    │  └─ "cpuinfo @ 19b9316c"
    └─ "cpuinfo @ d5e37adf"

Note the different versions of `cpuinfo` referenced by `pytorch`,
`XNNPACK`, *and* `pthreadpool`.

The current Torch version documented is v1.11.0 with versions v1.10.2,
v1.12.1, v1.13.1 serving as context.

## Overview

``` mermaid
graph LR

subgraph pytorch
    pytorch_1_13_1[pytorch v1.13.1]
    pytorch_1_12_1[pytorch v1.12.1]
    pytorch_1_11_0[pytorch v1.11.0]
    pytorch_1_10_2[pytorch v1.10.2]
end

pytorch_1_13_1 --> XNNPACK_ae108ef49aa5623b896fc93d4298c49d1750d9ba
pytorch_1_13_1 --> cpuinfo_d5e37adf1406cf899d7d9ec1d317c47506ccb970
pytorch_1_13_1 --> pthreadpool_545ebe9f225aec6dca49109516fac02e973a3de2

pytorch_1_12_1 --> XNNPACK_ae108ef49aa5623b896fc93d4298c49d1750d9ba
pytorch_1_12_1 --> cpuinfo_d5e37adf1406cf899d7d9ec1d317c47506ccb970
pytorch_1_12_1 --> pthreadpool_545ebe9f225aec6dca49109516fac02e973a3de2

pytorch_1_11_0 --> XNNPACK_79cd5f9e18ad0925ac9a050b00ea5a36230072db
pytorch_1_11_0 --> cpuinfo_d5e37adf1406cf899d7d9ec1d317c47506ccb970
pytorch_1_11_0 --> pthreadpool_545ebe9f225aec6dca49109516fac02e973a3de2

pytorch_1_10_2 --> XNNPACK_79cd5f9e18ad0925ac9a050b00ea5a36230072db
pytorch_1_10_2 --> cpuinfo_d5e37adf1406cf899d7d9ec1d317c47506ccb970
pytorch_1_10_2 --> pthreadpool_545ebe9f225aec6dca49109516fac02e973a3de2

subgraph XNNPACK
    XNNPACK_ae108ef49aa5623b896fc93d4298c49d1750d9ba["google/XNNPACK @ ae108ef4 / 20220216"]
    XNNPACK_79cd5f9e18ad0925ac9a050b00ea5a36230072db["google/XNNPACK @ 79cd5f9e / 20210622"]
end

subgraph cpuinfo
    cpuinfo_19b9316c71e4e45b170a664bf62ddefd7ac9feb5["pytorch/cpuinfo @ 19b9316c / 20200522"]
    cpuinfo_d5e37adf1406cf899d7d9ec1d317c47506ccb970["pytorch/cpuinfo @ d5e37adf / 20190201"]
end

subgraph pthreadpool
    pthreadpool_545ebe9f225aec6dca49109516fac02e973a3de2["Maratyszcza/pthreadpool @ 545ebe9f / 20201206"]
end

XNNPACK_ae108ef49aa5623b896fc93d4298c49d1750d9ba --> pthreadpool_545ebe9f225aec6dca49109516fac02e973a3de2
XNNPACK_ae108ef49aa5623b896fc93d4298c49d1750d9ba --> cpuinfo_d5e37adf1406cf899d7d9ec1d317c47506ccb970
XNNPACK_79cd5f9e18ad0925ac9a050b00ea5a36230072db --> pthreadpool_545ebe9f225aec6dca49109516fac02e973a3de2
XNNPACK_79cd5f9e18ad0925ac9a050b00ea5a36230072db --> cpuinfo_d5e37adf1406cf899d7d9ec1d317c47506ccb970


pthreadpool_545ebe9f225aec6dca49109516fac02e973a3de2 --> cpuinfo_19b9316c71e4e45b170a664bf62ddefd7ac9feb5

```
