#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set local_path "/Users/conspiratus/Projects/Este_Nomada/ttk"
set remote_path "/var/www/estenomada/ttk_repo/ttk"

puts "📥 Скачивание ТТК файлов с сервера..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Список файлов
send "sudo -u www-data ls -1 $remote_path/*.md\r"
expect "administrator@*"

# Скачиваем каждый файл
send "sudo -u www-data cat $remote_path/6_Хинкали.md\r"
expect {
    "administrator@*" {
        set output $expect_out(buffer)
        # Сохраняем в локальный файл
        exec sh -c "echo '$output' | sed '1d;\$d' > $local_path/6_Хинкали.md"
    }
}

send "exit\r"
expect eof

