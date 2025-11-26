#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "📥 Синхронизация последних коммитов с сервера..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Получаем список коммитов, которых нет в GitHub
send "cd $ttk_repo_path && sudo -u www-data git log --oneline origin/main..HEAD 2>/dev/null || sudo -u www-data git log --oneline -5\r"
expect "administrator@*"

# Скачиваем файл
send "sudo -u www-data cat $ttk_repo_path/ttk/6_Хинкали.md\r"
expect {
    -re "(.*)administrator@" {
        set file_content $expect_out(1,string)
        set file_content [string trim $file_content]
        
        set fp [open "/Users/conspiratus/Projects/Este_Nomada/ttk/6_Хинкали.md" w]
        fconfigure $fp -encoding utf-8
        puts -nonewline $fp $file_content
        close $fp
        
        puts "✅ Файл сохранен"
    }
}

send "exit\r"
expect eof

