#!/bin/bash


which s3cmd && \
    s3cmd mb s3://test && \
    echo "Bucket Created Successfully" && \
    s3cmd put ../temp_data/testFile s3://test/testFile && \
    echo "File Uploaded to LeoFS"
    s3cmd ls s3://test && \
    s3cmd get s3://test/testFile testFile.copy && \
    echo "File Downloaded Sucessfully" && \
    diff ../temp_data/testFile testFile.copy && rm testFile.copy && \
    s3cmd cp s3://test/testFile s3://test/testFile.copy && \
    echo "File coppied Successfully" && \
    s3cmd mv s3://test/testFile.copy s3://test/testFile.org && \
    echo "File Move or Rename Successfully" &&\
    s3cmd del s3://test/testFile s3://test/testFile.org && \
    echo "File Deleted Successfully" &&\
    s3cmd ls s3://test && \
    s3cmd rb s3://test 
