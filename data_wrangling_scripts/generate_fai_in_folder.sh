#!/bin/bash

for FILE in *; do samtools faidx $FILE; done
