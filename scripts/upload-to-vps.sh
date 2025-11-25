#!/usr/bin/expect -f

set timeout 600
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

set local_file [lindex $argv 0]
set remote_path [lindex $argv 1]

spawn scp -o StrictHostKeyChecking=no $local_file $user@$host:$remote_path

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}

