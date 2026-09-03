--!strict
-- insert that test in folder where placed array

-- latest test on my notepad

--[==[
	NOTEPAD STATS
		i5-12450H
		RTX 4050
		64 GB RAM DDR5
		SATA SSD 1 TB SAMSUNG EVO 880

	❯ luau -g0 -O2 --codegen
	> require "./test"
	=== BUFFER ARRAY (DENSE) ===
	0.02047237998340279	time to create array
	1.318101166980341	time to fill array
	count:	50000000
	max:	50000000
	3.726914447033778	time to forward iter | sum:	50000000
	buffer array total:	5.074169136933051

	=== TABLE (DENSE) ===
	0.0829926630249247	time to create table
	0.11039348202757537	time to fill table
	0.13423748698551208	time to forward iter | sum:	50000000
	table total:	0.3710850520292297

	=== 1. MEMORY FOOTPRINT ===
	Buffer array physical size:	206250017	bytes (~196 MB)
	Lua table theoretical size:  ~800 MB (50,000,000 * 16 bytes TValue)
	Memory saved: ~604 MB (75%)

	=== 2. SPARSE OPERATIONS ===
	0.0036241260822862387	time to create 50000 holes (set to nil)
	0.0000028730137273669243	time to array.pick(a) -> pos:	1val:	nil
	0.0000033760443329811096	time to array.put(a, 999) -> allocated at pos:	1000

	=== 3. DELETION / CLEAR PERFORMANCE ===
	0.027535330969840288	time to clear 1,000,000 elements in buffer array
	0.0057434579357504845	time to clear 1,000,000 elements in table

	=== 4. BOOLEAN ARRAY (Bitmap) ===
	0.0010201620170846581	time to create boolean array
	1.1268039499409497	time to fill boolean array with 'true'
	Boolean array physical size:	6250017	bytes (~5 MB)

	=== 5. O(1) READ/WRITE MICRO-BENCHMARK ===
	9.75094735622406e-07	buffer array O(1) write
	9.569339454174042e-07	buffer array O(1) read (result: 42)
	1.8102582544088364e-07	table O(1) write
	6.507616490125656e-08	table O(1) read (result: 42)

	=== 6. RAW LOOP READ ===
	0.15333405090495944	48951042	time for table raw loop read
	1.9955936060287058	48951042	time for buffer array raw loop read

	=== 7. #t TEST (count test) ===
	0.008530116989277303	time for array to get count of elements
	0.0000035170232877135277	time for table to get count of elements

	ALL MAIN TESTS COMPLETED SUCCESSFULLY


	DEBUG TESTS 2

	=== 7. DEBUG: READ/WRITE CORRECTNESS ===
	read(1):	42	(expected: 42)
	read(50):	999	(expected: 999)
	read(100):	-7	(expected: -7)
	read(25):	nil	(expected: nil)
	read(1) after rewrite:	123	(expected: 123)
	read(50) after clear:	nil	(expected: nil)
	pick:	123	nil	(expected: 1, 123)
	put:	2	(expected: 2 — first free)
	read after put:	777	(expected: 777)
	count:	3	(expected: 3 — positions 1, 2, 100)
	bool read(1):	true	(expected: true)
	bool read(50) after false:	false	(expected: false)
	bool read(25):	false	(expected: false)
	8.767593323020265	global world time after test start

	=== DEBUG COMPLETE ===
]==]

local array = require("./")

const MAX = 50_000_000

print("=== BUFFER ARRAY (DENSE) ===")
local w0 = os.clock()

local t0 = os.clock()
local a = array.create("integer", MAX)
print(os.clock() - t0, "time to create array")

local t1 = os.clock()
for i = 1, MAX do
	array.write(a, i, 1)
end
print(os.clock() - t1, "time to fill array")
print("count:", array.count(a))
print("max:", array.max(a))

local t2 = os.clock()
local sum_forward = 0
local iterator = array.iter(a)
while true do
	local position, value = iterator()
	if position == nil then break end
	sum_forward += value
end
print(os.clock() - t2, "time to forward iter | sum:", sum_forward)

print("buffer array total:", os.clock() - t0)


print("\n=== TABLE (DENSE) ===")

local t5 = os.clock()
local t = table.create(MAX, 0)
print(os.clock() - t5, "time to create table")

local t6 = os.clock()
for i = 1, MAX do
	t[i] = 1
end
print(os.clock() - t6, "time to fill table")

local t7 = os.clock()
local table_sum_forward = 0
for i = 1, MAX do
	table_sum_forward += t[i]
end
print(os.clock() - t7, "time to forward iter | sum:", table_sum_forward)

print("table total:", os.clock() - t5)

print("\n=== 1. MEMORY FOOTPRINT ===")
local buffer_size_mb = math.floor(buffer.len(a) / 1024 / 1024)
print("Buffer array physical size:", buffer.len(a), "bytes (~" .. buffer_size_mb .. " MB)")
print("Lua table theoretical size:  ~800 MB (50,000,000 * 16 bytes TValue)")
print("Memory saved: ~" .. (800 - buffer_size_mb) .. " MB (" .. math.floor((1 - buffer_size_mb/800)*100) .. "%)")


print("\n=== 2. SPARSE OPERATIONS ===")
local holes_count = 0
local t_holes = os.clock()
for i = 1000, MAX, 1000 do
	array.write(a, i, nil)
	t[i] = nil
	holes_count += 1
