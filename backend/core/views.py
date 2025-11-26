"""
Views для интерфейса повара.
"""
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.db.models import Q
from django.views.decorators.http import require_http_methods
from django.conf import settings
from .models import MenuItem, DishTTK
from .forms import TTKEditForm, TTKCreateForm
from django.utils import timezone
import markdown
import os


def chef_login(request):
    """Страница входа для повара."""
    if request.user.is_authenticated:
        return redirect('chef:dashboard')
    
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        
        if username and password:
            user = authenticate(request, username=username, password=password)
            if user is not None:
                login(request, user)
                messages.success(request, f'Добро пожаловать, {user.username}!')
                return redirect('chef:dashboard')
            else:
                messages.error(request, 'Неверный логин или пароль.')
        else:
            messages.error(request, 'Пожалуйста, введите логин и пароль.')
    
    return render(request, 'chef/login.html')


@login_required
def chef_logout(request):
    """Выход для повара."""
    logout(request)
    messages.success(request, 'Вы успешно вышли из системы.')
    return redirect('chef:login')


@login_required
def chef_dashboard(request):
    """Главная страница интерфейса повара - список всех блюд с ТТК."""
    # Получаем все блюда (включая неактивные)
    dishes = MenuItem.objects.all().prefetch_related('ttks', 'translations')
    
    # Поиск
    search_query = request.GET.get('search', '')
    if search_query:
        dishes = dishes.filter(
            Q(name__icontains=search_query) |
            Q(translations__name__icontains=search_query)
        ).distinct()
    
    # Фильтр по наличию ТТК
    ttk_filter = request.GET.get('ttk_filter', 'all')
    if ttk_filter == 'with_ttk':
        dishes = dishes.filter(ttks__isnull=False, ttks__active=True).distinct()
    elif ttk_filter == 'without_ttk':
        dishes = dishes.filter(ttks__isnull=True)
    
    # Сортируем по названию
    dishes = dishes.order_by('name')
    
    # Для каждого блюда получаем активную ТТК
    for dish in dishes:
        dish.active_ttk = dish.ttks.filter(active=True).first()
        dish.ttk_count = dish.ttks.count()
    
    context = {
        'dishes': dishes,
        'search_query': search_query,
        'ttk_filter': ttk_filter,
        'user': request.user,
    }
    
    return render(request, 'chef/dashboard.html', context)


@login_required
def chef_dish_detail(request, dish_id):
    """Детальная страница блюда с ТТК."""
    dish = get_object_or_404(MenuItem, id=dish_id)
    
    # Получаем все ТТК для этого блюда
    ttks = dish.ttks.all().order_by('-active', '-updated_at')
    active_ttk = dish.ttks.filter(active=True).first()
    
    context = {
        'dish': dish,
        'ttks': ttks,
        'active_ttk': active_ttk,
        'user': request.user,
    }
    
    return render(request, 'chef/dish_detail.html', context)


@login_required
def chef_ttk_view(request, dish_id, ttk_id=None):
    """Просмотр содержимого ТТК файла с возможностью редактирования."""
    dish = get_object_or_404(MenuItem, id=dish_id)
    
    # Если ttk_id не указан, используем активную ТТК
    if ttk_id:
        ttk = get_object_or_404(DishTTK, id=ttk_id, menu_item=dish)
    else:
        ttk = dish.ttks.filter(active=True).first()
        if not ttk:
            messages.error(request, 'ТТК для этого блюда не найдена.')
            return redirect('chef:dish_detail', dish_id=dish_id)
    
    # Читаем содержимое .md файла
    ttk_content = None
    html_content = None
    version_history = []
    
    if settings.TTK_USE_GIT:
        # Используем Git репозиторий
        try:
            repo = ttk.get_git_repo()
            ttk_content = repo.read_file(dish.id, dish.name, ttk_id=ttk.id, ttk_name=ttk.name)
            if ttk_content:
                html_content = markdown.markdown(ttk_content)
                # Получаем историю из Git
                git_history = repo.get_file_history(dish.id, dish.name, limit=10, ttk_id=ttk.id, ttk_name=ttk.name)
                version_history = [
                    {
                        'version': f"commit {item['hash'][:7]}",
                        'changed_by_name': item['author_name'],
                        'created_at': item['date'],
                        'change_description': item['message'],
                    }
                    for item in git_history
                ]
        except Exception as e:
            messages.error(request, f'Ошибка при чтении ТТК из Git: {str(e)}')
    else:
        # Используем старый способ через FileField
        if ttk.ttk_file:
            try:
                with open(ttk.ttk_file.path, 'r', encoding='utf-8') as f:
                    ttk_content = f.read()
                html_content = markdown.markdown(ttk_content)
            except Exception as e:
                messages.error(request, f'Ошибка при чтении файла ТТК: {str(e)}')
    
    # Форма для редактирования
    edit_form = TTKEditForm(initial={
        'content': ttk_content or '',
    })
    
    # Получаем все ТТК для этого блюда
    all_ttks = dish.ttks.all().order_by('-active', '-updated_at')
    
    context = {
        'dish': dish,
        'ttk': ttk,
        'all_ttks': all_ttks,
        'ttk_content': ttk_content,
        'html_content': html_content,
        'version_history': version_history,
        'edit_form': edit_form,
        'user': request.user,
        'use_git': settings.TTK_USE_GIT,
    }
    
    return render(request, 'chef/ttk_view.html', context)


