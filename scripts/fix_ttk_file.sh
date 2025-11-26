#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "📥 Получение правильного содержимого ТТК файла..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Получаем содержимое файла напрямую
send "sudo -u www-data cat $ttk_repo_path/ttk/6_Хинкали.md\r"
expect {
    -re "(.*)administrator@" {
        set file_content $expect_out(1,string)
        # Убираем лишние символы
        set file_content [string trim $file_content]
        
        # Сохраняем в локальный файл
        set fp [open "/Users/conspiratus/Projects/Este_Nomada/ttk/6_Хинкали.md" w]
        fconfigure $fp -encoding utf-8
        puts -nonewline $fp $file_content
        close $fp
        
        puts "✅ Файл сохранен"
    }
    timeout {
        puts "❌ Таймаут при получении файла"
    }
}

send "exit\r"
expect eof

