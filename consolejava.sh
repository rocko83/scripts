#!/bin/bash
ls -1tr /home/damato/Downloads/*.jnlp | tail -n 1 | xargs -i /home/damato/java/bin/javaws {}
