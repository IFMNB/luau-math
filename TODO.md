## PLANNED

Stack-buffer (LIFO)
    -- Извлечение только с конца

Queue-buffer (FIFO)
    -- Извлечение только с начала

## CHANGE

### Array-buffer

-- Позволить пользователям переопределять стандартный размер слота
    --> Разрешить пользователям создавать buffer/string arrays
        | Стандартный размер 64 байта на 1 слот

-- Добавить функционал:

```luau
    
    type todo = {
        read fill: <T>(of: Array<T>, from_pos: number, to_pos: number, value: T) -> (),
        read insert: <T>(of: Array<T>, value: T, pos: number?) -> number, -- pos
        read remove: <T>(of: Array<T>, pos: number?) -> boolean,
        read find: <T>(of: Array<T>, value: T?) -> number, -- pos
        read expand: <T>(of: Array<T>, new_max: number) -> Array<T>, -- новый array заполнен теми же значениями, но расширен размер
    }
```

-- Добавить настройку `SETTINGS_CONVERT`
    | `array.read()` сможет возвращать raw информацию без конвертации в `array.type()` значение