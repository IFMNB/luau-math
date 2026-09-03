--!strict

--[==[
	NOTEPAD STATS
		i5-12450H
		RTX 4050
		64 GB RAM DDR5
		SATA SSD 1 TB SAMSUNG EVO 880

	~/G/L/L/s/bitmap main*
	❯ luau -g0 -O2 --codegen
	> require "./test"
	=== BITMAP TEST ===

	=== 1. BASIC OPERATIONS ===
	basic operations: OK

	=== 2. ALL BIT POSITIONS ===
	all 256 bits: OK

	=== 3. FIND FORWARD ===
	forward find: OK

	=== 4. FIND RANGE ===
	range find: OK

	=== 5. FIND INVERSE ===
	reverse find: OK

	=== 6. FIND FREE ===
	find_free forward: OK

	=== 7. FIND FREE RANGE ===
	find_free range: OK

	=== 8. FIND FREE INVERSE ===
	reverse find_free: OK

	=== 9. OFFSET ===
	offset: OK

	=== 10. OFFSET + FIND FREE ===
	offset find_free: OK

	=== 11. BOUNDARY TESTS ===
	boundaries: OK

	=== 12. EMPTY / INVALID RANGES ===
	empty/invalid ranges: OK

	=== 13. RANDOMIZED CORRECTNESS ===
	randomized correctness: OK

	=== 14. SET PERFORMANCE ===
	0.5616594180464745	time to set	50000000	bits
	bitmap physical size:	6250000	bytes (~5 MB)

	=== 15. GET PERFORMANCE ===
	0.8658477540593594	time to get	50000000	bits | set count:	50000000

	=== 16. FIND PERFORMANCE ===
	0.0000011479714885354042	time to find first set bit | result:	0
	3.2491516321897507e-07	time to find last set bit | result:	49999999

	=== 17. FIND_FREE PERFORMANCE ===
	0.021019569016061723	time to find first free bit | result:	25000000
	0.0190030470257625	time to find last free bit | result:	25000000

	=== 18. CLEAR PERFORMANCE ===
	0.573658627923578	time to clear50000000	bits

	=== BENCHMARK SUMMARY ===
	set:	0.5616594180464745	seconds
	get:	0.8658477540593594	seconds | sum:	50000000
	find forward:	0.0000011479714885354042	seconds
	find reverse:	3.2491516321897507e-07	seconds
	find_free forward:	0.021019569016061723	seconds
	find_free reverse:	0.0190030470257625	seconds
	clear:	0.573658627923578	seconds
	
	physical size:	6250000	bytes (~5 MB)
	bits per byte:	8
	world time:	2.0853163009742275

	ALL BITMAP TESTS PASSED
]==]

local bitmap = require("./")

local function assert_equal<T>(actual: T, expected: T, message: string)
	if actual ~= expected then
		error(
			message
				.. "\nexpected: "
				.. tostring(expected)
				.. "\nactual: "
				.. tostring(actual),
			2
		)
	end
end

local function assert_nil(value: any, message: string)
	if value ~= nil then
		error(
			message
				.. "\nexpected: nil"
				.. "\nactual: "
				.. tostring(value),
			2
		)
	end
end


print("=== BITMAP TEST ===")

local world_start = os.clock()


-- ============================================================
-- 1. BASIC GET / SET / CLEAR / TOGGLE
-- ============================================================

print("\n=== 1. BASIC OPERATIONS ===")

local b = buffer.create(16)

-- Buffer starts completely zeroed.
for i = 0, 127 do
	assert_equal(
		bitmap.get(b, i),
		false,
		"new bitmap must contain only zero bits at index " .. i
	)
end

-- First bit.
bitmap.set(b, 0)
assert_equal(bitmap.get(b, 0), true, "set(0) failed")

-- Last bit of first byte.
bitmap.set(b, 7)
assert_equal(bitmap.get(b, 7), true, "set(7) failed")

-- First bit of second byte.
bitmap.set(b, 8)
assert_equal(bitmap.get(b, 8), true, "set(8) failed")

-- Random positions.
bitmap.set(b, 13)
bitmap.set(b, 31)
bitmap.set(b, 32)
bitmap.set(b, 63)
bitmap.set(b, 64)
bitmap.set(b, 127)

