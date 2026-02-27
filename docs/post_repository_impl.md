⏺ PostRepositoryImpl — это реализация абстрактного PostRepository по паттерну Clean Architecture. Вот как он устроен:

  Зависимости

  Принимает три зависимости:
  - PostRemoteDataSource — сетевые запросы к Mattermost API (Dio)
  - PostLocalDataSource — локальный кэш (офлайн-хранилище)
  - NetworkInfo — проверка доступности сети

  Все методы возвращают Either<Failure, T> (из пакета dartz) — левая сторона для ошибок, правая для успеха.

  Ключевые методы и логика

  getChannelPosts — загрузка сообщений канала (строка 27)

  Самый сложный метод, трёхуровневая стратегия:
  1. Есть сеть → загружает с сервера, в фоне кэширует локально (cachePosts с catchError, чтобы ошибка кэша не сломала основной поток)
  2. Нет сети → читает из локального кэша
  3. Ошибка сервера (ServerException) → пробует локальный кэш как fallback; если кэш пуст — возвращает ServerFailure

  createPost — отправка сообщения (строка 74)

  Поддерживает офлайн-отправку:
  - Онлайн → отправляет через API, кэширует результат
  - Офлайн → создаёт Post с pendingId (формат pending_<timestamp>) и сохраняет через savePendingPost. userId оставляется пустым — заполнится при синхронизации

  editPost / deletePost (строки 127, 143)

  Работают только онлайн. После успеха обновляют/удаляют запись в локальном кэше в фоне.

  Простые прокси-методы

  Остальные методы (getPost, getPostThread, getFlaggedPosts, searchPosts, getPinnedPosts, pinPost, unpinPost, flagPost, unflagPost, getUserThreads) — это простые обёртки вокруг _remoteDataSource,
  которые ловят ServerException и оборачивают результат в Either.

  Паттерны

  - Фоновое кэширование: _localDataSource.cachePosts(...)catchError(...) — кэш обновляется асинхронно, ошибки логируются но не пробрасываются
  - Graceful degradation: при ошибках сети/сервера — fallback на кэш
  - Optimistic offline: при отправке офлайн сразу возвращается "pending" пост, чтобы UI не блокировался
