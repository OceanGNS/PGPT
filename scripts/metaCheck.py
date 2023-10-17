import yaml
import sys
import os
from cerberus import Validator


metaFile = sys.argv[1]
with open(metaFile, 'r') as f:
    metaData = yaml.load(f, Loader=yaml.BaseLoader)

scriptsDir = os.path.dirname(os.path.realpath(__file__))
schema = eval(open('%s/schema.json' % scriptsDir, 'r').read())

v = Validator(schema)
v.allow_unknown = True
if(v.validate(metaData, schema)):
    print("%s is valid." % metaFile)
else:
    print("%s is NOT valid!" % metaFile)
    print(v.errors)
    exit(1)