assert_equal(bitmap.get(b, 13), true, "set(13) failed")
assert_equal(bitmap.get(b, 31), true, "set(31) failed")
assert_equal(bitmap.get(b, 32), true, "set(32) failed")
assert_equal(bitmap.get(b, 63), true, "set(63) failed")
assert_equal(bitmap.get(b, 64), true, "set(64) failed")
assert_equal(bitmap.get(b, 127), true, "set(127) failed")

-- Bits which were never set must remain false.
assert_equal(bitmap.get(b, 1), false, "unexpected bit 1")
assert_equal(bitmap.get(b, 6), false, "unexpected bit 6")
assert_equal(bitmap.get(b, 9), false, "unexpected bit 9")
assert_equal(bitmap.get(b, 14), false, "unexpected bit 14")

-- Clear.
bitmap.clear(b, 0)
bitmap.clear(b, 31)
bitmap.clear(b, 64)
bitmap.clear(b, 127)

assert_equal(bitmap.get(b, 0), false, "clear(0) failed")
assert_equal(bitmap.get(b, 31), false, "clear(31) failed")
assert_equal(bitmap.get(b, 64), false, "clear(64) failed")
assert_equal(bitmap.get(b, 127), false, "clear(127) failed")

-- Toggle false -> true.
bitmap.toggle(b, 1)
assert_equal(bitmap.get(b, 1), true, "toggle false -> true failed")

-- Toggle true -> false.
bitmap.toggle(b, 1)
assert_equal(bitmap.get(b, 1), false, "toggle true -> false failed")

print("basic operations: OK")


-- ============================================================
-- 2. ALL BIT POSITIONS
-- ============================================================

print("\n=== 2. ALL BIT POSITIONS ===")

local all = buffer.create(32)

for i = 0, 255 do
	bitmap.set(all, i)
end

for i = 0, 255 do
	assert_equal(
		bitmap.get(all, i),
		true,
		"failed to set bit " .. i
	)
end

for i = 0, 255 do
	bitmap.clear(all, i)
end

for i = 0, 255 do
	assert_equal(
		bitmap.get(all, i),
		false,
		"failed to clear bit " .. i
	)
end

print("all 256 bits: OK")


-- ============================================================
-- 3. FIND FORWARD
-- ============================================================

print("\n=== 3. FIND FORWARD ===")

local f = buffer.create(16)

-- Set:
-- 3
-- 9
-- 17
-- 24
-- 63
-- 64
-- 100
-- 127

local set_positions = {
	3,
	9,
	17,
	24,
	63,
	64,
	100,
	127,
}

for _, position in set_positions do
	bitmap.set(f, position)
end

assert_equal(
	bitmap.find(f),
	3,
	"find() must return first set bit"
)

assert_equal(
	bitmap.find(f, 0),
	3,
	"find(0) failed"
)

assert_equal(
	bitmap.find(f, 4),
	9,
	"find(4) failed"
)

assert_equal(
	bitmap.find(f, 10),
	17,
	"find(10) failed"
)

assert_equal(
	bitmap.find(f, 18),
	24,
	"find(18) failed"
)

assert_equal(
	bitmap.find(f, 25),
	63,
	"find(25) failed"
)

assert_equal(
	bitmap.find(f, 64),
	64,
	"find(64) failed"
)

assert_equal(
	bitmap.find(f, 65),
	100,
	"find(65) failed"
)

assert_equal(
	bitmap.find(f, 101),
	127,
	"find(101) failed"
)

assert_nil(
	bitmap.find(f, 128),
	"find(128) must return nil"
)

print("forward find: OK")


-- ============================================================
-- 4. FIND RANGE
-- ============================================================

print("\n=== 4. FIND RANGE ===")

-- Exact range containing one bit.
assert_equal(
	bitmap.find(f, 9, 9),
	9,
	"find(9, 9) failed"
)

-- Range excludes the actual bit.
assert_nil(
	bitmap.find(f, 10, 16),
	"find(10, 16) must return nil"
)

-- 17 is inside.
assert_equal(
	bitmap.find(f, 16, 20),
	17,
	"find(16, 20) failed"
)

-- 24 is inside.
assert_equal(
	bitmap.find(f, 20, 24),
	24,
	"find(20, 24) failed"
)

