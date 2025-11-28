"""
Admin views для управления базой данных.
"""
from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.admin.views.decorators import staff_member_required
from django.http import HttpResponse, FileResponse, JsonResponse
from django.views.decorators.http import require_http_methods
from django.conf import settings
from pathlib import Path
from datetime import datetime
import os
import shutil
import subprocess
from django.db import connection
from .db_management import (
    get_db_info, get_tables_info, get_table_data,
    create_backup, list_backups
)


@staff_member_required
def db_overview(request):
    """Обзор базы данных."""
    db_info = get_db_info()
    tables = get_tables_info()
    
    context = {
        'db_info': db_info,
        'tables': tables,
        'title': 'Управление базой данных',
    }
    return render(request, 'admin/db_management/overview.html', context)


@staff_member_required
def db_table_view(request, table_name):
    """Просмотр данных таблицы."""
    limit = int(request.GET.get('limit', 100))
    offset = int(request.GET.get('offset', 0))
    
    columns, rows, total_count = get_table_data(table_name, limit=limit, offset=offset)
    
    if columns is None:
        messages.error(request, f'Таблица "{table_name}" не найдена.')
        return redirect('admin:db_overview')
    
    # Вычисляем значения для пагинации
    prev_offset = max(0, offset - limit)
    next_offset = offset + limit
    rows_count = len(rows) if rows else 0
    end_index = offset + rows_count
    
    context = {
        'table_name': table_name,
        'columns': columns,
        'rows': rows,
        'total_count': total_count,
        'limit': limit,
        'offset': offset,
        'prev_offset': prev_offset,
        'next_offset': next_offset,
        'end_index': end_index,
        'has_prev': offset > 0,
        'has_next': offset + limit < total_count,
        'title': f'Таблица: {table_name}',
    }
    return render(request, 'admin/db_management/table_view.html', context)


@staff_member_required
@require_http_methods(["POST"])
def db_backup_create(request):
    """Создать бэкап базы данных."""
    try:
        backup_path, backup_filename = create_backup()
        messages.success(request, f'Бэкап успешно создан: {backup_filename}')
    except Exception as e:
        messages.error(request, f'Ошибка при создании бэкапа: {str(e)}')
    
    return redirect('admin:db_backups')


@staff_member_required
def db_backups_list(request):
    """Список бэкапов."""
    backups = list_backups()
    
    context = {
        'backups': backups,
        'title': 'Бэкапы базы данных',
    }
    return render(request, 'admin/db_management/backups.html', context)


@staff_member_required
def db_backup_download(request, filename):
    """Скачать бэкап."""
    backup_dir = Path(settings.BASE_DIR) / 'backups'
    backup_path = backup_dir / filename
    
    # Проверка безопасности
    if not backup_path.exists() or not str(backup_path).startswith(str(backup_dir)):
        messages.error(request, 'Файл не найден или недопустимый путь.')
        return redirect('admin:db_backups')
    
    response = FileResponse(
        open(backup_path, 'rb'),
        as_attachment=True,
        filename=filename
    )
    return response


@staff_member_required
@require_http_methods(["POST"])
def db_backup_restore(request):
    """Восстановить базу данных из бэкапа."""
    filename = request.POST.get('filename')
    if not filename:
        messages.error(request, 'Не указан файл бэкапа.')
        return redirect('admin:db_backups')
    
    backup_dir = Path(settings.BASE_DIR) / 'backups'
    backup_path = backup_dir / filename
    
    # Проверка безопасности
    if not backup_path.exists() or not str(backup_path).startswith(str(backup_dir)):
        messages.error(request, 'Файл не найден или недопустимый путь.')
        return redirect('admin:db_backups')
    
    db_config = settings.DATABASES['default']
    engine = db_config['ENGINE']
    use_sqlite = 'sqlite3' in engine
    
    try:
        if use_sqlite:
            # SQLite: копируем файл
            db_path = Path(db_config['NAME'])
            # Создаем резервную копию текущей БД
            if db_path.exists():
                backup_current = backup_dir / f'pre_restore_{datetime.now().strftime("%Y%m%d_%H%M%S")}.sqlite3'
                shutil.copy2(db_path, backup_current)
                messages.info(request, f'Создана резервная копия текущей БД: {backup_current.name}')
            
            shutil.copy2(backup_path, db_path)
            messages.success(request, f'База данных восстановлена из {filename}')
        else:
            # MySQL: используем mysql
            cmd = [
                'mysql',
                f"--user={db_config['USER']}",
                f"--password={db_config['PASSWORD']}",
                f"--host={db_config.get('HOST', 'localhost')}",
                f"--port={db_config.get('PORT', '3306')}",
                db_config['NAME'],
            ]
            
            # Создаем резервную копию текущей БД перед восстановлением
            try:
                backup_current_path, backup_current_filename = create_backup()
                messages.info(request, f'Создана резервная копия текущей БД: {backup_current_filename}')
            except Exception as e:
                messages.warning(request, f'Не удалось создать резервную копию перед восстановлением: {str(e)}')
            
            with open(backup_path, 'r', encoding='utf-8') as f:
                result = subprocess.run(
                    cmd,
                    stdin=f,
                    stderr=subprocess.PIPE,
                    text=True,
                    check=True
                )
            
            messages.success(request, f'База данных восстановлена из {filename}')
    except Exception as e:
        messages.error(request, f'Ошибка при восстановлении: {str(e)}')
    
    return redirect('admin:db_backups')

