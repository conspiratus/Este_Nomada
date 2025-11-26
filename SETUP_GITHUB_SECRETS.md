# Настройка GitHub Secrets для автоматического деплоя

## 🔐 Необходимые секреты

Для работы автоматического деплоя нужно настроить следующие секреты в GitHub:

1. **PROD_SERVER_HOST** = `85.190.102.101`
2. **PROD_SERVER_USER** = `administrator`
3. **PROD_SERVER_PASSWORD** = `Jovi4AndMay2020!`

## 📝 Как настроить

### Вариант 1: Через GitHub UI (рекомендуется)

1. Перейдите: https://github.com/conspiratus/Este_Nomada/settings/secrets/actions
2. Нажмите **"New repository secret"**
3. Добавьте каждый секрет:
   - **Name**: `PROD_SERVER_HOST`, **Value**: `85.190.102.101`
   - **Name**: `PROD_SERVER_USER`, **Value**: `administrator`
   - **Name**: `PROD_SERVER_PASSWORD`, **Value**: `Jovi4AndMay2020!`

### Вариант 2: Через GitHub CLI

Если установлен GitHub CLI:

```bash
gh secret set PROD_SERVER_HOST --body "85.190.102.101" --repo conspiratus/Este_Nomada
gh secret set PROD_SERVER_USER --body "administrator" --repo conspiratus/Este_Nomada
gh secret set PROD_SERVER_PASSWORD --body "Jovi4AndMay2020!" --repo conspiratus/Este_Nomada
```

## ✅ Проверка

После настройки секретов, следующий push в `main` автоматически запустит деплой.

Проверить можно здесь: https://github.com/conspiratus/Este_Nomada/actions

## 🔒 Безопасность

- Секреты хранятся в зашифрованном виде
- Доступны только для GitHub Actions
- Не отображаются в логах

