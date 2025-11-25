#!/usr/bin/expect -f

# Тестирование всех API endpoints

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🧪 Тестирую все API endpoints..."
puts ""

puts "1. /api/menu/?locale=en"
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s 'https://estenomada.es/api/menu/?locale=en' | head -20"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 2

puts "2. /api/hero/images/"
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s 'https://estenomada.es/api/hero/images/' | head -10"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 2

puts "3. /api/translations/by_locale/?locale=en"
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s 'https://estenomada.es/api/translations/by_locale/?locale=en' | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 2

puts "4. /api/stories/public/?locale=en&limit=3"
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s 'https://estenomada.es/api/stories/public/?locale=en&limit=3' | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 2

puts "5. /api/auth/login/ (POST)"
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s -X POST 'https://estenomada.es/api/auth/login/' -H 'Content-Type: application/json' -d '{\"username\":\"test\",\"password\":\"test\"}' | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

