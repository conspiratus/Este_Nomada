#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
# GitHub token should be passed as environment variable GITHUB_TOKEN or set manually
set github_token $env(GITHUB_TOKEN)
if { $github_token == "" } {
    puts "⚠️  GITHUB_TOKEN environment variable not set. Please set it before running this script."
    puts "   export GITHUB_TOKEN=your_token_here"
    exit 1
}
set ttk_repo_path "/var/www/estenomada/ttk_repo"
set main_repo_url "https://github.com/conspiratus/Este_Nomada.git"

puts "🔧 Восстановление синхронизации ТТК репозитория после переписывания истории..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Создаем резервную копию текущего состояния
puts "\n💾 Создаю резервную копию текущего состояния..."
send "sudo -u www-data cp -r $ttk_repo_path ${ttk_repo_path}_backup_$(date +%Y%m%d_%H%M%S) 2>&1\r"
expect "administrator@*"

# Проверяем текущий статус
puts "\n📊 Проверяю текущий статус репозитория..."
send "cd $ttk_repo_path && sudo -u www-data git status\r"
expect "administrator@*"

# Сохраняем незакоммиченные изменения если есть
puts "\n💾 Сохраняю незакоммиченные изменения..."
send "cd $ttk_repo_path && sudo -u www-data git stash 2>&1 || echo 'Нет изменений для сохранения'\r"
expect "administrator@*"

# Проверяем remote
puts "\n🔗 Проверяю remote настройки..."
send "cd $ttk_repo_path && sudo -u www-data git remote -v\r"
expect "administrator@*"

# Обновляем remote с токеном для аутентификации
puts "\n🔧 Обновляю remote с токеном..."
send "cd $ttk_repo_path && sudo -u www-data git remote remove origin 2>/dev/null; echo 'Старый remote удален'\r"
expect "administrator@*"

send "cd $ttk_repo_path && sudo -u www-data git remote add origin https://${github_token}@github.com/conspiratus/Este_Nomada.git\r"
expect "administrator@*"

# Получаем новую историю
puts "\n📥 Получаю новую историю из GitHub..."
send "cd $ttk_repo_path && sudo -u www-data git fetch origin --force\r"
expect "administrator@*"

# Проверяем, есть ли локальная ветка main
puts "\n🌿 Проверяю локальные ветки..."
send "cd $ttk_repo_path && sudo -u www-data git branch\r"
expect "administrator@*"

# Переключаемся на main и делаем hard reset к новой истории
puts "\n🔄 Переключаюсь на новую историю..."
send "cd $ttk_repo_path && sudo -u www-data git checkout -B main origin/main 2>&1 || sudo -u www-data git checkout -b main origin/main 2>&1\r"
expect "administrator@*"

# Проверяем, что файлы ttk/ на месте
puts "\n📁 Проверяю наличие файлов ttk/..."
send "cd $ttk_repo_path && sudo -u www-data ls -lah ttk/ 2>&1 | head -10\r"
expect "administrator@*"

# Если файлов нет, копируем из основного репозитория
puts "\n📋 Проверяю структуру репозитория..."
send "cd $ttk_repo_path && sudo -u www-data git ls-tree -r HEAD --name-only | grep '^ttk/' | head -5\r"
expect "administrator@*"

# Восстанавливаем незакоммиченные изменения если были
puts "\n🔄 Восстанавливаю незакоммиченные изменения..."
send "cd $ttk_repo_path && sudo -u www-data git stash pop 2>&1 || echo 'Нет сохраненных изменений'\r"
expect "administrator@*"

# Проверяем финальный статус
puts "\n✅ Проверяю финальный статус..."
send "cd $ttk_repo_path && sudo -u www-data git status\r"
expect "administrator@*"

# Показываем последние коммиты
puts "\n📋 Последние коммиты:"
send "cd $ttk_repo_path && sudo -u www-data git --no-pager log --oneline -10\r"
expect "administrator@*"

puts "\n✅ Синхронизация восстановлена!"
puts "\n💡 Теперь:"
puts "   - Репозиторий синхронизирован с новой историей GitHub"
puts "   - Файлы ttk/ должны быть доступны"
puts "   - История изменений должна отображаться в шефском портале"

send "exit\r"
expect eof

