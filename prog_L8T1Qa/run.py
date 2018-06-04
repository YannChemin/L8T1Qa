#!/usr/env python

import sys
import subprocess
err=subprocess.call(['./l8t1qa',sys.argv[1],sys.argv[2],sys.argv[3]])
print err
