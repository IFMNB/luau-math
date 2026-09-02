--!strict
--!native
--!optimize 2
const bitmap = require("./bitmap")

-- TODO

export type supported = number | nil | boolean | string | vector | Array
export type supported_types = "integer" | "boolean" | "vector" | "float" | "number" | "normal"
export type array_settings = "freeze" | "spoof"

type Byte = number
type Index = number
type Type = number

export type Integer = number
export type Float = number

export type Array<T = supported> = buffer
export type Library = {
	read create: <T>(of: supported_types, max: number?) -> Array<T>,

	read read: <T>(of: Array<T>, pos: number?) -> T?,
	read write: <T>(of: Array<T>, pos: number?, value: T?) -> (),

	read insert: <T>(of: Array<T>, value: T?, pos: number?) -> (),
	read remove: <T>(of: Array<T>, pos: number?) -> (),

	read put: <T>(of: Array<T>, value: T, inverse: boolean?) -> (),
	read pick: <T>(of: Array<T>, inverse: boolean?) -> T?,

	read next: <T>(of: Array<T>, pos: number?) -> (number?, T),

	read type: <T>(of: Array<T>) -> supported_types,
	read max: <T>(of: Array<T>) -> number,
	read count: <T>(of: Array<T>) -> number,
	read size: <T>(of: Array<T>, slot: boolean?) -> number,
	read set: <T>(of: Array<T>, setting: array_settings, to: boolean) -> (),
    read get: <T>(of: Array<T>, setting: array_settings) -> boolean,
    read header: <T>(of: Array<T>) -> number,
}

--[=[   schematic

    sizeof <T> (u8)
    max <T> (u32)
    count <T> (u32)
    type <T> (u8)
    bitmap ceil N/8
    ... = <T>

    normal
        u32
        next

    vector
        f32
        f32
        f32
        next

    boolean (bitmap)
        null
        next

    integer
        u32
        next

    float
        f32
        next

    buffer

    
]=]

const STATIC_SIZE_SLOT_VECTOR: Byte = 12 -- f32 (1/3)
const STATIC_SIZE_SLOT_NORMAL: Byte = 4 -- u32 (rad f32 }{ f32)
const STATIC_SIZE_SLOT_BOOLEAN: Byte = 1 -- bitmap
const STATIC_SIZE_SLOT_INTEGER: Byte = 4
const STATIC_SIZE_SLOT_FLOAT: Byte = 4 -- f32 TODO f16

const ARRAY_SETTINGS: Index = 0
const SETTINGS_FREEZE: Index = 0
const SETTINGS_NULLIFE: Index = 1
const SETTINGS_SPOOF: Index = 2

const ARRAY_TYPE: Index = 1
const ARRAY_MAX: Index = 5
const ARRAY_COUNT: Index = 9
const ARRAY_BITMAP: Index = 13
const ARRAY_STATIC_PART_ENDS_AT: Index = ARRAY_BITMAP

const LIBRARY_INDEX_STARTS_AT = 1
const LIBRARY_DEFAULT_MAX = LIBRARY_INDEX_STARTS_AT + 1
const LIBRARY_OFFSET_AFTER_HEADER: Index = 0
const LIBRARY_OFFSET_BITMAP = ARRAY_BITMAP

const TYPE_VECTOR: Type = 0
const TYPE_INTEGER: Type = 1
const TYPE_FLOAT: Type = 6
const TYPE_BOOLEAN: Type = 3
const TYPE_STRING: Type = 5
const TYPE_DOUBLE: Type = 7
const TYPE_NORMAL: Type = 8

const STYPE_VECTOR: "vector" = "vector"
const STYPE_STRING: "string" = "string"
const STYPE_NUMBER: "double" = "double"
const STYPE_FLOAT: "float" = "float"
const STYPE_INTEGER: "integer" = "integer"
const STYPE_NORMAL: "normal" = "normal"
const STYPE_BOOLEAN: "boolean" = "boolean"

