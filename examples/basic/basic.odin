package example_basic

import "core:fmt"
import "core:mem"

import hu "../../huginn"

main :: proc() {
	fmt.printfln("Hello Huginn")

	server := hu.DEFAULT_HUGINN_SERVER
	server.max_memory = 4 * mem.Megabyte
	server.address = "127.0.0.1"
	server.port = 8080

	hu.add_route(
		&server,
		"GET /",
		proc(req: ^hu.Request, res: ^hu.Response) -> ^hu.Response {
			msg := "hello from / handler"
			// fmt.printfln(msg)
			mem.copy(&res.buffer, raw_data(msg), len(msg))
			res.buffer_len = len(msg)
			res.status_code = 200
			return res
		},
	)

	hu.add_route(&server, "GET /oi", proc(req: ^hu.Request, res: ^hu.Response) -> ^hu.Response {
		msg := "++++ hello from /oi handler......."
		mem.copy(&res.buffer, raw_data(msg), len(msg))
		res.buffer_len = len(msg)
		res.status_code = 200
		return res
	})

	hu.get(&server, "/outra-rota", proc(req: ^hu.Request, res: ^hu.Response) -> ^hu.Response {
		return res
	})

	hu.run(&server)
}
