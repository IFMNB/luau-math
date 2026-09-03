## PLANNED

Stack-buffer (LIFO)
-- Extraction only from the end

Queue-buffer (FIFO)
-- Extraction only from the beginning

## CHANGE

### Array-buffer

-- Allow users to override the default slot size
--> Allow users to create buffer/string arrays
| Default size: 64 bytes per slot

-- Add the following functionality:

```luau
    
    type todo = {
        read fill: <T>(of: Array<T>, from_pos: number, to_pos: number, value: T) -> (),
        read insert: <T>(of: Array<T>, value: T, pos: number?) -> number, -- pos
        read remove: <T>(of: Array<T>, pos: number?) -> boolean,
        read find: <T>(of: Array<T>, value: T?) -> number, -- pos
        read expand: <T>(of: Array<T>, new_max: number) -> Array<T>, -- new array filled with the same values, but with an increased size
    }
```

-- Add `SETTINGS_CONVERT` setting
| `array.read()` will be able to return raw information without converting it to an `array.type()` value
