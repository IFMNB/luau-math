--!strict
--!native
--!optimize 2
const bitmap = require("./bitmap")

-- TODO

export type supported = number | nil | boolean | string | vector | Array
export type supported_types = "integer" | "boolean" | "vector" | "float" | "number"

type Byte = number
type Index = number
type Type = number

export type Integer = number
export type Float = number

export type Array<T = supported> = buffer
export type Library = {
    read create: <T> (of: supported_types, max: number?) -> Array<T>,

    read read: <T> (of: Array<T>, pos: number?) -> T?,
    read write: <T> (of: Array<T>, pos: number?, value: T?) -> (),

    read insert: <T> (of: Array<T>, value: T?, pos: number?) -> (),
    read remove: <T> (of: Array<T>, pos: number?) -> (),

    read put: <T> (of: Array<T>, value: T, inverse: boolean?) -> (),
    read pick: <T> (of: Array<T>, inverse: boolean?) -> T?,

    read max: <T> (of: Array<T>) -> number,
    read count: <T> (of: Array<T>) -> number,
    read next: <T> (of: Array<T>, pos: number?) -> (number?, T),
    read type: <T> (of: Array<T>) -> supported_types,
    read size: <T> (of: Array<T>, slot: boolean?) -> number
}


--[=[   schematic

    sizeof <T> (u8)
    max <T> (u32)
    count <T> (u32)
    type <T> (u8)
    bitmap ceil N/8
    ... = <T>
]=]

const STATIC_SIZE_SLOT_VECTOR_COMPONENT: Byte = 4 -- f32
const STATIC_SIZE_SLOT_BOOLEAN: Byte = 1 -- u8
const STATIC_SIZE_SLOT_NIL: Byte = 0
const STATIC_SIZE_SLOT_INTEGER: Byte = 4
const STATIC_SIZE_SLOT_CHARACTER: Byte = 4 -- u32
const STATIC_SIZE_SLOT_FLOAT: Byte = 4 -- f32 TODO f16
const STATIC_SIZE_SLOT_BUFFER: Byte = 64 ^2
const STATIC_SIZE_SLOT_STRING: Byte = 32

const ARRAY_SIZE_SLOT: Index = 0
const ARRAY_MAX: Index = 4
const ARRAY_COUNT: Index = 8
const ARRAY_TYPE: Index = 12
const ARRAY_BITMAP: Index = 13
const ARRAY_HEADER_SIZE: Byte = 13 -- ends at

const LIBRARY_OFFSET_AFTER_HEADER: Index = 0
const LIBRARY_OFFSET_BITMAP = ARRAY_HEADER_SIZE

const TYPE_VECTOR: Type = 0
const TYPE_INTEGER: Type = 1
const TYPE_FLOAT: Type = 6
const TYPE_BUFFER: Type = 2
const TYPE_BOOLEAN: Type = 3
const TYPE_NIL: Type = 4
const TYPE_STRING: Type = 5

const MAP = table.freeze({
	["buffer"] = TYPE_BUFFER,
    ["vector"] = TYPE_VECTOR,
	["string"] = TYPE_STRING,
	["number"] = TYPE_FLOAT,
	["integer"] = TYPE_INTEGER,
	["float"] = TYPE_FLOAT,
	["boolean"] = TYPE_BOOLEAN,
    TYPE_BOOLEAN = STATIC_SIZE_SLOT_BOOLEAN,
    TYPE_BUFFER = STATIC_SIZE_SLOT_BUFFER,
    TYPE_FLOAT = STATIC_SIZE_SLOT_FLOAT,
    TYPE_INTEGER = STATIC_SIZE_SLOT_INTEGER,
    TYPE_NIL = STATIC_SIZE_SLOT_NIL,
    TYPE_VECTOR = STATIC_SIZE_SLOT_VECTOR_COMPONENT,
    TYPE_STRING = STATIC_SIZE_SLOT_STRING
} :: {[string|number]: number})

