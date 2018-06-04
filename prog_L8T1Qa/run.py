#!/usr/env python

# Argv[1] = L8 Band x
# Argv[2] = L8 Qa Band
# Argv[3] = L8 corrected Output Band x

import sys
import subprocess
err=subprocess.call(['./l8t1qa',sys.argv[1],sys.argv[2],sys.argv[3]])
print err
