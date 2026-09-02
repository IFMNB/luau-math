--!strict
--!native
--!optimize 2
const bitmap = require("./bitmap")

-- TODO

export type supported = number | nil | boolean | string | vector | Array
export type supported_types = "integer" | "boolean" | "vector" | "float" | "number" | "normal" | "short"
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

	read put: <T>(of: Array<T>, value: T, inverse: boolean?) -> number,
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
        next-link u32
        data
        next

    string <-> buffer
    
]=]

const STATIC_SIZE_SLOT_VECTOR: Byte = 12 -- f32 (1/3)
const STATIC_SIZE_SLOT_NORMAL: Byte = 4 -- u32 (rad f32 }{ f32)
const STATIC_SIZE_SLOT_BOOLEAN: Byte = 1 -- bitmap storage unit (1 bit per element)
const STATIC_SIZE_SLOT_INTEGER: Byte = 4
const STATIC_SIZE_SLOT_FLOAT: Byte = 4 -- f32 TODO f16
const STATIC_SIZE_SLOT_SHORT: Byte = 2 -- u16

const WRITE_INTEGER = buffer.writei32
const WRITE_FLOAT = buffer.writef32
const WRITE_DOUBLE = buffer.writef64
const WRITE_VECTOR = buffer.writef32
const WRITE_NORMAL = buffer.writeu32
const WRITE_CHAR = buffer.writeu8
const WRITE_SHORT = buffer.writeu16

const READ_INTEGER = buffer.readi32
const READ_FLOAT = buffer.readf32
const READ_DOUBLE = buffer.readf64
const READ_VECTOR = buffer.readf32
const READ_NORMAL = buffer.readu32
const READ_CHAR = buffer.readu8
const READ_SHORT = buffer.readu16

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
const TYPE_SHORT: Type = 9

const STYPE_VECTOR: "vector" = "vector"
const STYPE_STRING: "string" = "string"
const STYPE_NUMBER: "double" = "double"
const STYPE_FLOAT: "float" = "float"
const STYPE_INTEGER: "integer" = "integer"
const STYPE_NORMAL: "normal" = "normal"
const STYPE_BOOLEAN: "boolean" = "boolean"
const STYPE_SHORT: "short" = "short"

const MAP = table.freeze({
	[STYPE_VECTOR] = TYPE_VECTOR,
	[STYPE_STRING] = TYPE_STRING,
	[STYPE_NUMBER] = TYPE_DOUBLE,
	[STYPE_INTEGER] = TYPE_INTEGER,
	[STYPE_FLOAT] = TYPE_FLOAT,
	[STYPE_BOOLEAN] = TYPE_BOOLEAN,
    [STYPE_NORMAL] = TYPE_NORMAL,
    [STYPE_SHORT] = TYPE_SHORT,

	[TYPE_BOOLEAN] = STATIC_SIZE_SLOT_BOOLEAN,
	[TYPE_FLOAT] = STATIC_SIZE_SLOT_FLOAT,
	[TYPE_INTEGER] = STATIC_SIZE_SLOT_INTEGER,
	[TYPE_VECTOR] = STATIC_SIZE_SLOT_VECTOR,
    [TYPE_NORMAL] = STATIC_SIZE_SLOT_NORMAL,
    [TYPE_SHORT] = STATIC_SIZE_SLOT_SHORT,

    [tostring(TYPE_BOOLEAN)] = STYPE_BOOLEAN,
    [tostring(TYPE_FLOAT)] = STYPE_FLOAT,
    [tostring(TYPE_INTEGER)] = STYPE_INTEGER,
    [tostring(TYPE_DOUBLE)] = STYPE_NUMBER,
    [tostring(TYPE_NORMAL)] = STYPE_NORMAL,
    [tostring(TYPE_VECTOR)] = STYPE_VECTOR,
    [tostring(TYPE_STRING)] = STYPE_STRING,
    [tostring(TYPE_SHORT)] = STYPE_SHORT,

    nullify = SETTINGS_NULLIFE,
    freeze = SETTINGS_FREEZE,
    spoof = SETTINGS_SPOOF
} :: { [string | number]: number })

