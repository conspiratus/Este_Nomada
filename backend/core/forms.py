"""
Forms для интерфейса повара.
"""
from django import forms


class TTKCreateForm(forms.Form):
    """Форма для создания новой ТТК."""
    name = forms.CharField(
        max_length=200,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Например: для дома, для ресторана, базовая версия'
        }),
        label='Название ТТК',
        help_text='Укажите название или тип ТТК (например: "для дома", "для ресторана")',
        initial='Основная версия'
    )
    content = forms.CharField(
        widget=forms.Textarea(attrs={
            'class': 'form-control ttk-editor-textarea',
            'rows': 30,
            'style': 'font-family: monospace; background-color: #fffacd;'
        }),
        label='Содержимое ТТК',
        help_text='Введите содержимое ТТК в формате Markdown'
    )
    version = forms.CharField(
        max_length=50,
        required=False,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Например: 1.0, 2024-01'
        }),
        label='Версия',
        help_text='Номер или название версии (необязательно)'
    )
    notes = forms.CharField(
        required=False,
        widget=forms.Textarea(attrs={
            'class': 'form-control',
            'rows': 3,
            'placeholder': 'Дополнительные примечания'
        }),
        label='Примечания',
        help_text='Дополнительные заметки о ТТК (необязательно)'
    )
    active = forms.BooleanField(
        required=False,
        initial=True,
        widget=forms.CheckboxInput(attrs={
            'class': 'form-check-input'
        }),
        label='Сделать активной',
        help_text='Если отмечено, эта ТТК станет активной (другие ТТК этого блюда станут неактивными)'
    )


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

