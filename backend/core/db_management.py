"""
Управление базой данных через админку Django.
"""
import os
import subprocess
import shutil
from datetime import datetime
from pathlib import Path
from django.conf import settings
from django.db import connection
from django.http import HttpResponse, JsonResponse, FileResponse
from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.admin.views.decorators import staff_member_required
from django.views.decorators.http import require_http_methods
from django.utils import timezone


def get_db_info():
    """Получить информацию о базе данных."""
    db_config = settings.DATABASES['default']
    engine = db_config['ENGINE']
    use_sqlite = 'sqlite3' in engine
    
    info = {
        'engine': 'SQLite' if use_sqlite else 'MySQL',
        'use_sqlite': use_sqlite,
        'name': db_config.get('NAME', ''),
        'host': db_config.get('HOST', 'localhost'),
        'port': db_config.get('PORT', ''),
    }
    
    # Размер БД
    if use_sqlite:
        db_path = Path(db_config['NAME'])
        if db_path.exists():
            size_bytes = db_path.stat().st_size
            info['size_bytes'] = size_bytes
            info['size_mb'] = round(size_bytes / (1024 * 1024), 2)
        else:
            info['size_bytes'] = 0
            info['size_mb'] = 0
    else:
        # MySQL
        with connection.cursor() as cursor:
            cursor.execute("SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = %s GROUP BY table_schema", [db_config['NAME']])
            result = cursor.fetchone()
            if result:
                info['size_mb'] = float(result[1]) if result[1] else 0
                info['size_bytes'] = int(info['size_mb'] * 1024 * 1024)
            else:
                info['size_mb'] = 0
                info['size_bytes'] = 0
    
    return info


def get_tables_info():
    """Получить информацию о таблицах в БД."""
    db_config = settings.DATABASES['default']
    engine = db_config['ENGINE']
    use_sqlite = 'sqlite3' in engine
    
    tables = []
    
    if use_sqlite:
        with connection.cursor() as cursor:
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
            table_names = [row[0] for row in cursor.fetchall()]
            
            for table_name in table_names:
                # Получаем количество записей
                cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
                row_count = cursor.fetchone()[0]
                
                # Получаем размер таблицы (приблизительно)
                cursor.execute(f"SELECT COUNT(*) FROM pragma_table_info('{table_name}')")
                col_count = cursor.fetchone()[0]
                
                tables.append({
                    'name': table_name,
                    'row_count': row_count,
                    'column_count': col_count,
                })
    else:
        # MySQL
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    table_name,
                    table_rows,
                    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
                FROM information_schema.tables
                WHERE table_schema = %s
                ORDER BY table_name
            """, [db_config['NAME']])
            
            for row in cursor.fetchall():
                tables.append({
                    'name': row[0],
                    'row_count': row[1] if row[1] else 0,
                    'size_mb': float(row[2]) if row[2] else 0,
                })
    
    return tables


def get_table_data(table_name, limit=100, offset=0):
    """Получить данные из таблицы."""
    with connection.cursor() as cursor:
        # Проверяем существование таблицы
        db_config = settings.DATABASES['default']
        engine = db_config['ENGINE']
        use_sqlite = 'sqlite3' in engine
        
        if use_sqlite:
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [table_name])
        else:
            cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = %s AND table_name = %s", [db_config['NAME'], table_name])
        
        if not cursor.fetchone():
            return None, None, None
        
        # Получаем колонки
        cursor.execute(f"SELECT * FROM {table_name} LIMIT 0")
        columns = [desc[0] for desc in cursor.description]
        
        # Получаем общее количество записей
        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        total_count = cursor.fetchone()[0]
        
        # Получаем данные
        cursor.execute(f"SELECT * FROM {table_name} LIMIT {limit} OFFSET {offset}")
        rows = cursor.fetchall()
        
        return columns, rows, total_count


def create_backup():
    """Создать бэкап базы данных."""
    db_config = settings.DATABASES['default']
    engine = db_config['ENGINE']
    use_sqlite = 'sqlite3' in engine
    
    # Создаем директорию для бэкапов
    backup_dir = Path(settings.BASE_DIR) / 'backups'
    backup_dir.mkdir(exist_ok=True)
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    if use_sqlite:
        # SQLite: просто копируем файл
        db_path = Path(db_config['NAME'])
        backup_filename = f'db_backup_{timestamp}.sqlite3'
        backup_path = backup_dir / backup_filename
        
        if db_path.exists():
            shutil.copy2(db_path, backup_path)
            return backup_path, backup_filename
        else:
            raise FileNotFoundError(f"Database file not found: {db_path}")
    else:
        # MySQL: используем mysqldump
        backup_filename = f'db_backup_{timestamp}.sql'
        backup_path = backup_dir / backup_filename
        
        cmd = [
            'mysqldump',
            f"--user={db_config['USER']}",
            f"--password={db_config['PASSWORD']}",
            f"--host={db_config.get('HOST', 'localhost')}",
            f"--port={db_config.get('PORT', '3306')}",
            '--single-transaction',
            '--routines',
            '--triggers',
            db_config['NAME'],
        ]
        
        try:
            with open(backup_path, 'w', encoding='utf-8') as f:
                result = subprocess.run(
                    cmd,
                    stdout=f,
                    stderr=subprocess.PIPE,
                    text=True,
                    check=True
                )
            return backup_path, backup_filename
        except subprocess.CalledProcessError as e:
            raise Exception(f"Backup failed: {e.stderr}")
        except FileNotFoundError:
            raise Exception("mysqldump not found. Please install MySQL client tools.")


def list_backups():
    """Получить список доступных бэкапов."""
    backup_dir = Path(settings.BASE_DIR) / 'backups'
    if not backup_dir.exists():
        return []
    
    backups = []
    for file_path in sorted(backup_dir.iterdir(), key=lambda x: x.stat().st_mtime, reverse=True):
        if file_path.is_file() and (file_path.suffix == '.sqlite3' or file_path.suffix == '.sql'):
            stat = file_path.stat()
            backups.append({
                'filename': file_path.name,
                'path': str(file_path),
                'size_bytes': stat.st_size,
                'size_mb': round(stat.st_size / (1024 * 1024), 2),
                'created': datetime.fromtimestamp(stat.st_mtime),
            })
    
    return backups