const MAP = table.freeze({
	[STYPE_VECTOR] = TYPE_VECTOR,
	[STYPE_STRING] = TYPE_STRING,
	[STYPE_NUMBER] = TYPE_DOUBLE,
	[STYPE_INTEGER] = TYPE_INTEGER,
	[STYPE_FLOAT] = TYPE_FLOAT,
	[STYPE_BOOLEAN] = TYPE_BOOLEAN,
    [STYPE_NORMAL] = TYPE_NORMAL,

	[TYPE_BOOLEAN] = STATIC_SIZE_SLOT_BOOLEAN,
	[TYPE_FLOAT] = STATIC_SIZE_SLOT_FLOAT,
	[TYPE_INTEGER] = STATIC_SIZE_SLOT_INTEGER,
	[TYPE_VECTOR] = STATIC_SIZE_SLOT_VECTOR,
    [TYPE_NORMAL] = STATIC_SIZE_SLOT_NORMAL,
    
    [tostring(TYPE_BOOLEAN)] = STYPE_BOOLEAN,
    [tostring(TYPE_FLOAT)] = STYPE_FLOAT,
    [tostring(TYPE_INTEGER)] = STYPE_INTEGER,
    [tostring(TYPE_DOUBLE)] = STYPE_NUMBER,
    [tostring(TYPE_NORMAL)] = STYPE_NORMAL,
    [tostring(TYPE_VECTOR)] = STYPE_VECTOR,
    [tostring(TYPE_STRING)] = STYPE_STRING,

    nullify = SETTINGS_NULLIFE,
    freeze = SETTINGS_FREEZE,
    spoof = SETTINGS_SPOOF
} :: { [string | number]: number })

