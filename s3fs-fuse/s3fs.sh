#!/bin/bash

s3cmd mb s3://test
/usr/local/s3fs-fuse/bin/s3fs test /mnt/s3fs-fuse -o allow_other,uid=498,gid=498,umask=0022 -o url='http://localhost:8080'
echo "Bucket Mounted Successfully" && \
cp -p ../temp_data/testFile /mnt/s3fs-fuse && \
ls -l /mnt/s3fs-fuse && \
echo "File Uploaded Successfully" && \
cp  -p /mnt/s3fs-fuse/testFile testFile.copy && \
echo "File Downloaded Sucessfully" && \
diff ../temp_data/testFile testFile.copy && rm testFile.copy && \
cp /mnt/s3fs-fuse/testFile /mnt/s3fs-fuse/testFile.copy && \
ls -l /mnt/s3fs-fuse && \
echo "File coppied Successfully" && \
mv /mnt/s3fs-fuse/testFile.copy /mnt/s3fs-fuse/testFile.org && \
ls -l /mnt/s3fs-fuse && \
echo "File Move or Rename Successfully" &&\
rm -f /mnt/s3fs-fuse/testFile /mnt/s3fs-fuse/testFile.org && \
echo "File Deleted Successfully" &&\
ls /mnt/s3fs-fuse
fusermount -u  /mnt/s3fs-fuse
s3cmd rb s3://test