end
print(os.clock() - t_holes, "time to create " .. holes_count .. " holes (set to nil)")

local t_pick = os.clock()
local picked_pos, picked_val = array.pick(a)
print(os.clock() - t_pick, "time to array.pick(a) -> pos:", picked_pos, "val:", picked_val)

local t_put = os.clock()
local put_pos = array.put(a, 999)
print(os.clock() - t_put, "time to array.put(a, 999) -> allocated at pos:", put_pos)


print("\n=== 3. DELETION / CLEAR PERFORMANCE ===")
local t_clear_buf = os.clock()
for i = 1, 1_000_000 do
	array.write(a, i, nil)
end
print(os.clock() - t_clear_buf, "time to clear 1,000,000 elements in buffer array")

local t_clear_tbl = os.clock()
for i = 1, 1_000_000 do
	t[i] = nil
end
print(os.clock() - t_clear_tbl, "time to clear 1,000,000 elements in table")


print("\n=== 4. BOOLEAN ARRAY (Bitmap) ===")
local t_bool_create = os.clock()
local bool_arr = array.create("boolean", MAX)
print(os.clock() - t_bool_create, "time to create boolean array")

local t_bool_fill = os.clock()
for i = 1, MAX do
	array.write(bool_arr, i, true)
end
print(os.clock() - t_bool_fill, "time to fill boolean array with 'true'")
print("Boolean array physical size:", buffer.len(bool_arr), "bytes (~" .. math.floor(buffer.len(bool_arr)/1024/1024) .. " MB)")

print("\n=== 5. O(1) READ/WRITE MICRO-BENCHMARK ===")
local t_ow_buf = os.clock()
array.write(a, 5_000_000, 42)
print(os.clock() - t_ow_buf, "buffer array O(1) write")

local t_or_buf = os.clock()
local r0 = array.read(a, 5_000_000)
print(os.clock() - t_or_buf, "buffer array O(1) read (result: " .. tostring(r0) .. ")")

local t_ow_tbl = os.clock()
t[5_000_000] = 42
print(os.clock() - t_ow_tbl, "table O(1) write")

local t_or_tbl = os.clock()
local r = t[5_000_000]
print(os.clock() - t_or_tbl, "table O(1) read (result: " .. tostring(r) .. ")")


print("\n=== 6. RAW LOOP READ ===")
local sum_tbl = 0
local t_loop_tbl = os.clock()
for i = 1, MAX do
    sum_tbl += t[i] or 0
end
print(os.clock() - t_loop_tbl, sum_tbl, "time for table raw loop read")

local sum_buf = 0
local t_loop_buf = os.clock()
for i = 1, MAX do
    sum_buf += array.read(a, i) or 0
end
print(os.clock() - t_loop_buf, sum_buf, "time for buffer array raw loop read")

print("\n=== 7. #t TEST (count test) ===")
local t_count_array = os.clock()
local _ = array.count(a)

print(os.clock() - t_count_array, "time for array to get count of elements")

local t_count_tbl = os.clock()
local _ = #t

print(os.clock() - t_count_tbl, "time for table to get count of elements")


print("\n ALL MAIN TESTS COMPLETED SUCCESSFULLY")

print("\n\n DEBUG TESTS 2")

print("\n=== 7. DEBUG: READ/WRITE CORRECTNESS ===")

local debug_arr = array.create("integer", 100)
array.write(debug_arr, 1, 42)
array.write(debug_arr, 50, 999)
array.write(debug_arr, 100, -7)

local v1 = array.read(debug_arr, 1)
local v50 = array.read(debug_arr, 50)
local v100 = array.read(debug_arr, 100)
local v_empty = array.read(debug_arr, 25)

print("read(1):", v1, "(expected: 42)")
print("read(50):", v50, "(expected: 999)")
print("read(100):", v100, "(expected: -7)")
print("read(25):", v_empty, "(expected: nil)")

array.write(debug_arr, 1, 123)
local v1_new = array.read(debug_arr, 1)
print("read(1) after rewrite:", v1_new, "(expected: 123)")

array.write(debug_arr, 50, nil)
local v50_cleared = array.read(debug_arr, 50)
print("read(50) after clear:", v50_cleared, "(expected: nil)")

local pick_pos, pick_val = array.pick(debug_arr)
print("pick:", pick_pos, pick_val, "(expected: 1, 123)")

local put_pos = array.put(debug_arr, 777)
print("put:", put_pos, "(expected: 2 — first free)")
local put_val = array.read(debug_arr, put_pos)
print("read after put:", put_val, "(expected: 777)")

local cnt = array.count(debug_arr)
print("count:", cnt, "(expected: 3 — positions 1, 2, 100)")

local bool_arr = array.create("boolean", 100)
array.write(bool_arr, 1, true)
array.write(bool_arr, 50, true)
array.write(bool_arr, 50, false)
local b1 = array.read(bool_arr, 1)
local b50 = array.read(bool_arr, 50)
local b_empty = array.read(bool_arr, 25)
print("bool read(1):", b1, "(expected: true)")
print("bool read(50) after false:", b50, "(expected: false)")
print("bool read(25):", b_empty, "(expected: false)")

print(os.clock() - w0, "global world time after test start")
print("\n=== DEBUG COMPLETE ===")

return true