local self: Library
const library: Library = {

    create = function <T> (of: supported_types, max: number?) : Array<T>
        max = if max then if max >= 1 then max else 1 else 1

        const array_type = assert (MAP[of], `cannot create array of {of}`)
        const array_bitmap_size = math.ceil(max / 8)
        const array_slot_size = MAP[array_type] * max

        const new = buffer.create(ARRAY_HEADER_SIZE + LIBRARY_OFFSET_AFTER_HEADER + array_bitmap_size + array_slot_size)

        buffer.writeu8(new, ARRAY_SIZE_SLOT, array_slot_size)
        buffer.writeu32(new, ARRAY_MAX, max)
        buffer.writeu32(new, ARRAY_COUNT, 0)
        buffer.writeu8(new, ARRAY_TYPE, array_type)
        
        return new
    end,

    read = function <T> (of: Array<T>, pos: number?): T?
        if pos then
            assert(pos <= self.max(of), "index went beyond the array boundary")
            assert(pos > LIBRARY_OFFSET_AFTER_HEADER, "index starts from the wrong position")
            pos = pos
        else
            pos = self.count(of) + 1
        end

	   
    end,

    write = function <T> (of: Array<T>, pos: number?, value: supported?) : ()  
	    pos = pos or self.count(of) + 1
        assert(pos >= 1 and pos <= self.max(of), "index out of bounds")

        const index = pos - 1

        if value == nil then
            if bitmap.get(of, index, LIBRARY_OFFSET_BITMAP) then
                bitmap.clear(of, index, LIBRARY_OFFSET_BITMAP)

                buffer.writeu32(of, ARRAY_COUNT, self.count(of) - 1)
            end

            return
        end

        if not bitmap.get(of, index, LIBRARY_OFFSET_BITMAP) then
            bitmap.set(of, index, LIBRARY_OFFSET_BITMAP)

            buffer.writeu32(of, ARRAY_COUNT, self.count(of) + 1)
        end
    end,

    insert = function <T> (of: Array<T>, value: T?, pos: number?): ()
        
    end,

    remove = function <T> (of: Array<T>, pos: number?): ()
        
    end,

    pick = function <T> (of: Array<T>, inverse: boolean?): T?
        const index = bitmap.find(of, 0, self.max(of) - 1, LIBRARY_OFFSET_BITMAP, inverse)

        if index == nil then
            return nil
        end

        return self.read(of, index + 1)
    end,

    put = function <T> (of: Array<T>, value: T, inverse: boolean?): ()
        const max = self.max(of)
        const index = bitmap.find_free(
            of,
            0,
            max - 1,
            LIBRARY_OFFSET_BITMAP,
            inverse
        )

        if index == nil then
            error("array is full", 2)
        end

        self.write(of, index + 1, value)
    end,

    max = function <T> (of: Array<T>) : number
	    return buffer.readu32(of, ARRAY_MAX)
    end,

    count = function <T> (of: Array<T>): number
        return buffer.readu32(of, ARRAY_COUNT)
    end,

    next = function <T> (of: Array<T>, previous: number?) : (number?, T)
        const index = bitmap.find(of, previous or 0, self.max(of) - 1, LIBRARY_OFFSET_BITMAP)

        if not index then
            return nil, nil
        end

        const position = index + 1

        return position, self.read(of, position)
    end,

    type = function <T> (of: Array<T>): supported_types
        const array_type = buffer.readu8(of, ARRAY_TYPE)

        if array_type == TYPE_BOOLEAN then
            return "boolean"
        elseif array_type == TYPE_BUFFER then
            return "buffer"
        elseif array_type == TYPE_INTEGER then
            return "integer"
        elseif array_type == TYPE_FLOAT then
            return "float"
        elseif array_type == TYPE_STRING then
            return "string"
        elseif array_type == TYPE_VECTOR then
            return "vector"
        else
            error("cannot reach type in array", 0)
        end
    end,

    size = function <T> (of: Array<T>, slot: boolean?): number
        if slot then
            const array_size_slot = buffer.readu8(of, ARRAY_SIZE_SLOT)
            const T = self.type(of)

            if T == "vector" then
                return array_size_slot * 3
            else
                return array_size_slot
            end
        else
            return buffer.len(of)
        end
    end
}

self = library
return library