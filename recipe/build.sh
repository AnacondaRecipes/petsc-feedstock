#!/bin/bash
set -eu
export PETSC_DIR=$SRC_DIR
export PETSC_ARCH=arch-conda-c-opt

unset CC
unset CXX
if [[ $(uname) == Linux ]]; then
    export LDFLAGS="-pthread $LDFLAGS"
fi

python ./configure \
  CC="mpicc" \
  CXX="mpicxx" \
  FC="mpifort" \
  CFLAGS="$CFLAGS" \
  CPPFLAGS="$CPPFLAGS" \
  CXXFLAGS="$CXXFLAGS" \
  LDFLAGS="$LDFLAGS" \
  --COPTFLAGS=-O3 \
  --CXXOPTFLAGS=-O3 \
  --FOPTFLAGS=-O3 \
  --with-clib-autodetect=0 \
  --with-cxxlib-autodetect=0 \
  --with-fortranlib-autodetect=0 \
  --with-debugging=0 \
  --with-blas-lapack-lib=libopenblas${SHLIB_EXT} \
  --with-hwloc=0 \
  --with-hypre=1 \
  --with-metis=1 \
  --with-mpi=1 \
  --with-mumps=1 \
  --with-parmetis=1 \
  --with-pthread=1 \
  --with-ptscotch=1 \
  --with-ssl=0 \
  --with-scalapack=1 \
  --with-suitesparse=1 \
  --with-x=0 \
  --prefix=$PREFIX

sedinplace() {
  if [[ $(uname) == Darwin ]]; then
    sed -i "" $@
  else
    sed -i"" $@
  fi
}

for path in $PETSC_DIR $PREFIX; do
    sedinplace s%$path%\${PETSC_DIR}%g $PETSC_ARCH/include/petsc*.h
done

make

for f in $(grep -l build_env -R "${PETSC_ARCH}/lib"); do
  echo "fixing build prefix in $f"
  sedinplace s%${BUILD_PREFIX}%${PREFIX}%g $f
done

# FIXME: Workaround mpiexec setting O_NONBLOCK in std{in|out|err}
# See https://github.com/conda-forge/conda-smithy/pull/337
# See https://github.com/pmodels/mpich/pull/2755
make check MPIEXEC="${RECIPE_DIR}/mpiexec.sh"

make install

rm -fr $PREFIX/share/petsc/examples
rm -fr $PREFIX/share/petsc/datafiles
find   $PREFIX/lib/petsc -name '*.pyc' -delete
