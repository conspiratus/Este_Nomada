#!/usr/bin/expect -f

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

set command [lindex $argv 0]
set args [lrange $argv 1 end]

spawn ssh -o StrictHostKeyChecking=no $user@$host $command {*}$args

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

interact

