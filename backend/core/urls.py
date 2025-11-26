"""
URLs для интерфейса повара.
"""
from django.urls import path
from . import views

app_name = 'chef'

urlpatterns = [
    path('login/', views.chef_login, name='login'),
    path('logout/', views.chef_logout, name='logout'),
    path('', views.chef_dashboard, name='dashboard'),
    path('dish/<int:dish_id>/', views.chef_dish_detail, name='dish_detail'),
    path('dish/<int:dish_id>/ttk/create/', views.chef_ttk_create, name='ttk_create'),
    path('dish/<int:dish_id>/ttk/list/', views.chef_ttk_list, name='ttk_list'),
    path('dish/<int:dish_id>/ttk/<int:ttk_id>/', views.chef_ttk_view, name='ttk_view'),
    path('dish/<int:dish_id>/ttk/<int:ttk_id>/edit/', views.chef_ttk_edit, name='ttk_edit'),
    path('dish/<int:dish_id>/ttk/<int:ttk_id>/set-active/', views.chef_ttk_set_active, name='ttk_set_active'),
    # Старые URL для обратной совместимости
    path('dish/<int:dish_id>/ttk/', views.chef_ttk_view, name='ttk_view_old'),
]

