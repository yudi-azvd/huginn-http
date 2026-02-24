package huginn_http

import mem "core:mem"

Arena :: struct {
	block: rawptr,
}

huginn_arena_allocator :: proc(arena: ^Arena) -> mem.Allocator {
	return mem.Allocator{huginn_allocator_proc, arena}
}

Allocator_Error :: mem.Allocator_Error


huginn_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_ptr: rawptr,
	old_size: int,
	location := #caller_location,
) -> (
	[]byte,
	Allocator_Error,
) {
	return nil, nil
}
