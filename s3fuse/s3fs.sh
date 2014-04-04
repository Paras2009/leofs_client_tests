#!/bin/bash

s3cmd mb s3://test
s3fuse -o allow_other /mnt/s3fuse &&\
echo "Bucket Mounted Successfully" && \
cp -p ../temp_data/testFile /mnt/s3fuse && \
echo "File Uploaded Successfully" && \
ls -l /mnt/s3fuse && \
cp  -p /mnt/s3fuse/testFile testFile.copy && \
echo "File Downloaded Sucessfully" && \
diff ../temp_data/testFile testFile.copy && rm testFile.copy && \
cp /mnt/s3fuse/testFile /mnt/s3fuse/testFile.copy && \
echo "File coppied Successfully" && \
ls -l /mnt/s3fuse && \
mv /mnt/s3fuse/testFile.copy /mnt/s3fuse/testFile.org && \
echo "File Move or Rename Successfully" &&\
ls -l /mnt/s3fuse && \
rm -f /mnt/s3fuse/testFile /mnt/s3fuse/testFile.org && \
echo "File Deleted Successfully" &&\
ls /mnt/s3fuse
/usr/bin/fusermount -u  /mnt/s3fuse
s3cmd rb s3://test