@login_required
@require_http_methods(["POST"])
def chef_ttk_edit(request, dish_id, ttk_id):
    """Редактирование содержимого ТТК."""
    dish = get_object_or_404(MenuItem, id=dish_id)
    ttk = get_object_or_404(DishTTK, id=ttk_id, menu_item=dish)
    
    form = TTKEditForm(request.POST)
    
    if form.is_valid():
        new_content = form.cleaned_data['content']
        change_description = form.cleaned_data.get('change_description', '').strip()
        
        # Формируем сообщение коммита
        if change_description:
            commit_message = f"{dish.name}: {change_description}"
        else:
            commit_message = f"Обновление ТТК: {dish.name}"
        
        try:
            if settings.TTK_USE_GIT:
                # Используем Git репозиторий
                repo = ttk.get_git_repo()
                author_name = request.user.get_full_name() or request.user.username
                author_email = request.user.email or settings.TTK_GIT_USER_EMAIL
                
                    success = repo.write_file(
                        dish.id,
                        dish.name,
                        new_content,
                        commit_message,
                        author_name=author_name,
                        author_email=author_email,
                        ttk_id=ttk.id,
                        ttk_name=ttk.name
                    )
                
                if success:
                    ttk.save()  # Обновляем updated_at
                    messages.success(request, 'ТТК успешно обновлена и закоммичена в Git.')
                else:
                    messages.error(request, 'Ошибка при сохранении ТТК в Git.')
            else:
                # Используем старый способ через FileField
                if ttk.ttk_file:
                    with open(ttk.ttk_file.path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    ttk.save()
                    messages.success(request, 'ТТК успешно обновлена.')
                else:
                    messages.error(request, 'Файл ТТК не найден.')
        except Exception as e:
            messages.error(request, f'Ошибка при сохранении ТТК: {str(e)}')
    else:
        messages.error(request, 'Ошибка в форме редактирования.')
    
    return redirect('chef:ttk_view', dish_id=dish_id, ttk_id=ttk_id)


@login_required
def chef_ttk_create(request, dish_id):
    """Создание новой ТТК для блюда."""
    dish = get_object_or_404(MenuItem, id=dish_id)
    
    if request.method == 'POST':
        form = TTKCreateForm(request.POST)
        
        if form.is_valid():
            name = form.cleaned_data['name']
            content = form.cleaned_data['content']
            version = form.cleaned_data.get('version', '').strip()
            notes = form.cleaned_data.get('notes', '').strip()
            make_active = form.cleaned_data.get('active', False)
            
            # Если делаем активной, деактивируем остальные ТТК этого блюда
            if make_active:
                dish.ttks.update(active=False)
            
            # Создаем новую ТТК
            ttk = DishTTK.objects.create(
                menu_item=dish,
                name=name,
                version=version or None,
                notes=notes or None,
                active=make_active
            )
            
            # Сохраняем содержимое в Git или файл
            try:
                if settings.TTK_USE_GIT:
                    repo = ttk.get_git_repo()
                    author_name = request.user.get_full_name() or request.user.username
                    author_email = request.user.email or settings.TTK_GIT_USER_EMAIL
                    
                    commit_message = f"Создание ТТК: {dish.name} - {name}"
                    if version:
                        commit_message += f" (версия {version})"
                    
                    success = repo.write_file(
                        dish.id,
                        dish.name,
                        content,
                        commit_message,
                        author_name=author_name,
                        author_email=author_email,
                        ttk_id=ttk.id,
                        ttk_name=ttk.name
                    )
                    
                    if success:
                        # Обновляем git_path
                        file_path = repo.get_file_path(dish.id, dish.name, ttk_id=ttk.id, ttk_name=ttk.name)
                        ttk.git_path = str(file_path.relative_to(repo.repo_path))
                        ttk.save()
                        messages.success(request, f'ТТК "{name}" успешно создана и сохранена в Git.')
                    else:
                        messages.error(request, 'Ошибка при сохранении ТТК в Git.')
                        ttk.delete()
                        return redirect('chef:dish_detail', dish_id=dish_id)
                else:
                    # Старый способ через FileField (не реализован для создания)
                    messages.error(request, 'Создание ТТК через FileField не поддерживается. Включите Git интеграцию.')
                    ttk.delete()
                    return redirect('chef:dish_detail', dish_id=dish_id)
            except Exception as e:
                messages.error(request, f'Ошибка при создании ТТК: {str(e)}')
                ttk.delete()
                return redirect('chef:dish_detail', dish_id=dish_id)
            
            return redirect('chef:ttk_view', dish_id=dish_id, ttk_id=ttk.id)
    else:
        form = TTKCreateForm()
    
    context = {
        'dish': dish,
        'form': form,
        'user': request.user,
    }
    
    return render(request, 'chef/ttk_create.html', context)


@login_required
@require_http_methods(["POST"])
def chef_ttk_set_active(request, dish_id, ttk_id):
    """Установка активной ТТК для блюда."""
    dish = get_object_or_404(MenuItem, id=dish_id)
    ttk = get_object_or_404(DishTTK, id=ttk_id, menu_item=dish)
    
    # Деактивируем все ТТК этого блюда
    dish.ttks.update(active=False)
    
    # Активируем выбранную ТТК
    ttk.active = True
    ttk.save()
    
    messages.success(request, f'ТТК "{ttk.name}" теперь активна для блюда "{dish.name}".')
    
    return redirect('chef:dish_detail', dish_id=dish_id)


@login_required
def chef_ttk_list(request, dish_id):
    """Список всех ТТК для блюда."""
    dish = get_object_or_404(MenuItem, id=dish_id)
    ttks = dish.ttks.all().order_by('-active', '-updated_at')
    
    context = {
        'dish': dish,
        'ttks': ttks,
        'user': request.user,
    }
    
    return render(request, 'chef/ttk_list.html', context)