-- 24 must not be returned when upper bound is 23.
assert_nil(
	bitmap.find(f, 20, 23),
	"find(20, 23) must return nil"
)

-- First and last positions in a byte.
assert_equal(
	bitmap.find(f, 0, 7),
	3,
	"find(0, 7) failed"
)

assert_equal(
	bitmap.find(f, 4, 7),
	nil,
	"find(4, 7) must return nil"
)

assert_equal(
	bitmap.find(f, 8, 15),
	9,
	"find(8, 15) failed"
)

print("range find: OK")


-- ============================================================
-- 5. FIND INVERSE
-- ============================================================

print("\n=== 5. FIND INVERSE ===")

-- Forward:
-- 3, 9, 17, 24, 63, 64, 100, 127

-- Reverse must return:
-- 127, 100, 64, 63, 24, 17, 9, 3

assert_equal(
	bitmap.find(f, nil, nil, nil, true),
	127,
	"reverse find() failed"
)

assert_equal(
	bitmap.find(f, 0, 126, nil, true),
	100,
	"reverse find(0, 126) failed"
)

assert_equal(
	bitmap.find(f, 0, 99, nil, true),
	64,
	"reverse find(0, 99) failed"
)

assert_equal(
	bitmap.find(f, 0, 62, nil, true),
	24,
	"reverse find(0, 62) failed"
)

assert_equal(
	bitmap.find(f, 0, 23, nil, true),
	17,
	"reverse find(0, 23) failed"
)

assert_equal(
	bitmap.find(f, 0, 16, nil, true),
	9,
	"reverse find(0, 16) failed"
)

assert_equal(
	bitmap.find(f, 0, 8, nil, true),
	3,
	"reverse find(0, 8) failed"
)

assert_nil(
	bitmap.find(f, 0, 2, nil, true),
	"reverse find(0, 2) must return nil"
)

print("reverse find: OK")


-- ============================================================
-- 6. FIND FREE
-- ============================================================

print("\n=== 6. FIND FREE ===")

local free = buffer.create(4)

-- Set bits 0..7.
for i = 0, 7 do
	bitmap.set(free, i)
end

-- First free = 8.
assert_equal(
	bitmap.find_free(free),
	8,
	"find_free() failed"
)

-- Fill 8..15.
for i = 8, 15 do
	bitmap.set(free, i)
end

assert_equal(
	bitmap.find_free(free),
	16,
	"find_free() after first byte failed"
)

-- Fill 16..23.
for i = 16, 23 do
	bitmap.set(free, i)
end

assert_equal(
	bitmap.find_free(free),
	24,
	"find_free() after second byte failed"
)

-- Fill everything.
for i = 24, 31 do
	bitmap.set(free, i)
end

assert_nil(
	bitmap.find_free(free),
	"find_free() on completely full bitmap must return nil"
)

print("find_free forward: OK")


-- ============================================================
-- 7. FIND FREE WITH RANGE
-- ============================================================

print("\n=== 7. FIND FREE RANGE ===")

local range_free = buffer.create(4)

-- Occupied:
-- 0,1,2,3
-- 8,9,10,11
--
-- Free:
-- 4..7
-- 12..31

for i = 0, 3 do
	bitmap.set(range_free, i)
end

for i = 8, 11 do
	bitmap.set(range_free, i)
end

assert_equal(
	bitmap.find_free(range_free, 0, 31),
	4,
	"find_free(0, 31) failed"
)

assert_equal(
	bitmap.find_free(range_free, 5, 31),
	5,
	"find_free(5, 31) failed"
)

assert_equal(
	bitmap.find_free(range_free, 7, 31),
	7,
	"find_free(7, 31) failed"
)

assert_equal(
	bitmap.find_free(range_free, 8, 31),
	12,
	"find_free(8, 31) failed"
)

assert_nil(
	bitmap.find_free(range_free, 0, 3),
	"find_free(0, 3) must return nil"
)

assert_nil(
	bitmap.find_free(range_free, 8, 11),
	"find_free(8, 11) must return nil"
)

print("find_free range: OK")


-- ============================================================
-- 8. FIND FREE INVERSE
-- ============================================================

print("\n=== 8. FIND FREE INVERSE ===")

-- Free bits:
-- 4,5,6,7,12..31
--
-- Reverse must return:
-- 31, 30, 29...

