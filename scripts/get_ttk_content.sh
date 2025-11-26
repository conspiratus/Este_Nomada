#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "📥 Получение содержимого ТТК файла..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

send "sudo -u www-data cat /var/www/estenomada/ttk_repo/ttk/6_Хинкали.md\r"
expect {
    "administrator@*" {
        # Получаем весь вывод до промпта
        set content [string range $expect_out(buffer) 0 [string first "administrator@" $expect_out(buffer)]]
        # Убираем промпты и команды
        set content [regsub -all {administrator@[^\n]*\n} $content ""]
        set content [regsub -all {sudo -u www-data cat[^\n]*\n} $content ""]
        
        # Сохраняем в файл
        set fp [open "/Users/conspiratus/Projects/Este_Nomada/ttk/6_Хинкали.md" w]
        puts $fp $content
        close $fp
        
        puts "✅ Файл сохранен"
    }
}

send "exit\r"
expect eof

