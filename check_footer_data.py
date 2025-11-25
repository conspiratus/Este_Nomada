#!/usr/bin/env python3
import requests
import json

# Проверяем что приходит с API
url = "https://api.estenomada.es/api/footer/?locale=ru"
response = requests.get(url)
data = response.json()

print("Данные с API:")
print(json.dumps(data, indent=2, ensure_ascii=False))

if data.get('results'):
    first = data['results'][0]
    print(f"\nПервый результат:")
    print(f"Title: {first.get('title', '')[:200]}")
    print(f"Content: {first.get('content', '')[:200] if first.get('content') else ''}")

