FROM vapor/runtime/php-74:latest as base

SHELL ["/bin/bash", "-c"]

ENV IMAGICK_BUILD_DIR="/tmp/build/imagick"
ENV INSTALL_DIR="/opt/vapor"

ENV PKG_CONFIG_PATH="${INSTALL_DIR}/lib64/pkgconfig:${INSTALL_DIR}/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig" \
    PKG_CONFIG="/usr/bin/pkg-config" \
    PATH="${INSTALL_DIR}/bin:${PATH}"

ENV LD_LIBRARY_PATH="${INSTALL_DIR}/lib64:${INSTALL_DIR}/lib"

RUN echo ${PATH}

RUN mkdir -p ${IMAGICK_BUILD_DIR}
RUN LD_LIBRARY_PATH= yum -y install libwebp-devel wget

# Compile libde265 (libheif dependency)
WORKDIR ${IMAGICK_BUILD_DIR}
RUN wget https://github.com/strukturag/libde265/releases/download/v1.0.5/libde265-1.0.5.tar.gz -O libde265.tar.gz
RUN tar xzf libde265.tar.gz
WORKDIR ${IMAGICK_BUILD_DIR}/libde265-1.0.5
RUN ./configure --prefix ${INSTALL_DIR} --exec-prefix ${INSTALL_DIR}
RUN make -j $(nproc)
RUN make install

# Compile libheif
WORKDIR ${IMAGICK_BUILD_DIR}
RUN wget https://github.com/strukturag/libheif/releases/download/v1.6.2/libheif-1.6.2.tar.gz -O libheif.tar.gz
RUN tar xzf libheif.tar.gz
WORKDIR ${IMAGICK_BUILD_DIR}/libheif-1.6.2
RUN ./configure --prefix ${INSTALL_DIR} --exec-prefix ${INSTALL_DIR}
RUN make -j $(nproc)
RUN make install

# Compile the ImageMagick library
WORKDIR ${IMAGICK_BUILD_DIR}
RUN wget https://github.com/ImageMagick/ImageMagick6/archive/6.9.11-7.tar.gz -O ImageMagick.tar.gz
RUN tar xzf ImageMagick.tar.gz
WORKDIR ${IMAGICK_BUILD_DIR}/ImageMagick6-6.9.11-7
RUN ./configure --prefix ${INSTALL_DIR} --exec-prefix ${INSTALL_DIR} --with-webp --with-heic --disable-static
RUN make -j $(nproc)
RUN make install

# Compile the php imagick extension
WORKDIR ${IMAGICK_BUILD_DIR}
RUN pecl download imagick
RUN tar xzf imagick-3.4.4.tgz
WORKDIR ${IMAGICK_BUILD_DIR}/imagick-3.4.4
RUN phpize
RUN ./configure --with-imagick=${INSTALL_DIR}
RUN make -j $(nproc)
RUN make install
RUN cp `php-config --extension-dir`/imagick.so /tmp/imagick.so

# Copy Everything To The Base Container

FROM amazonlinux:2018.03

ENV INSTALL_DIR="/opt/vapor"
ENV DESTINATION_DIR="/opt"

RUN mkdir -p ${DESTINATION_DIR}/lib \
    ${DESTINATION_DIR}/bin

WORKDIR /opt

COPY --from=base ${INSTALL_DIR}/lib/libMagickWand-6.Q16.so.6.0.0  ${DESTINATION_DIR}/lib/libMagickWand-6.Q16.so.6
COPY --from=base ${INSTALL_DIR}/lib/libMagickCore-6.Q16.so.6.0.0 ${DESTINATION_DIR}/lib/libMagickCore-6.Q16.so.6

COPY --from=base /usr/lib64/libwebp.so.4.0.2 ${DESTINATION_DIR}/lib/libwebp.so.4
COPY --from=base ${INSTALL_DIR}/lib/libde265.so.0.0.12 ${DESTINATION_DIR}/lib/libde265.so.0
COPY --from=base ${INSTALL_DIR}/lib/libheif.so.1.6.2 ${DESTINATION_DIR}/lib/libheif.so.1

COPY --from=base /tmp/imagick.so ${DESTINATION_DIR}/bin/imagick.so

RUN LD_LIBRARY_PATH= yum -y install zip

CMD echo "zip --quiet --recurse-paths /export/imagick.zip  ${DESTINATION_DIR}"
