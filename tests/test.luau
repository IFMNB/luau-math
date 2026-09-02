local array = require("./")

const MAX = 50_000_000
const FROM = math.round(MAX / 4)

print("=== BUFFER ARRAY ===")

-- ============================================================
-- CREATE
-- ============================================================

local t0 = os.clock()

local a = array.create("integer", MAX)

local create_time = os.clock() - t0
print(create_time, "time to create array")

-- ============================================================
-- FILL
-- ============================================================

local t1 = os.clock()

for i = 1, MAX do
	array.write(a, i, 1)
end

local fill_time = os.clock() - t1

print(fill_time, "time to fill array")
print("count:", array.count(a))
print("max:", array.max(a))

-- ============================================================
-- FORWARD ITERATION
-- ============================================================

local t2 = os.clock()
local sum_forward = 0

local iterator = array.iter(a)

while true do
	local position, value = iterator()

	if position == nil then
		break
	end

	sum_forward += value
end

local forward_time = os.clock() - t2

print(forward_time, "time to forward iter")
print("sum:", sum_forward)

-- ============================================================
-- REVERSE ITERATION
-- ============================================================

local t3 = os.clock()
local sum_reverse = 0

local iterator_reverse = array.iter(a, nil, true)

while true do
	local position, value = iterator_reverse()

	if position == nil then
		break
	end

	sum_reverse += value
end

local reverse_time = os.clock() - t3

print(reverse_time, "time to reversed iter")
print("sum:", sum_reverse)

-- ============================================================
-- ITERATION FROM POSITION
-- ============================================================

local t4 = os.clock()
local sum_from_position = 0

local iterator3 = array.iter(a, FROM)

while true do
	local position, value = iterator3()

	if position == nil then
		break
	end

	sum_from_position += value
end

local from_position_time = os.clock() - t4

print(from_position_time, `time to iter from position {FROM}`)
print("sum:", sum_from_position)

print("buffer array total:", os.clock() - t0)


print("\n\n=== TABLE ===")

-- ============================================================
-- CREATE
-- ============================================================

local t5 = os.clock()

local t = table.create(MAX)

local create_table_time = os.clock() - t5

print(create_table_time, "time to create table")

-- ============================================================
-- FILL
-- ============================================================

local t6 = os.clock()

for i = 1, MAX do
	t[i] = 1
end

local fill_table_time = os.clock() - t6

print(fill_table_time, "time to fill table")

-- ============================================================
-- FORWARD ITERATION
-- ============================================================

local t7 = os.clock()
local table_sum_forward = 0

for i = 1, MAX do
	table_sum_forward += t[i]
end

local table_forward_time = os.clock() - t7

print(table_forward_time, "time to forward iter")
print("sum:", table_sum_forward)

-- ============================================================
-- REVERSE ITERATION
-- ============================================================

local t8 = os.clock()
local table_sum_reverse = 0

for i = MAX, 1, -1 do
	table_sum_reverse += t[i]
end

local table_reverse_time = os.clock() - t8

print(table_reverse_time, "time to reversed iter")
print("sum:", table_sum_reverse)

-- ============================================================
-- ITERATION FROM POSITION
-- ============================================================

local t9 = os.clock()
local table_sum_from_position = 0

for i = FROM + 1, MAX do
	table_sum_from_position += t[i]
end

local table_from_position_time = os.clock() - t9

print(table_from_position_time, `time to iter from position {FROM}`)
print("sum:", table_sum_from_position)

print("table total:", os.clock() - t5)

print("\n=== CHECK ===")

print("forward:", sum_forward, table_sum_forward)
print("reverse:", sum_reverse, table_sum_reverse)
print("from position:", sum_from_position, table_sum_from_position)


print("table count:", #t)
print("array count:", array.count(a))

print("table o(1) operation test (t[n])")
const t6 = os.clock()
t[5_000_000] = 1
print(os.clock() - t6, "time to o(1) operation")

print("buffer o(1) operation test (a[n])")
const t7 = os.clock()
array.write(a, 5_000_000, 1)
print(os.clock() - t7, "time to o(1) operation")

print("\n === test array for i = n, m, do (table)")

local sum = 0
local t8 = os.clock()

for i = 1, MAX do
    sum += t[i]
end

print(os.clock() - t8, sum, "time to table for i = n, m, do")

print("\n === test array for i = n, m, do (array)")


local sum = 0
local t9 = os.clock()

for i = 1, MAX do
    sum += array.read(a, i) :: number
end

print(os.clock() - t9, sum, "time to array for i = n, m, do")

print("\ndone")

return true