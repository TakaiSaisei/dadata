# Contributing Guidelines | Руководство по участию в разработке

[English](#english) | [Русский](#russian)

---

<a name="russian"></a>
# Руководство по участию в разработке

## Структура веток

Проект использует следующую структуру веток:

- `main` - основная ветка, содержащая только релизы с чистой историей коммитов
- `next` - ветка разработки, интеграционная ветка для новых функций
- `vX.Y.Z` - ветки для поддержки предыдущих мажорных версий (например, `v1.0.0`)
- `feature/*` - ветки для разработки новых функций
- `fix/*` - ветки для исправления ошибок
- `refactor/*` - ветки для рефакторинга кода

## Процесс разработки

1. **Начало работы над новой функцией**:
   ```bash
   git checkout next           # Переключаемся на ветку next
   git pull                   # Получаем последние изменения
   git checkout -b feature/X  # Создаем новую ветку для функции
   ```

2. **Разработка**:
   - Следуйте стилю кода проекта
   - Добавляйте тесты для новой функциональности
   - Используйте [Conventional Commits](https://www.conventionalcommits.org/) для сообщений коммитов

3. **Интеграция**:
   ```bash
   git checkout next          # Переключаемся на next
   git pull                  # Получаем последние изменения
   git merge feature/X       # Интегрируем новую функцию
   ```

4. **Подготовка релиза**:
   - Обновите CHANGELOG.md
   - Обновите версию в lib/dadata/version.rb
   - Обновите документацию

5. **Релиз**:
   ```bash
   git checkout main         # Переключаемся на main
   git merge --squash next  # Сливаем изменения из next с объединением коммитов
   git commit -m "..."      # Создаем релизный коммит
   git tag vX.Y.Z          # Создаем тег для версии
   ```

6. **После релиза**:
   ```bash
   git checkout next        # Переключаемся на next
   git reset --hard main   # Синхронизируем next с main
   ```

## Правила именования коммитов

Используйте [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - новая функциональность
- `fix:` - исправление ошибок
- `docs:` - изменения в документации
- `style:` - форматирование, отступы и т.д.
- `refactor:` - рефакторинг кода
- `test:` - добавление или изменение тестов
- `chore:` - обслуживание кода

Для breaking changes добавляйте `!` и описание в теле коммита:
```
feat!: изменение API клиента

BREAKING CHANGE: Изменен способ инициализации клиента
```

---

<a name="english"></a>
# Contributing Guidelines

## Branch Structure

The project uses the following branch structure:

- `main` - main branch containing only releases with clean commit history
- `next` - development branch, integration branch for new features
- `vX.Y.Z` - branches for supporting previous major versions (e.g., `v1.0.0`)
- `feature/*` - branches for new feature development
- `fix/*` - branches for bug fixes
- `refactor/*` - branches for code refactoring

## Development Process

1. **Starting a New Feature**:
   ```bash
   git checkout next           # Switch to next branch
   git pull                   # Get latest changes
   git checkout -b feature/X  # Create new feature branch
   ```

2. **Development**:
   - Follow the project's code style
   - Add tests for new functionality
   - Use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages

3. **Integration**:
   ```bash
   git checkout next          # Switch to next
   git pull                  # Get latest changes
   git merge feature/X       # Integrate new feature
   ```

4. **Release Preparation**:
   - Update CHANGELOG.md
   - Update version in lib/dadata/version.rb
   - Update documentation

5. **Release**:
   ```bash
   git checkout main         # Switch to main
   git merge --squash next  # Merge changes from next with squash
   git commit -m "..."      # Create release commit
   git tag vX.Y.Z          # Create version tag
   ```

6. **Post-Release**:
   ```bash
   git checkout next        # Switch to next
   git reset --hard main   # Sync next with main
   ```

## Commit Naming Rules

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - new feature
- `fix:` - bug fix
- `docs:` - documentation changes
- `style:` - formatting, indentation, etc.
- `refactor:` - code refactoring
- `test:` - adding or modifying tests
- `chore:` - code maintenance

For breaking changes, add `!` and description in commit body:
```
feat!: change client API

BREAKING CHANGE: Changed client initialization method
```
