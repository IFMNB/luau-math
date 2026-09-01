--!strict
--!native
--!optimize 2

export type BitMap = buffer

export type Library = {
	read get: (of: BitMap, index: number, offset: number?) -> boolean,
	read set: (of: BitMap, index: number, offset: number?) -> (),
	read toggle: (of: BitMap, index: number, offset: number?) -> (),

	read clear: (of: BitMap, index: number, offset: number?) -> (),
	read find: (of: BitMap, from: number?, to: number?, offset: number?, inverse: boolean?) -> number?,
	read find_free: (of: BitMap, from: number?, to: number?, offset: number?, inverse: boolean?) -> number?,
}

const BYTE_BITS = 8
const BYTE_MASK = 0xFF

const function range_mask(first: number, last: number): number
	local mask = BYTE_MASK

	if first > 0 then
		mask = bit32.band(mask, bit32.bnot(bit32.lshift(1, first) - 1))
	end

	if last < 7 then
		mask = bit32.band(mask, bit32.lshift(1, last + 1) - 1)
	end

	return mask
end

const library: Library = table.freeze {
	get = function(of: BitMap, index: number, offset: number?): boolean
		return bit32.band(buffer.readu8(of, math.floor(index / BYTE_BITS) + (offset or 0)),  bit32.lshift(1, index % BYTE_BITS)) ~= 0
	end,

	set = function(of: BitMap, index: number, offset: number?): ()
		const byte = math.floor(index / BYTE_BITS) + (offset or 0)
		const value = buffer.readu8(of, byte)

		buffer.writeu8(of, byte, bit32.bor(value, bit32.lshift(1, index % BYTE_BITS)))
	end,

	toggle = function(of: BitMap, index: number, offset: number?): ()
		const byte = math.floor(index / BYTE_BITS) + (offset or 0)
		const value = buffer.readu8(of, byte)

		buffer.writeu8(of, byte, bit32.bxor(value,  bit32.lshift(1, index % BYTE_BITS)))
	end,

	clear = function(of: BitMap, index: number, offset: number?): ()
		const byte = math.floor(index / BYTE_BITS) + (offset or 0)
		const value = buffer.readu8(of, byte)

		buffer.writeu8(of, byte, bit32.band(value, bit32.bnot( bit32.lshift(1, index % BYTE_BITS))))
	end,

	find = function(of: BitMap, from: number?, to: number?, offset: number?, inverse: boolean?): number?
		offset = offset or 0

		const max = buffer.len(of) * BYTE_BITS - 1
		const first = from and from > 0 and from or 0
		const last = math.min(to or max, max)

		if first > last then
			return nil
		end

		const first_byte = math.floor(first / BYTE_BITS)
		const last_byte = math.floor(last / BYTE_BITS)

		if not inverse then
			for byte = first_byte, last_byte do
				const value = bit32.band(
					buffer.readu8(of, byte + offset),
					range_mask(
						if byte == first_byte then first % BYTE_BITS else 0,
						if byte == last_byte then last % BYTE_BITS else 7
					)
				)

				if value ~= 0 then
					return byte * BYTE_BITS + bit32.countrz(value)
				end
			end
		else
			for byte = last_byte, first_byte, -1 do
				const value = bit32.band(
					buffer.readu8(of, byte + offset),
					range_mask(
						if byte == first_byte then first % BYTE_BITS else 0,
						if byte == last_byte then last % BYTE_BITS else 7
					)
				)

				if value ~= 0 then
					return byte * BYTE_BITS + (7 - bit32.countlz(value))
				end
			end
		end


		return nil
	end,

	find_free = function(of: BitMap, from: number?, to: number?, offset: number?, inverse: boolean?): number?
		offset = offset or 0

		const max = buffer.len(of) * BYTE_BITS - 1
	    const first = from and from > 0 and from or 0
		const last = math.min(to or max, max)

		if first > last then
			return nil
		end

        const first_byte = math.floor(first / BYTE_BITS)
        const last_byte = math.floor(last / BYTE_BITS)

		if not inverse then
			for byte = first_byte, last_byte do
				const value = buffer.readu8(of, byte + offset)
				const low = if byte == first_byte then first % BYTE_BITS else 0
				const high = if byte == last_byte then last % BYTE_BITS else 7
				const mask = range_mask(low, high)
				const free = bit32.band(bit32.bnot(value), mask)

				if free ~= 0 then
					return byte * BYTE_BITS + bit32.countrz(free)
				end
			end
		else
			for byte = last_byte, first_byte, -1 do
				const value = buffer.readu8(of, byte + offset)

				const low = if byte == first_byte then first % BYTE_BITS else 0
				const high = if byte == last_byte then last % BYTE_BITS else 7

				const mask = range_mask(low, high)
				const free = bit32.band(bit32.bnot(value), mask)

				if free ~= 0 then
					return byte * BYTE_BITS + (7 - bit32.countlz(free))
				end
			end
		end

		return nil
	end,
}

return library