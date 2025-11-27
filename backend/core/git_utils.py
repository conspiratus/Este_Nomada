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
            # Устанавливаем переменные окружения для Git
            env = os.environ.copy()
            env['GIT_TERMINAL_PROMPT'] = '0'  # Отключаем интерактивные запросы
            env['GIT_ASKPASS'] = ''  # Отключаем запрос пароля
            env['GIT_CONFIG_NOSYSTEM'] = '1'  # Не используем системный конфиг
            
            result = subprocess.run(
                full_cmd,
                cwd=cwd,
                capture_output=True,
                text=True,
                check=False,
                encoding='utf-8',
                env=env,
                timeout=30  # Таймаут 30 секунд
            )
            if result.returncode != 0:
                logger.warning(f"Git command failed: {' '.join(full_cmd)}\nError: {result.stderr}\nOutput: {result.stdout}")
            return result
        except subprocess.TimeoutExpired:
            logger.error(f"Git command timeout: {' '.join(full_cmd)}")
            raise
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
        # Сначала пробуем найти файл с ttk_id (новый формат)
        if ttk_id or ttk_name:
            file_path = self.get_file_path(dish_id, dish_name, ttk_id=ttk_id, ttk_name=ttk_name)
            if file_path.exists():
                try:
                    logger.info(f"Найден файл ТТК (новый формат): {file_path}")
                    return file_path.read_text(encoding='utf-8')
                except Exception as e:
                    logger.error(f"Error reading file {file_path}: {e}")
        
        # Если не найден, пробуем старый формат (без ttk_id) для обратной совместимости
        file_path_old = self.get_file_path(dish_id, dish_name, ttk_id=None, ttk_name=None)
        if file_path_old.exists():
            try:
                logger.info(f"Найден файл ТТК (старый формат): {file_path_old}")
                return file_path_old.read_text(encoding='utf-8')
            except Exception as e:
                logger.error(f"Error reading file {file_path_old}: {e}")
        
        logger.warning(f"Файл ТТК не найден. Пробовали: {file_path if (ttk_id or ttk_name) else 'N/A'} и {file_path_old}")
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
            # Проверяем, изменился ли файл
            file_changed = True
            if file_path.exists():
                old_content = file_path.read_text(encoding='utf-8')
                if old_content == content:
                    logger.info(f"Файл {file_path} не изменился, пропускаем коммит")
                    file_changed = False
                else:
                    logger.info(f"Файл {file_path} изменен, создаю коммит")
            else:
                logger.info(f"Создаю новый файл {file_path}")
            
            # Записываем файл
            file_path.write_text(content, encoding='utf-8')
            
            if not file_changed:
                logger.info(f"Файл не изменился, коммит не требуется")
                return True  # Файл записан, но коммит не нужен
            
            # Добавляем в Git
            relative_path = str(file_path.relative_to(self.repo_path))
            logger.info(f"Добавляю файл в Git: {relative_path}")
            add_result = self._run_git(['add', relative_path])
            if add_result.returncode != 0:
                logger.error(f"❌ Ошибка при добавлении файла в Git: {add_result.stderr}")
                # Пробуем добавить через абсолютный путь
                logger.info(f"Пробую добавить через абсолютный путь...")
                add_result2 = self._run_git(['add', str(file_path)])
                if add_result2.returncode != 0:
                    logger.error(f"❌ Ошибка при добавлении через абсолютный путь: {add_result2.stderr}")
                    return False
            
            # Проверяем, что файл действительно добавлен
            status_result = self._run_git(['status', '--porcelain', relative_path])
            if relative_path not in status_result.stdout:
                logger.warning(f"Файл не в staged area после add, пробую еще раз...")
                self._run_git(['add', '-f', relative_path])  # Force add
            
            # Создаем коммит с указанным автором
            commit_cmd = ['commit', '-m', commit_message]
            if author_name and author_email:
                commit_cmd.extend(['--author', f'{author_name} <{author_email}>'])
            
            logger.info(f"Создаю коммит: {commit_message[:50]}...")
            result = self._run_git(commit_cmd)
            logger.info(f"Результат коммита: код={result.returncode}")
            if result.returncode != 0:
                logger.error(f"❌ Ошибка при создании коммита: {result.stderr}")
                # Проверяем, может быть коммит уже существует или нет изменений
                if "nothing to commit" in result.stderr.lower() or "no changes" in result.stderr.lower():
                    logger.info(f"Нет изменений для коммита (возможно, файл уже закоммичен)")
                    return True  # Это не критичная ошибка
                return False
            
            if result.returncode == 0:
                logger.info(f"Файл {file_path} успешно закоммичен: {commit_message}")
                # Пытаемся отправить в GitHub автоматически
                try:
                    # Сначала получаем изменения из GitHub
                    fetch_result = self._run_git(['fetch', 'origin', '--force'])
                    logger.info(f"Fetch выполнен: {fetch_result.returncode}")
                    
                    # Проверяем, есть ли расхождение истории
                    check_result = self._run_git(['rev-list', '--count', 'HEAD..origin/main'])
                    behind_count = check_result.stdout.strip() if check_result.returncode == 0 else "0"
                    
                    check_result = self._run_git(['rev-list', '--count', 'origin/main..HEAD'])
                    ahead_count = check_result.stdout.strip() if check_result.returncode == 0 else "0"
                    
                    logger.info(f"История: behind={behind_count}, ahead={ahead_count}")
                    
                    # Если мы позади, сначала делаем pull
                    if behind_count != "0":
                        logger.info(f"Есть удаленные изменения, делаю pull...")
                        pull_result = self._run_git(['pull', '--rebase', 'origin', 'main'])
                        if pull_result.returncode != 0:
                            logger.warning(f"Rebase не удался, пробую обычный pull: {pull_result.stderr}")
                            pull_result = self._run_git(['pull', 'origin', 'main', '--no-edit'])
                            if pull_result.returncode != 0:
                                logger.error(f"Pull не удался: {pull_result.stderr}")
                    
                    # Теперь отправляем
                    logger.info(f"Отправляю коммит в GitHub...")
                    push_result = self._run_git(['push', 'origin', 'main'])
                    if push_result.returncode == 0:
                        logger.info(f"✅ Коммит успешно отправлен в GitHub")
                    else:
                        logger.error(f"❌ Не удалось отправить коммит в GitHub. Код: {push_result.returncode}, Ошибка: {push_result.stderr}")
                        # Пробуем force push только если это критично (не рекомендуется)
                        if "non-fast-forward" in push_result.stderr.lower():
                            logger.warning(f"Пробую force push (опасно!)...")
                            force_push = self._run_git(['push', '--force', 'origin', 'main'])
                            if force_push.returncode == 0:
                                logger.warning(f"✅ Force push выполнен успешно")
                            else:
                                logger.error(f"❌ Force push тоже не удался: {force_push.stderr}")
                except Exception as e:
                    logger.error(f"❌ Ошибка при отправке коммита в GitHub: {e}", exc_info=True)
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
        # Пытаемся найти файл в новом формате (с ttk_id)
        file_path = self.get_file_path(dish_id, dish_name, ttk_id=ttk_id, ttk_name=ttk_name)
        relative_path = file_path.relative_to(self.repo_path)
        
        # Если файл не найден в новом формате, пробуем старый формат
        if not file_path.exists() and ttk_id:
            file_path_old = self.get_file_path(dish_id, dish_name, ttk_id=None, ttk_name=None)
            if file_path_old.exists():
                file_path = file_path_old
                relative_path = file_path.relative_to(self.repo_path)
        
        if not file_path.exists():
            logger.warning(f"Файл ТТК не найден для истории: {file_path}")
            return []
        
        # Получаем историю коммитов для обоих форматов файла
        paths_to_check = [str(relative_path)]
        if ttk_id:
            # Также проверяем старый формат
            old_path = self.get_file_path(dish_id, dish_name, ttk_id=None, ttk_name=None).relative_to(self.repo_path)
            if str(old_path) != str(relative_path) and (self.repo_path / old_path).exists():
                paths_to_check.append(str(old_path))
        
        all_history = []
        seen_hashes = set()
        
        for path in paths_to_check:
            result = self._run_git([
                'log',
                f'-{limit * 2}',  # Берем больше, чтобы учесть оба формата
                '--pretty=format:%H|%an|%ae|%ad|%s',
                '--date=iso',
                '--',
                path
            ])
            
            if result.returncode == 0 and result.stdout.strip():
                for line in result.stdout.strip().split('\n'):
                    if not line:
                        continue
                    parts = line.split('|', 4)
                    if len(parts) == 5:
                        commit_hash = parts[0]
                        if commit_hash not in seen_hashes:
                            seen_hashes.add(commit_hash)
                            all_history.append(line)
        
        if not all_history:
            return []
        
        # Ограничиваем количество и сортируем по дате (новые первыми)
        history = []
        for line in all_history[:limit]:
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
        
        # Сортируем по дате (новые первыми)
        history.sort(key=lambda x: x['date'], reverse=True)
        return history[:limit]
    
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

