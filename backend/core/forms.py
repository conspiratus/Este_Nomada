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
    change_description = forms.CharField(
        required=False,
        widget=forms.Textarea(attrs={
            'class': 'form-control',
            'rows': 3,
            'placeholder': 'Опишите, что было изменено (будет использовано как сообщение коммита)'
        }),
        label='Описание изменений',
        help_text='Краткое описание изменений (будет сохранено в Git как сообщение коммита)'
    )

