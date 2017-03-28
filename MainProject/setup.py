
# build .pyx files?
from distutils.core import setup, Extension
from Cython.Build import cythonize

import os
from os.path import join

import numpy


from sklearn._build_utils import get_blas_info
cblas_libs, blas_info = get_blas_info()

#
# setup(
#   name = 'k_means_elkan',
#   ext_modules = cythonize("_k_means_elkan.pyx"),
# )

# setup(
#     name = '_k_means_elkan',
#     ext_modules=[ cythonize("_k_means_elkan.pyx"),
#         Extension("_k_means_elkan", ["_k_means_elkan.c"],
#                   include_dirs=[numpy.get_include()]),
#     ],
# )


# setup(
#     name = '_k_means_elkan',
#     ext_modules=[
#         Extension("_k_means_elkan", ["_k_means_elkan.c"],
#                   include_dirs=[numpy.get_include()]),
#     ],
# )

# setup(
#     name = '_k_means',
#     ext_modules=[ cythonize("_k_means.pyx"),
#         Extension("_k_means", ["_k_means.c"])
#     ]
# )

setup(
    name= '_k_means',
    ext_modules = cythonize(
      [
        Extension(
          "_k_means", ["_k_means.c"],
          include_dirs=[
            join('..', 'src', 'cblas'),
            numpy.get_include(),
            blas_info.pop('include_dirs', [])
          ],
          extra_compile_args=blas_info.pop(
            'extra_compile_args', []
          ),
          **blas_info
        )
      ]
    )
)

# ext_modules=cythonize([
#              Extension('*', ['project/core/lib/*.pyx']),
#              Extension('*', ['project/core/*.pyx'])
#         ])
# setup(
#     name = '_k_means',
#     ext_modules=
#     [
#         Extension("_k_means", ["_k_means.c"],
#                   include_dirs=[join('..', 'src', 'cblas'),
#                                        numpy.get_include(),
#                                        blas_info.pop('include_dirs', [])],
#                   extra_compile_args=blas_info.pop(
#                              'extra_compile_args', []),
#                          **blas_info),
#     ],
# )


# setup(
#     name = '_k_means',
#     ext_modules=[ cythonize("_k_means.pyx"),
#         Extension("_k_means", ["_k_means.c"],
#                   include_dirs=[numpy.get_include(), get_blas_info()]),
#     ],
# )