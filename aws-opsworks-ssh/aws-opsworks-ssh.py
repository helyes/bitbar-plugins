#!/usr/bin/env python
# -*- coding: utf-8 -*-

# <bitbar.title>Opsworks ec2 wizard</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Andras Helyes</bitbar.author>
# <bitbar.author.github>helyes</bitbar.author.github>
# <bitbar.desc>Shows running opsworks instances and let ssh to it</bitbar.desc>
# <bitbar.image>https://github.com/helyes/bitbar-plugins/raw/master/aws-opsworks-ssh/bitbar-image-aws-opsworks-ssh.py.png</bitbar.image>
# <bitbar.dependencies>python, aws-cli</bitbar.dependencies>
# <bitbar.abouturl>https://github.com/helyes/bitbar-plugins/blob/master/aws-opsworks-ssh/aws-opsworks-ssh.py</bitbar.abouturl>

import json
import re
import subprocess
import ConfigParser

# requires mocked json response. Check describestackTestMode.mockFile
TEST_MODE=True

AWS_CLI_PROFILE='default'
AWS_REGION='us-east-1'

# show instances only. All conditions must match
INCLUDE_FILTERS=[ {'Hostname': '^rails-.*|^delayed-.*'}, {'Status': '^.*'}]

#EXCLUDE_FILTERS=[ {'Status': '^stopped'} ]
EXCLUDE_FILTERS=[ ]

AWS_STACK_IDS=[ {'Production': '25890516-aad3-4ee7-8697-573e89a1d98b'}, 
                {'Staging': 'e14492e0-b704-4b29-905e-df4af7e42ec8'}, 
                {'Development': 'df8e5d9f-b068-45a5-8664-96b9cf4fc068'}
               ]

#INSTANCE_COMMANDS=[ { 'SSH' : "ssh -oStrictHostKeyChecking=no -i /Users/andras/.ssh/aws-shiftcare.pem -t andrasshiftcarecom@##{PublicIp}## 'cd /srv/www/shiftcare/current; sudo su; bash -l'"},
INSTANCE_COMMANDS=[ { 'SSH' : "ssh -oStrictHostKeyChecking=no -i $(ctae.sh -g CONFIG_PRIVATE_KEY_FILE) $(ctae.sh -g CONFIG_EC2_USER_NAME)@##{PublicIp}##"},
                    { 'DB:5433' : 'ssh -L 5433:$(ctae.sh -g shiftcare_rds_host):5432 -i $(ctae.sh -g CONFIG_PRIVATE_KEY_FILE) $(ctae.sh -g CONFIG_EC2_USER_NAME)@##{PublicIp}##'}
                  ]

def describestackTestMode(stack_id):
  mockFile="/tmp/describedstack-" + stack_id + ".json"
  f=open(mockFile, "r")
  contents =f.read()
  f.close()
  return contents

def describestackAws(stack_id):
  bashCommand = "aws --profile " + AWS_CLI_PROFILE + " opsworks --region " + AWS_REGION + " describe-instances --stack-id " + stack_id
  process = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
  output, error = process.communicate()
  return output

def describestack(stack_id):
  if TEST_MODE:
    return json.loads(describestackTestMode(stack_id))["Instances"]
  else:
    return json.loads(describestackAws(stack_id))["Instances"]

def normalizeCommand(command, instanceDescription):
  ret = command
  pattern = '##{(.*?)}##'
  for match in re.finditer(pattern, command):
     key = match.group(1)
     if key in instanceDescription:
      ret = ret.replace("##{" + key + "}##", instanceDescription[key])
     else:
      return "N/A"
  return ret


def isInstancePlaying (instanceDescription):
  
  # check includes - returns false if key is missing or does not match
  for filter in INCLUDE_FILTERS:
    if not filter.keys()[0] in instanceDescription or not re.search(filter.values()[0], instanceDescription[filter.keys()[0]]):
      return False
  
  # check excludes - return false if key exists and matches
  for filter in EXCLUDE_FILTERS:
    if filter.keys()[0] in instanceDescription and re.search(filter.values()[0], instanceDescription[filter.keys()[0]]):
      return False

  return True
  

menu = []
def buildMenu(stackName, stackId):
  stackDescription = describestack(stackId)
  menuStack = []
  for instance in stackDescription:
    if isInstancePlaying(instance):
      menuStack.append(instance)

  menuStack = sorted(menuStack, key=lambda k: k['Hostname'])     
  menu.append({stackName: menuStack})

for stackId in AWS_STACK_IDS:
  buildMenu(stackId.keys()[0], stackId.values()[0])

# static menu
print "OPS"
print "---"
if TEST_MODE:
  print ('Testmode')

# menu
for elements in menu:
  print elements.keys()[0]
  for inst in elements[elements.keys()[0]]:
    #color='green' if inst['Status'] == 'online' else 'red'
    print "--" + inst['Hostname'] + " | color=" + ('green' if inst['Status'] == 'online' else 'red')
    for instanceCommand in INSTANCE_COMMANDS:
      normalizedCommand = normalizeCommand(instanceCommand.values()[0], inst)
      if normalizedCommand != "N/A":
        print '----' + instanceCommand.keys()[0] + ' | bash="' + normalizedCommand + '" terminal=true' 
      else:
        print '----' + instanceCommand.keys()[0] 

print "Refresh | terminal=false refresh=true"
