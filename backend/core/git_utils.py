"""
Утилиты для работы с Git репозиторием ТТК файлов.
"""
import os
import subprocess
import logging
from pathlib import Path
from typing import Optional, List, Dict
from datetime import datetime

logger = logging.getLogger(__name__)


class TTKGitRepository:
    """Класс для работы с Git репозиторием ТТК."""
    
    def __init__(self, repo_path: str, git_user_name: str = "Este Nomada Chef", git_user_email: str = "chef@estenomada.es"):
        """
        Инициализация Git репозитория.
        
        Args:
            repo_path: Путь к Git репозиторию
            git_user_name: Имя пользователя для Git коммитов
            git_user_email: Email пользователя для Git коммитов
        """
        self.repo_path = Path(repo_path)
        self.git_user_name = git_user_name
        self.git_user_email = git_user_email
        self._ensure_repo_exists()
    
    def _ensure_repo_exists(self):
        """Создает репозиторий, если его нет."""
        if not self.repo_path.exists():
            self.repo_path.mkdir(parents=True, exist_ok=True)
            self._run_git(['init'])
            self._run_git(['config', 'user.name', self.git_user_name])
            self._run_git(['config', 'user.email', self.git_user_email])
            # Создаем начальный коммит
            readme_path = self.repo_path / 'README.md'
            readme_path.write_text('# ТТК файлы\n\nРепозиторий технико-технологических карт блюд.\n', encoding='utf-8')
            self._run_git(['add', 'README.md'])
            self._run_git(['commit', '-m', 'Initial commit'])
            logger.info(f"Создан новый Git репозиторий: {self.repo_path}")
        else:
            # Убеждаемся, что это Git репозиторий
            if not (self.repo_path / '.git').exists():
                self._run_git(['init'])
                self._run_git(['config', 'user.name', self.git_user_name])
                self._run_git(['config', 'user.email', self.git_user_email])
    
    def _run_git(self, cmd: List[str], cwd: Optional[Path] = None) -> subprocess.CompletedProcess:
        """
        Выполняет Git команду.
        
        Args:
            cmd: Список аргументов Git команды
            cwd: Рабочая директория (по умолчанию repo_path)
        
        Returns:
            CompletedProcess результат выполнения команды
        """
        if cwd is None:
            cwd = self.repo_path
        
        full_cmd = ['git'] + cmd
        try:
            result = subprocess.run(
                full_cmd,
                cwd=cwd,
                capture_output=True,
                text=True,
                check=False,
                encoding='utf-8'
            )
            if result.returncode != 0:
                logger.warning(f"Git command failed: {' '.join(full_cmd)}\nError: {result.stderr}")
            return result
        except Exception as e:
            logger.error(f"Error running git command: {e}")
            raise
    
    def get_file_path(self, dish_id: int, dish_name: str, ttk_id: int = None, ttk_name: str = None) -> Path:
        """
        Возвращает путь к файлу ТТК в репозитории.
        
        Args:
            dish_id: ID блюда
            dish_name: Название блюда
            ttk_id: ID ТТК (для создания уникального файла)
            ttk_name: Название ТТК (для создания уникального файла)
        
        Returns:
            Path к файлу ТТК
        """
        # Создаем безопасное имя файла
        safe_name = "".join(c for c in dish_name if c.isalnum() or c in (' ', '-', '_')).strip()
        safe_name = safe_name.replace(' ', '_')
        
        # Если указан ttk_id или ttk_name, добавляем его к имени файла
        if ttk_id:
            filename = f"{dish_id}_{ttk_id}_{safe_name}.md"
        elif ttk_name:
            safe_ttk_name = "".join(c for c in ttk_name if c.isalnum() or c in (' ', '-', '_')).strip()
            safe_ttk_name = safe_ttk_name.replace(' ', '_')
            filename = f"{dish_id}_{safe_ttk_name}_{safe_name}.md"
        else:
            # Старый формат для обратной совместимости
            filename = f"{dish_id}_{safe_name}.md"
        
        return self.repo_path / 'ttk' / filename
    
    def read_file(self, dish_id: int, dish_name: str, ttk_id: int = None, ttk_name: str = None) -> Optional[str]:
        """
        Читает содержимое файла ТТК из репозитория.
        
        Args:
            dish_id: ID блюда
            dish_name: Название блюда
            ttk_id: ID ТТК (опционально)
            ttk_name: Название ТТК (опционально)
        
        Returns:
            Содержимое файла или None, если файл не найден
        """
        file_path = self.get_file_path(dish_id, dish_name, ttk_id=ttk_id, ttk_name=ttk_name)
        if file_path.exists():
            try:
                return file_path.read_text(encoding='utf-8')
            except Exception as e:
                logger.error(f"Error reading file {file_path}: {e}")
                return None
        return None
    
    def write_file(self, dish_id: int, dish_name: str, content: str, commit_message: str, author_name: Optional[str] = None, author_email: Optional[str] = None, ttk_id: int = None, ttk_name: str = None) -> bool:
        """
        Записывает содержимое в файл ТТК и создает коммит.
        
        Args:
            dish_id: ID блюда
            dish_name: Название блюда
            content: Содержимое файла
            commit_message: Сообщение коммита
            author_name: Имя автора (опционально)
            author_email: Email автора (опционально)
            ttk_id: ID ТТК (опционально)
            ttk_name: Название ТТК (опционально)
        
        Returns:
            True если успешно, False в противном случае
        """
        file_path = self.get_file_path(dish_id, dish_name, ttk_id=ttk_id, ttk_name=ttk_name)
        
        # Создаем директорию, если её нет
        file_path.parent.mkdir(parents=True, exist_ok=True)
        
        try:
            # Записываем файл
            file_path.write_text(content, encoding='utf-8')
            
            # Добавляем в Git
            self._run_git(['add', str(file_path.relative_to(self.repo_path))])
            
            # Создаем коммит с указанным автором
            commit_cmd = ['commit', '-m', commit_message]
            if author_name and author_email:
                commit_cmd.extend(['--author', f'{author_name} <{author_email}>'])
            
            result = self._run_git(commit_cmd)
            
            if result.returncode == 0:
                logger.info(f"Файл {file_path} успешно закоммичен: {commit_message}")
                # Пытаемся отправить в GitHub автоматически
                try:
                    # Сначала получаем изменения из GitHub
                    fetch_result = self._run_git(['fetch', 'origin'])
                    # Пытаемся синхронизировать (pull с rebase)
                    pull_result = self._run_git(['pull', '--rebase', 'origin', 'main'])
                    if pull_result.returncode != 0:
                        # Если rebase не удался, пробуем обычный pull
                        pull_result = self._run_git(['pull', 'origin', 'main', '--no-edit'])
                    
                    # Теперь отправляем
                    push_result = self._run_git(['push', 'origin', 'main'])
                    if push_result.returncode == 0:
                        logger.info(f"Коммит успешно отправлен в GitHub")
                    else:
                        logger.warning(f"Не удалось отправить коммит в GitHub: {push_result.stderr}")
                except Exception as e:
                    logger.warning(f"Ошибка при отправке коммита в GitHub: {e}")
                return True
            else:
                # Возможно, изменений не было
                logger.warning(f"Коммит не создан (возможно, изменений не было): {result.stderr}")
                return True  # Файл записан, даже если коммит не создан
        except Exception as e:
            logger.error(f"Error writing file {file_path}: {e}")
            return False
    
    def get_file_history(self, dish_id: int, dish_name: str, limit: int = 10, ttk_id: int = None, ttk_name: str = None) -> List[Dict]:
        """
        Получает историю изменений файла ТТК из Git.
        
        Args:
            dish_id: ID блюда
            dish_name: Название блюда
            limit: Максимальное количество записей
            ttk_id: ID ТТК (опционально)
            ttk_name: Название ТТК (опционально)
        
        Returns:
            Список словарей с информацией о коммитах
        """
        file_path = self.get_file_path(dish_id, dish_name, ttk_id=ttk_id, ttk_name=ttk_name)
        relative_path = file_path.relative_to(self.repo_path)
        
        if not file_path.exists():
            return []
        
        # Получаем историю коммитов
        result = self._run_git([
            'log',
            f'-{limit}',
            '--pretty=format:%H|%an|%ae|%ad|%s',
            '--date=iso',
            str(relative_path)
        ])
        
        if result.returncode != 0 or not result.stdout.strip():
            return []
        
        history = []
        for line in result.stdout.strip().split('\n'):
            if not line:
                continue
            parts = line.split('|', 4)
            if len(parts) == 5:
                commit_hash, author_name, author_email, date_str, message = parts
                try:
                    commit_date = datetime.fromisoformat(date_str.replace(' +', '+').replace(' -', '-'))
                except:
                    commit_date = datetime.now()
                
                history.append({
                    'hash': commit_hash,
                    'author_name': author_name,
                    'author_email': author_email,
                    'date': commit_date,
                    'message': message,
                })
        
        return history
    
    def get_file_at_commit(self, dish_id: int, dish_name: str, commit_hash: str) -> Optional[str]:
        """
        Получает содержимое файла на момент указанного коммита.
        
        Args:
            dish_id: ID блюда
            dish_name: Название блюда
            commit_hash: Хеш коммита
        
        Returns:
            Содержимое файла или None
        """
        file_path = self.get_file_path(dish_id, dish_name)
        relative_path = file_path.relative_to(self.repo_path)
        
        result = self._run_git(['show', f'{commit_hash}:{relative_path}'])
        
        if result.returncode == 0:
            return result.stdout
        return None
    
    def get_diff(self, dish_id: int, dish_name: str, commit_hash1: Optional[str] = None, commit_hash2: Optional[str] = None) -> Optional[str]:
        """
        Получает diff между двумя версиями файла.
        
        Args:
            dish_id: ID блюда
            dish_name: Название блюда
            commit_hash1: Хеш первого коммита (если None, то текущая версия)
            commit_hash2: Хеш второго коммита (если None, то предыдущий коммит)
        
        Returns:
            Diff в виде строки или None
        """
        file_path = self.get_file_path(dish_id, dish_name)
        relative_path = file_path.relative_to(self.repo_path)
        
        if commit_hash1 and commit_hash2:
            result = self._run_git(['diff', commit_hash1, commit_hash2, '--', str(relative_path)])
        elif commit_hash1:
            result = self._run_git(['diff', commit_hash1, '--', str(relative_path)])
        else:
            result = self._run_git(['diff', 'HEAD~1', 'HEAD', '--', str(relative_path)])
        
        if result.returncode == 0 and result.stdout:
            return result.stdout
        return None
    
    def file_exists(self, dish_id: int, dish_name: str) -> bool:
        """
        Проверяет, существует ли файл ТТК.
        
        Args:
            dish_id: ID блюда
            dish_name: Название блюда
        
        Returns:
            True если файл существует
        """
        file_path = self.get_file_path(dish_id, dish_name)
        return file_path.exists()