local self: Library
const library: Library = {

	create = function<T>(of: supported_types, max: number?): Array<T>
		max = max or LIBRARY_DEFAULT_MAX
        assert(LIBRARY_INDEX_STARTS_AT < max, `count of maximum elements {max} cannot be used, because array size < {LIBRARY_INDEX_STARTS_AT}`)

		const array_type = assert(MAP[of], `cannot create array of {of}, because type is unsupported currently`)
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


		WRITE_INTEGER(new, ARRAY_MAX, max)
	    WRITE_INTEGER(new, ARRAY_COUNT, 0)
		WRITE_CHAR(new, ARRAY_TYPE, array_type)

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
                const bit_index = bitmap.find(of, 0, self.max(of) - LIBRARY_INDEX_STARTS_AT, ARRAY_BITMAP)

                if bit_index then
                    return self.read(of, bit_index + LIBRARY_INDEX_STARTS_AT)
                else
                    return nil
                end
            end
        end

        const label = index * MAP[MAP[T]]
        const offset = ARRAY_BITMAP + self.header(of)
        const sector = offset + label

        if T == "float" then return READ_FLOAT(of, sector) end
        if T == "integer" then return READ_INTEGER(of, sector) end
        if T == "short" then return READ_SHORT(of, sector) end
        if T == "number" then return READ_DOUBLE(of, sector) end

        if T == "normal" then 
            const p = READ_NORMAL(of, sector)
            const u = bit32.band(p, 0xFFFF)
            const v = bit32.rshift(p, 16)

            local x = u / 65535 * 2 - 1
            local y = v / 65535 * 2 - 1
            local z = 1 - math.abs(x) - math.abs(y)

            if z < 0 then
                const old_x = x
                const old_y = y

                x = (1 - math.abs(old_y)) * (old_x >= 0 and 1 or -1)
                y = (1 - math.abs(old_x)) * (old_y >= 0 and 1 or -1)
            end

            const length = math.sqrt(x*x + y*y + z*z)

            x /= length
            y /= length
            z /= length

            return vector.create(x, y, z)
        end

        if T == "vector" then
            const slot_size = STATIC_SIZE_SLOT_VECTOR / 3

            return vector.create(
                READ_VECTOR(of, sector),
                READ_VECTOR(of, sector + slot_size),
                READ_VECTOR(of, sector + slot_size * 2)
            )
        end

        error(`cannot read value from this array, {T} is damaged or something unsupported right now`, 0)
    end,

	write = function<T>(of: Array<T>, pos: number?, value: supported?): ()
        pos = pos or LIBRARY_INDEX_STARTS_AT
        assert(pos >= LIBRARY_INDEX_STARTS_AT, `position {pos} wasn't in the scope of {LIBRARY_INDEX_STARTS_AT}`)
        assert(pos <= self.max(of), `position {pos} quited of bounds`)
        assert(not self.get(of, "freeze"), "cannot write to frozen array")

        const index = pos - LIBRARY_INDEX_STARTS_AT
        const T = self.type(of)
        
        if value == nil then
            if bitmap.get(of, index, ARRAY_BITMAP) then
                WRITE_INTEGER(of, ARRAY_COUNT, self.count(of) - 1)
            end

            bitmap.clear(of, index, ARRAY_BITMAP)
        else
            if not bitmap.get(of, index, ARRAY_BITMAP) then
                WRITE_INTEGER(of, ARRAY_COUNT, self.count(of) + 1)
            end

            bitmap.set(of, index, ARRAY_BITMAP)
        end

        if T == 'boolean' then return end

        const label = index * MAP[MAP[T]]
        const offset = ARRAY_BITMAP + self.header(of)
        const sector = offset + label

        if T == "float" then WRITE_FLOAT(of, sector, value :: number or 0); return end
        if T == "integer" then WRITE_INTEGER(of, sector, value :: number or 0); return end
        if T == "number" then WRITE_DOUBLE(of, sector, value :: number or 0); return end
        if T == "short" then WRITE_SHORT(of, sector, value :: number or 0); return end

        if T == "normal" then 
            const var = (value or vector.zero) :: vector
            const length = math.sqrt(var.x * var.x + var.y * var.y + var.z * var.z)

            local x = var.x / length
            local y = var.y / length
            local z = var.z / length

            const inv_l = 1 / (math.abs(x) + math.abs(y) + math.abs(z))
            x *= inv_l
            y *= inv_l
            z *= inv_l

            if z < 0 then
                const old = x
                x = (1 - math.abs(y)) * (old >= 0 and 1 or -1)
                y = (1 - math.abs(old)) * (y >= 0 and 1 or -1)
            end

            const u = math.round((x * 0.5 + 0.5) * 65535)
            const v = math.round((y * 0.5 + 0.5) * 65535)
            const p = bit32.bor(u,bit32.lshift(v, 16))

            WRITE_NORMAL(of, sector, p)
            return
        end

        if T == "vector" then
            const slot_size = STATIC_SIZE_SLOT_VECTOR / 3
            const var = (value or vector.zero) :: vector

            WRITE_VECTOR(of, sector, var.x)
            WRITE_VECTOR(of, sector + slot_size, var.y)
            WRITE_VECTOR(of, sector + slot_size * 2, var.z)

            return;
        end

        assert(type(value) == T, `received value {tostring(value)} isn't a part of expected type`)
        error(`cannot write value to this array, {T} is damaged or something unsupported right now`, 0)
	end,

	pick = function<T>(of: Array<T>, inverse: boolean?): T?
		const index = bitmap.find(of, 0, self.max(of) - 1, LIBRARY_OFFSET_BITMAP, inverse)
		return index and self.read(of, index + 1) or nil
	end,

	put = function<T>(of: Array<T>, value: T, inverse: boolean?): number
		const index = assert (bitmap.find_free(of, 0, self.max(of) - 1, LIBRARY_OFFSET_BITMAP, inverse), "array is full")
		const position = index + LIBRARY_INDEX_STARTS_AT
        self.write(of, position, value)
        return position
	end,

	next = function<T>(of: Array<T>, previous: number?): (number?, T)
		const index = bitmap.find(of, previous or 0, self.max(of) - 1, LIBRARY_OFFSET_BITMAP)
		if not index then return nil, nil end

		const position = index + 1
		return position, self.read(of, position)
	end,

	type = function<T>(of: Array<T>): supported_types
        return assert(MAP[tostring(READ_CHAR(of, ARRAY_TYPE))], "cannot read type, array damaged") :: any
	end,

    max = function<T>(of: Array<T>): number return READ_INTEGER(of, ARRAY_MAX) end,
	count = function<T>(of: Array<T>): number return READ_INTEGER(of, ARRAY_COUNT) end,
	size = function<T>(of: Array<T>, slot: boolean?): number return slot and MAP[self.type(of)] or buffer.len(of) end,
	set = function<T>(of: Array<T>, setting: array_settings, to: boolean): () assert(not self.get(of, "freeze"), "cannot modify frozen array"); if to then bitmap.set(of, assert(MAP[setting], `unknown {setting}`), ARRAY_SETTINGS) else bitmap.clear(of, assert(MAP[setting], `unknown {setting}`), ARRAY_SETTINGS) end end,
    get = function<T>(of: Array<T>, setting: array_settings): boolean return bitmap.get(of, assert(MAP[setting], `unknown setting {setting}`), ARRAY_SETTINGS) end,
    header = function<T>(of: Array<T>): number return math.ceil(self.max(of) / 8) end
}

self = library
return library
