#!/bin/bash

s3cmd mb s3://test
sudo -u jenkins s3fuse -o allow_other /mnt/s3fuse &&\
echo "Bucket Mounted Successfully" && \
cp -p ../temp_data/README /mnt/s3fuse && \
echo "File Uploaded to LeoFS" && \
ls -l /mnt/s3fuse && \
cp  -p /mnt/s3fuse/README README.copy && \
echo "File Downloaded Sucessfully" && \
diff ../temp_data/README README.copy && rm README.copy && \
cp /mnt/s3fuse/README /mnt/s3fuse/README.copy && \
echo "File coppied Successfully" && \
ls -l /mnt/s3fuse && \
mv /mnt/s3fuse/README.copy /mnt/s3fuse/README.org && \
echo "File Move or Rename Successfully" &&\
ls -l /mnt/s3fuse && \
rm -f /mnt/s3fuse/README /mnt/s3fuse/README.org && \
echo "File Deleted Successfully" &&\
ls /mnt/s3fuse && \
umount  /mnt/s3fuse
s3cmd rb s3://test
