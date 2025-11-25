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
    path('dish/<int:dish_id>/ttk/', views.chef_ttk_view, name='ttk_view'),
    path('dish/<int:dish_id>/ttk/edit/', views.chef_ttk_edit, name='ttk_edit'),
]