assert_equal(
	bitmap.find_free(range_free, nil, nil, nil, true),
	31,
	"reverse find_free() failed"
)

assert_equal(
	bitmap.find_free(range_free, 0, 30, nil, true),
	30,
	"reverse find_free(0, 30) failed"
)

assert_equal(
	bitmap.find_free(range_free, 0, 12, nil, true),
	12,
	"reverse find_free(0, 12) failed"
)

assert_equal(
	bitmap.find_free(range_free, 0, 11, nil, true),
	7,
	"reverse find_free(0, 11) failed"
)

assert_equal(
	bitmap.find_free(range_free, 0, 6, nil, true),
	6,
	"reverse find_free(0, 6) failed"
)

print("reverse find_free: OK")


-- ============================================================
-- 9. OFFSET
-- ============================================================

print("\n=== 9. OFFSET ===")

-- Layout:
--
-- byte 0 = header / unrelated data
-- byte 1.. = actual bitmap
--
-- index 0 therefore resides at physical byte 1.

local offset_buffer = buffer.create(8)

-- Put garbage into byte 0.
buffer.writeu8(offset_buffer, 0, 0xFF)

-- Actual bitmap begins at byte 1.
bitmap.set(offset_buffer, 0, 1)
bitmap.set(offset_buffer, 7, 1)
bitmap.set(offset_buffer, 8, 1)
bitmap.set(offset_buffer, 15, 1)

assert_equal(
	bitmap.get(offset_buffer, 0, 1),
	true,
	"offset get(0) failed"
)

assert_equal(
	bitmap.get(offset_buffer, 7, 1),
	true,
	"offset get(7) failed"
)

assert_equal(
	bitmap.get(offset_buffer, 8, 1),
	true,
	"offset get(8) failed"
)

assert_equal(
	bitmap.get(offset_buffer, 15, 1),
	true,
	"offset get(15) failed"
)

-- Without offset, byte 0 contains 0xFF.
assert_equal(
	bitmap.get(offset_buffer, 0),
	true,
	"physical byte 0 should remain untouched"
)

-- Find returns logical bitmap index, not index + offset.
assert_equal(
	bitmap.find(offset_buffer, nil, nil, 1),
	0,
	"offset find() failed"
)

assert_equal(
	bitmap.find(offset_buffer, 1, nil, 1),
	7,
	"offset find(1) failed"
)

assert_equal(
	bitmap.find(offset_buffer, 8, nil, 1),
	8,
	"offset find(8) failed"
)

print("offset: OK")


-- ============================================================
-- 10. OFFSET + FIND FREE
-- ============================================================

print("\n=== 10. OFFSET + FIND FREE ===")

local offset_free = buffer.create(8)

-- byte 0 is reserved.
buffer.writeu8(offset_free, 0, 0xAA)

-- Bitmap starts at byte 2.
local offset = 2

-- Occupy 0..9.
for i = 0, 9 do
	bitmap.set(offset_free, i, offset)
end

assert_equal(
	bitmap.find_free(offset_free, nil, nil, offset),
	10,
	"offset find_free() failed"
)

-- Occupy everything up to 31.
for i = 10, 31 do
	bitmap.set(offset_free, i, offset)
end

assert_nil(
	bitmap.find_free(offset_free, 0, 31, offset),
	"offset find_free() should return nil"
)

print("offset find_free: OK")


-- ============================================================
-- 11. BOUNDARY TESTS
-- ============================================================

print("\n=== 11. BOUNDARY TESTS ===")

local boundary = buffer.create(2)

-- Byte boundaries.
local boundaries = {
	0,
	7,
	8,
	15,
}

for _, index in boundaries do
	bitmap.set(boundary, index)
	assert_equal(
		bitmap.get(boundary, index),
		true,
		"boundary set/get failed at " .. index
	)
end

assert_equal(bitmap.find(boundary), 0, "boundary find 0 failed")
assert_equal(bitmap.find(boundary, 1), 7, "boundary find 7 failed")
assert_equal(bitmap.find(boundary, 8), 8, "boundary find 8 failed")
assert_equal(bitmap.find(boundary, 9), 15, "boundary find 15 failed")

assert_equal(
	bitmap.find(boundary, 0, 7),
	0,
	"boundary range 0..7 failed"
)

