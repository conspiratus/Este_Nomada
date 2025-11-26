"""
Forms для интерфейса повара.
"""
from django import forms


class TTKEditForm(forms.Form):
    """Форма для редактирования содержимого ТТК."""
    content = forms.CharField(
        widget=forms.Textarea(attrs={
            'class': 'form-control ttk-editor-textarea',
            'rows': 30,
            'style': 'font-family: monospace; background-color: #fffacd;'
        }),
        label='Содержимое ТТК',
        help_text='Отредактируйте содержимое ТТК в формате Markdown'
    )
    version = forms.CharField(
        max_length=50,
        required=False,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Например: 1.1, 2024-02'
        }),
        label='Новая версия',
        help_text='Укажите номер новой версии (оставьте пустым, чтобы не создавать новую версию)'
    )
    change_description = forms.CharField(
        required=False,
        widget=forms.Textarea(attrs={
            'class': 'form-control',
            'rows': 3,
            'placeholder': 'Опишите, что было изменено в этой версии'
        }),
        label='Описание изменений',
        help_text='Краткое описание изменений в этой версии'
    )

