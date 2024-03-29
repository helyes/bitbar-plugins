#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# <bitbar.title>Opsworks ec2 wizard</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Andras Helyes</bitbar.author>
# <bitbar.author.github>helyes</bitbar.author.github>
# <bitbar.desc>Shows running opsworks instances and let ssh to it</bitbar.desc>
# <bitbar.image>https://github.com/helyes/bitbar-plugins/raw/master/aws-opsworks-ssh/bitbar-image-aws-opsworks-ssh.py.png</bitbar.image>
# <bitbar.dependencies>python, aws-cli</bitbar.dependencies>
# <bitbar.abouturl>https://github.com/helyes/bitbar-plugins/blob/master/aws-opsworks-ssh/aws-opsworks-ssh.py</bitbar.abouturl>
# ./aws-opsworks-ssh/aws-opsworks-ssh.py

import datetime
import json
import os
import re
import subprocess
import sys

CONFIG_FILE="/Users/andras/work/helyes/bitbar-plugins/aws-opsworks-ssh/.secrets.json"

def loadConfig():
  try:
    with open(CONFIG_FILE, 'r') as f:
      content =f.read()
      return json.loads(content)
  except IOError:
      print ('Error')
      print ('Cannot open/parse config file: ' + CONFIG_FILE)

CONFIG=loadConfig()

def saveStackDescription (stackId, stackDescription):
  stackFile=buildTempFilePathForStackId(stackId)
  parentDirectory=os.path.abspath(os.path.join(stackFile, '..'))
  try:
    if not os.path.exists(parentDirectory):
      os.makedirs(parentDirectory)

    with open(stackFile, 'wb+') as f:
      f.write(stackDescription)
  except IOError:
      print ('Error')
      print ('Could not save: ', stackFile)

def buildTempFilePathForStackId(stackId):
  return '/tmp/bitbar-aws-opsworks-ssh/stackdescription-' + stackId + '.json'

def loadStackDescription(stackId):
  try:
    with open(buildTempFilePathForStackId(stackId), 'r') as f:
      content =f.read()
      return content
  except IOError:
      print ('Error')
      print ('Cannot open/parse config file: ' + CONFIG_FILE)


def describestackAws(stack_id):
  bashCommand = CONFIG["AWS_CLI_EXECUTABLE"] + " --profile " + CONFIG["AWS_CLI_PROFILE"] + " opsworks --region " + CONFIG["AWS_REGION"] + " describe-instances --stack-id " + stack_id
  # print bashCommand
  process = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
  output, error = process.communicate()
  saveStackDescription(stack_id, output)
  return output

def describestack(stackId):
  if os.path.isfile(buildTempFilePathForStackId(stackId)):
    return json.loads(loadStackDescription(stackId))["Instances"]
  else:
    return json.loads(describestackAws(stackId))["Instances"]

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
  for filter in CONFIG["INSTANCE_INCLUDE_FILTERS"]:
    if not list(filter.keys())[0] in instanceDescription or not re.search(list(filter.values())[0], instanceDescription[list(filter.keys())[0]]):
      return False
  
  # check excludes - return false if key exists and matches
  for filter in CONFIG["INSTANCE_EXCLUDE_FILTERS"]:
    if list(filter.keys())[0] in instanceDescription and re.search(list(filter.values())[0], instanceDescription[list(filter.keys())[0]]):
      return False
  return True

def isOnline (instanceDescription):
  return inst.get('Status', 'unknown') == 'online'

def inValidateCache():
  tmpFileDirectory=os.path.abspath(os.path.join(buildTempFilePathForStackId("notrelevant"), '..'))
  filelist = [ f for f in os.listdir(tmpFileDirectory) if f.endswith(".json") ]
  for f in filelist:
    os.remove(os.path.join(tmpFileDirectory, f))


if len(sys.argv) > 1 and sys.argv[1] == 'inValidateCache':
   inValidateCache()

menu = []
def buildMenu(stackName, stackId):
  stackDescription = describestack(stackId)
  menuStack = []
  for instance in stackDescription:
    if isInstancePlaying(instance):
      menuStack.append(instance)

  menuStack = sorted(menuStack, key=lambda k: k['Hostname'])     
  menu.append({stackName: menuStack})

for stackId in CONFIG["STACKS"]:
  # print ("stackid:", stackId)
  # print ("stackid key:", list(stackId.keys())[0])
  stackName = list(stackId.keys())[0]
  stackUUID = list(stackId.values())[0]
  # print ("stackid val:", list(stackId.values())[0])
  buildMenu(stackName, stackUUID)
  # buildMenu(list(stackId.keys())[0], list(stackId.values())[0])

# static menu
print ("OPS")
print ("---")

lastUpdated = os.path.getmtime(os.path.abspath(os.path.join(buildTempFilePathForStackId("notrelevant"), '..')))
print('As of {0:%Y-%m-%d %H:%M}'.format(datetime.datetime.fromtimestamp(lastUpdated)))

# menu
for elements in menu:
  print(list(elements.keys())[0])
  menuLabel = list(elements.keys())[0]
  # print("inst: ", elements[menuLabel])
  for inst in elements[menuLabel]:
    print ("--" + inst['Hostname'] + " | color=" + ('green' if isOnline(inst) else 'red'))
    if (not isOnline(inst)):
      continue

    for instanceCommand in CONFIG['INSTANCE_ACTIONS']:
      # skip command if stack does not match
      if (instanceCommand.get('stack', menuLabel) != menuLabel ):
        continue

      if instanceCommand['type'] == 'command':
        normalizedCommand = normalizeCommand(instanceCommand['executable'], inst)
        if normalizedCommand != "N/A":
          print ("---- %s | bash='%s' terminal=true" % (instanceCommand['label'], normalizedCommand))
      elif instanceCommand['type'] == 'script':
        normalizedCommand = normalizeCommand(instanceCommand['executable'], inst)
        params = []
        if normalizedCommand != "N/A":
          for i in range(len(instanceCommand['params'])):
            normalizedParam = normalizeCommand(instanceCommand['params'][i], inst)
            params.append( "param" + str(i+1) + "=" + normalizedParam)
          print ("---- %s | bash='%s' %s terminal=true" % (instanceCommand['label'], normalizedCommand, " ".join(params)))

print ("TEST 1| bash=ls param1='-l -a' terminal=true")
print ("TEST 2| bash='/Users/andras/work/helyes/bitbar-plugins/aws-opsworks-ssh/remote-cd-irb.sh' param1='54.252.209.251 $(ctae.sh -g CONFIG_PRIVATE_KEY_FILE) $(ctae.sh -g CONFIG_EC2_USER_NAME) /srv/www/shiftcare/current'    terminal=true")
 
print ("Refresh | terminal=false refresh=true")
# without that, auto refresh would refresh tempfile when app started
# It may take a while so sticking with on demand manual refresh
print ("Refresh remote | bash=" + os.path.abspath(sys.argv[0]) + " param1=inValidateCache terminal=false refresh=true")
