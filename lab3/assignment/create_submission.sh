#!/bin/bash
rm -f ece3058_cachelab_submission.tar.gz
tar -czvf ece3058_cachelab_submission.tar.gz cachesim.c cachesim.h lrustack.c lrustack.h
echo "Done!"
echo "The files that will be submitted are:"
tar -ztvf ece3058_cachelab_submission.tar.gz