local self: Library
const library: Library = {

	create = function<T>(of: supported_types, max: number?): Array<T>
		max = max or LIBRARY_DEFAULT_MAX
        assert(LIBRARY_INDEX_STARTS_AT < max, `count of maximum elements {max} cannot be used, because array size < {LIBRARY_INDEX_STARTS_AT}`)

		const array_type = assert(MAP[of], `cannot create array of {of}`)
		const array_bitmap_size = math.ceil(max / 8)

        local new: Array<T>

        if of == "boolean" then
            new = buffer.create(
                ARRAY_STATIC_PART_ENDS_AT +
                LIBRARY_OFFSET_AFTER_HEADER + 
                array_bitmap_size            
            )
        else
            new = buffer.create(
                ARRAY_STATIC_PART_ENDS_AT +
                LIBRARY_OFFSET_AFTER_HEADER + 
                array_bitmap_size + 
                MAP[array_type] * max
            )
        end


		buffer.writeu32(new, ARRAY_MAX, max)
		buffer.writeu32(new, ARRAY_COUNT, 0)
		buffer.writeu8(new, ARRAY_TYPE, array_type)

		return new
	end,

	read = function<T>(of: Array<T>, pos: number?): T?
        pos = pos or LIBRARY_INDEX_STARTS_AT
        assert(pos >= LIBRARY_INDEX_STARTS_AT, `position {pos} wasn't in the scope of {LIBRARY_INDEX_STARTS_AT}`)
        assert(pos <= self.max(of), `position {pos} quited of bounds`)

        const index: Index = pos - LIBRARY_INDEX_STARTS_AT
        const T: supported_types = self.type(of)

        if T == "boolean" then return bitmap.get(of, index, ARRAY_BITMAP) end
        if not bitmap.get(of, index, ARRAY_BITMAP) then
            if self.get(of, "spoof") then
                return self.read(of, math.random(LIBRARY_INDEX_STARTS_AT, self.max(of)))
            end
        end

        const label = index * MAP[MAP[T]]
        const offset = ARRAY_BITMAP + self.header(of)
        const sector = offset + label

        if T == "float" then return buffer.readf32(of, sector) end
        if T == "integer" then return buffer.readu32(of, sector) end
        if T == "number" then return buffer.readf64(of, sector) end

        if T == "normal" then 
            -- todo
        end

        if T == "vector" then
            const slot_size = STATIC_SIZE_SLOT_VECTOR / 3

            return vector.create(
                buffer.readf32(of, sector),
                buffer.readf32(of, sector + slot_size),
                buffer.readf32(of, sector + slot_size * 2)
            )
        end

        error(`cannot read value from this array, {T} is damaged or something unsupported right now`, 0)
    end,

	write = function<T>(of: Array<T>, pos: number?, value: supported?): ()
        pos = pos or LIBRARY_INDEX_STARTS_AT
        assert(pos >= LIBRARY_INDEX_STARTS_AT, `position {pos} wasn't in the scope of {LIBRARY_INDEX_STARTS_AT}`)
        assert(pos <= self.max(of), `position {pos} quited of bounds`)

        const index: Index = pos - LIBRARY_INDEX_STARTS_AT
        const T: supported_types = self.type(of)
        
        if value == nil then
            if bitmap.get(of, index, ARRAY_BITMAP) then
                buffer.writeu32(of, ARRAY_COUNT, self.count(of) - 1)
            end

            bitmap.clear(of, index, ARRAY_BITMAP)
        else
            if not bitmap.get(of, index, ARRAY_BITMAP) then
                buffer.writeu32(of, ARRAY_COUNT, self.count(of) + 1)
            end

            bitmap.set(of, index, ARRAY_BITMAP)
        end

        if T == 'boolean' then return end

        const label = index * MAP[MAP[T]]
        const offset = ARRAY_BITMAP + self.header(of)
        const sector = offset + label

        if T == "float" then buffer.writef32(of, sector, value :: number or 0); return end
        if T == "integer" then buffer.writeu32(of, sector, value :: number or 0); return end
        if T == "number" then buffer.writef64(of, sector, value :: number or 0); return end

        if T == "normal" then 
            -- todo
        end

        if T == "vector" then
            const slot_size = STATIC_SIZE_SLOT_VECTOR / 3
            const var = (value or vector.zero) :: vector

            buffer.writef32(of, sector, var.x)
            buffer.writef32(of, sector + slot_size, var.y)
            buffer.writef32(of, sector + slot_size * 2, var.z)

            return;
        end

        assert(type(value) == T, `received value {tostring(value)} isn't a part of expected type`)
        error(`cannot write value to this array, {T} is damaged or something unsupported right now`, 0)
	end,

	insert = function<T>(of: Array<T>, value: T?, pos: number?): ()
        
    end,

	remove = function<T>(of: Array<T>, pos: number?): () 
    
    end,

	pick = function<T>(of: Array<T>, inverse: boolean?): T?
		const index = bitmap.find(of, 0, self.max(of) - 1, LIBRARY_OFFSET_BITMAP, inverse)
		return index and self.read(of, index + 1) or nil
	end,

	put = function<T>(of: Array<T>, value: T, inverse: boolean?): ()
		const index = assert (bitmap.find_free(of, 0, self.max(of) - 1, LIBRARY_OFFSET_BITMAP, inverse), "array is full")
		self.write(of, index + 1, value)
	end,

	next = function<T>(of: Array<T>, previous: number?): (number?, T)
		const index = bitmap.find(of, previous or 0, self.max(of) - 1, LIBRARY_OFFSET_BITMAP)
		if not index then return nil, nil end

		const position = index + 1
		return position, self.read(of, position)
	end,

	type = function<T>(of: Array<T>): supported_types
        return assert(MAP[tostring(buffer.readu8(of, ARRAY_TYPE))], "cannot read type, array damaged") :: any
	end,

    max = function<T>(of: Array<T>): number return buffer.readu32(of, ARRAY_MAX) end,
	count = function<T>(of: Array<T>): number return buffer.readu32(of, ARRAY_COUNT) end,
	size = function<T>(of: Array<T>, slot: boolean?): number return slot and MAP[self.type(of)] or buffer.len(of) end,
	set = function<T>(of: Array<T>, setting: array_settings): () bitmap.set(of, assert(MAP[setting], `unknown {setting}`), ARRAY_SETTINGS) end,
    get = function<T>(of: Array<T>, setting: array_settings): boolean return bitmap.get(of, assert(MAP[setting], `unknown {setting}`), ARRAY_SETTINGS) end,
    header = function<T>(of: Array<T>): number return math.ceil(self.max(of) / 8) end
}

self = library
return library