assert_equal(
	bitmap.find(boundary, 1, 7),
	7,
	"boundary range 1..7 failed"
)

assert_equal(
	bitmap.find(boundary, 8, 15),
	8,
	"boundary range 8..15 failed"
)

assert_equal(
	bitmap.find(boundary, 9, 15),
	15,
	"boundary range 9..15 failed"
)

print("boundaries: OK")


-- ============================================================
-- 12. INVALID / EMPTY RANGES
-- ============================================================

print("\n=== 12. EMPTY / INVALID RANGES ===")

local empty = buffer.create(2)

assert_nil(
	bitmap.find(empty, 10, 5),
	"find() with first > last must return nil"
)

assert_nil(
	bitmap.find_free(empty, 10, 5),
	"find_free() with first > last must return nil"
)

assert_nil(
	bitmap.find(empty, 16, 16),
	"find() outside bitmap must return nil"
)

assert_nil(
	bitmap.find_free(empty, 16, 16),
	"find_free() outside bitmap must return nil"
)

assert_nil(
	bitmap.find(empty, 100, 200),
	"find() completely outside bitmap must return nil"
)

assert_nil(
	bitmap.find_free(empty, 100, 200),
	"find_free() completely outside bitmap must return nil"
)

print("empty/invalid ranges: OK")


-- ============================================================
-- 13. RANDOMIZED CORRECTNESS
-- ============================================================

print("\n=== 13. RANDOMIZED CORRECTNESS ===")

local RANDOM_BITS = 4096
local random_buffer = buffer.create(RANDOM_BITS / 8)

local reference: {[number]: boolean} = {}

math.randomseed(123456)

-- Random set/clear/toggle operations.
for _ = 1, 20_000 do
	local index = math.random(0, RANDOM_BITS - 1)
	local operation = math.random(1, 3)

	if operation == 1 then
		bitmap.set(random_buffer, index)
		reference[index] = true

	elseif operation == 2 then
		bitmap.clear(random_buffer, index)
		reference[index] = false

	else
		bitmap.toggle(random_buffer, index)
		reference[index] = not reference[index]
	end
end

-- Verify every bit.
for i = 0, RANDOM_BITS - 1 do
	local expected = reference[i] == true
	local actual = bitmap.get(random_buffer, i)

	assert_equal(
		actual,
		expected,
		"randomized get mismatch at bit " .. i
	)
end

-- Verify find against reference.
local expected_first: number? = nil

for i = 0, RANDOM_BITS - 1 do
	if reference[i] == true then
		expected_first = i
		break
	end
end

assert_equal(
	bitmap.find(random_buffer),
	expected_first,
	"randomized forward find mismatch"
)

-- Verify reverse find.
local expected_last: number? = nil

for i = RANDOM_BITS - 1, 0, -1 do
	if reference[i] == true then
		expected_last = i
		break
	end
end

assert_equal(
	bitmap.find(random_buffer, nil, nil, nil, true),
	expected_last,
	"randomized reverse find mismatch"
)

-- Verify find_free.
local expected_free: number? = nil

for i = 0, RANDOM_BITS - 1 do
	if reference[i] ~= true then
		expected_free = i
		break
	end
end

assert_equal(
	bitmap.find_free(random_buffer),
	expected_free,
	"randomized forward find_free mismatch"
)

-- Verify reverse find_free.
local expected_free_last: number? = nil

for i = RANDOM_BITS - 1, 0, -1 do
	if reference[i] ~= true then
		expected_free_last = i
		break
	end
end

assert_equal(
	bitmap.find_free(random_buffer, nil, nil, nil, true),
	expected_free_last,
	"randomized reverse find_free mismatch"
)

print("randomized correctness: OK")


-- ============================================================
-- 14. PERFORMANCE: SET
-- ============================================================

print("\n=== 14. SET PERFORMANCE ===")

local BENCH_BITS = 50_000_000
local bench = buffer.create(math.ceil(BENCH_BITS / 8))

local t_set = os.clock()

for i = 0, BENCH_BITS - 1 do
	bitmap.set(bench, i)
end

local set_time = os.clock() - t_set

print(
	set_time,
	"time to set",
	BENCH_BITS,
	"bits"
)

