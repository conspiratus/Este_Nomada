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
from .forms import TTKEditForm
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
    dishes = MenuItem.objects.all().select_related('ttk').prefetch_related('translations')
    
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
        dishes = dishes.filter(ttk__isnull=False, ttk__active=True)
    elif ttk_filter == 'without_ttk':
        dishes = dishes.filter(ttk__isnull=True)
    
    # Сортируем по названию
    dishes = dishes.order_by('name')
    
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
    try:
        dish = MenuItem.objects.select_related('ttk').prefetch_related('translations').get(id=dish_id)
    except MenuItem.DoesNotExist:
        messages.error(request, 'Блюдо не найдено.')
        return redirect('chef:dashboard')
    
    ttk = dish.ttk if hasattr(dish, 'ttk') else None
    
    context = {
        'dish': dish,
        'ttk': ttk,
        'user': request.user,
    }
    
    return render(request, 'chef/dish_detail.html', context)


@login_required
def chef_ttk_view(request, dish_id):
    """Просмотр содержимого ТТК файла с возможностью редактирования."""
    dish = get_object_or_404(MenuItem, id=dish_id)
    ttk = dish.ttk if hasattr(dish, 'ttk') else None
    
    if not ttk:
        messages.error(request, 'ТТК для этого блюда не найдена.')
        return redirect('chef:dashboard')
    
    # Читаем содержимое .md файла
    ttk_content = None
    html_content = None
    version_history = []
    
    if settings.TTK_USE_GIT:
        # Используем Git репозиторий
        try:
            repo = ttk.get_git_repo()
            ttk_content = repo.read_file(dish.id, dish.name)
            if ttk_content:
                html_content = markdown.markdown(ttk_content)
                # Получаем историю из Git
                git_history = repo.get_file_history(dish.id, dish.name, limit=10)
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
    
    context = {
        'dish': dish,
        'ttk': ttk,
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
def chef_ttk_edit(request, dish_id):
    """Редактирование содержимого ТТК."""
    dish = get_object_or_404(MenuItem, id=dish_id)
    ttk = dish.ttk if hasattr(dish, 'ttk') else None
    
    if not ttk:
        messages.error(request, 'ТТК для этого блюда не найдена.')
        return redirect('chef:dashboard')
    
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
                    author_email=author_email
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
    
    return redirect('chef:ttk_view', dish_id=dish_id)



