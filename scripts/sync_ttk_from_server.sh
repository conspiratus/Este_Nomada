#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "📥 Синхронизация ТТК файлов с сервера..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Получаем последний коммит
send "cd $ttk_repo_path && sudo -u www-data git log -1 --format='%H|%s' HEAD\r"
expect "administrator@*"

# Скачиваем файл
send "sudo -u www-data cat $ttk_repo_path/ttk/6_Хинкали.md\r"
expect {
    "administrator@*" {
        set content [string range $expect_out(buffer) 0 [string first "administrator@" $expect_out(buffer)]]
        set content [regsub -all {administrator@[^\n]*\n} $content ""]
        set content [regsub -all {sudo -u www-data cat[^\n]*\n} $content ""]
        
        set fp [open "/Users/conspiratus/Projects/Este_Nomada/ttk/6_Хинкали.md" w]
        puts $fp $content
        close $fp
    }
}

send "exit\r"
expect eof