print(
	"bitmap physical size:",
	buffer.len(bench),
	"bytes (~"
		.. math.floor(buffer.len(bench) / 1024 / 1024)
		.. " MB)"
)


-- ============================================================
-- 15. PERFORMANCE: GET
-- ============================================================

print("\n=== 15. GET PERFORMANCE ===")

local get_sum = 0

local t_get = os.clock()

for i = 0, BENCH_BITS - 1 do
	if bitmap.get(bench, i) then
		get_sum += 1
	end
end

local get_time = os.clock() - t_get

print(
	get_time,
	"time to get",
	BENCH_BITS,
	"bits | set count:",
	get_sum
)

assert_equal(
	get_sum,
	BENCH_BITS,
	"all benchmark bits must be set"
)


-- ============================================================
-- 16. PERFORMANCE: FIND
-- ============================================================

print("\n=== 16. FIND PERFORMANCE ===")

-- Clear one bit near the middle.
bitmap.clear(bench, BENCH_BITS // 2)

local t_find = os.clock()

local found = bitmap.find(
	bench,
	0,
	BENCH_BITS - 1
)

local find_time = os.clock() - t_find

print(
	find_time,
	"time to find first set bit | result:",
	found
)

assert_equal(
	found,
	0,
	"find() must return 0"
)

local t_find_reverse = os.clock()

local found_reverse = bitmap.find(
	bench,
	0,
	BENCH_BITS - 1,
	nil,
	true
)

local find_reverse_time = os.clock() - t_find_reverse

print(
	find_reverse_time,
	"time to find last set bit | result:",
	found_reverse
)

assert_equal(
	found_reverse,
	BENCH_BITS - 1,
	"reverse find() must return last bit"
)


-- ============================================================
-- 17. PERFORMANCE: FIND FREE
-- ============================================================

print("\n=== 17. FIND_FREE PERFORMANCE ===")

local t_find_free = os.clock()

local free_position = bitmap.find_free(
	bench,
	0,
	BENCH_BITS - 1
)

local find_free_time = os.clock() - t_find_free

print(
	find_free_time,
	"time to find first free bit | result:",
	free_position
)

assert_equal(
	free_position,
	BENCH_BITS // 2,
	"find_free() must find cleared middle bit"
)

local t_find_free_reverse = os.clock()

local free_reverse_position = bitmap.find_free(
	bench,
	0,
	BENCH_BITS - 1,
	nil,
	true
)

local find_free_reverse_time = os.clock() - t_find_free_reverse

print(
	find_free_reverse_time,
	"time to find last free bit | result:",
	free_reverse_position
)

assert_equal(
	free_reverse_position,
	BENCH_BITS // 2,
	"reverse find_free() must find cleared middle bit"
)


-- ============================================================
-- 18. CLEAR PERFORMANCE
-- ============================================================

print("\n=== 18. CLEAR PERFORMANCE ===")

local t_clear = os.clock()

for i = 0, BENCH_BITS - 1 do
	bitmap.clear(bench, i)
end

local clear_time = os.clock() - t_clear

print(
	clear_time,
	"time to clear",
	BENCH_BITS,
	"bits"
)

assert_nil(
	bitmap.find(bench),
	"bitmap must contain no set bits after clear"
)

assert_equal(
	bitmap.find_free(bench),
	0,
	"bitmap must have bit 0 free after clear"
)


-- ============================================================
-- FINAL
-- ============================================================

print("\n=== BENCHMARK SUMMARY ===")

print(
	"set:",
	set_time,
	"seconds"
)

print(
	"get:",
	get_time,
	"seconds | sum:",
	get_sum
)

print(
	"find forward:",
	find_time,
	"seconds"
)

print(
	"find reverse:",
	find_reverse_time,
	"seconds"
)

print(
	"find_free forward:",
	find_free_time,
	"seconds"
)

print(
	"find_free reverse:",
	find_free_reverse_time,
	"seconds"
)

print(
	"clear:",
	clear_time,
	"seconds"
)

print(
	"physical size:",
	buffer.len(bench),
	"bytes (~"
		.. math.floor(buffer.len(bench) / 1024 / 1024)
		.. " MB)"
)

print(
	"bits per byte:",
	8
)

print(
	"world time:",
	os.clock() - world_start
)

print("\nALL BITMAP TESTS PASSED")

return true