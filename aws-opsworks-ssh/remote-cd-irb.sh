#!/usr/bin/expect -f
#
# Requires brew install expect
# https://likegeeks.com/expect-command/
#
# Run it as remote-cd-irb.sh instance-ip /path/to/private/key/file aws-ec2-username /path/to/project irb=true

# prompt for regular user on remote box
set prompt "$ "
# prompt for superuser on remote box
set sudo_prompt "# "

set remote_ip [lindex $argv 0]
set private_key_file [lindex $argv 1]
set ssh_user [lindex $argv 2]
set rails_project_dir [lindex $argv 3]
set start_irb [lindex $argv 4]

spawn ssh -oStrictHostKeyChecking=no -i $private_key_file $ssh_user@$remote_ip
expect "$prompt"

send "sudo su \r"
expect "$sudo_prompt"

send "cd $rails_project_dir\r"
expect "$sudo_prompt"
 
if { $start_irb == "irb=true" } {
  send "bundle exec rails console\r"
  expect "irb(main):001:0> "

  send " User.limit(1).pluck(:name, :email)\r"
  expect "irb(main):002:0> "
} 

interact
