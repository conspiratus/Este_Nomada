"""
Views для интерфейса повара.
"""
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.db.models import Q
from django.views.decorators.http import require_http_methods
from .models import MenuItem, DishTTK, TTKVersionHistory
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
    if ttk.ttk_file:
        try:
            with open(ttk.ttk_file.path, 'r', encoding='utf-8') as f:
                ttk_content = f.read()
            # Конвертируем markdown в HTML
            html_content = markdown.markdown(ttk_content)
        except Exception as e:
            messages.error(request, f'Ошибка при чтении файла ТТК: {str(e)}')
    
    # Получаем историю версий
    version_history = TTKVersionHistory.objects.filter(ttk=ttk).select_related('changed_by').order_by('-created_at')[:10]
    
    # Форма для редактирования
    edit_form = TTKEditForm(initial={
        'content': ttk_content,
        'version': ttk.version,
    })
    
    context = {
        'dish': dish,
        'ttk': ttk,
        'ttk_content': ttk_content,
        'html_content': html_content,
        'version_history': version_history,
        'edit_form': edit_form,
        'user': request.user,
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
        new_version = form.cleaned_data.get('version', '').strip()
        change_description = form.cleaned_data.get('change_description', '').strip()
        
        try:
            # Сохраняем текущую версию в историю, если указана новая версия
            if new_version and new_version != ttk.version:
                # Читаем текущее содержимое файла
                current_content = ''
                if ttk.ttk_file:
                    try:
                        with open(ttk.ttk_file.path, 'r', encoding='utf-8') as f:
                            current_content = f.read()
                    except Exception:
                        pass
                
                TTKVersionHistory.objects.create(
                    ttk=ttk,
                    version=ttk.version or '1.0',
                    content=current_content,
                    changed_by=request.user,
                    change_description=change_description
                )
                ttk.version = new_version
            
            # Сохраняем новое содержимое в файл
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



