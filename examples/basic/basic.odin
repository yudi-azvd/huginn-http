package example_basic

import "core:fmt"
import "core:mem"
import "core:strings"

import rv "../../src"


main :: proc() {
	fmt.printfln("Hello Raven")

	server := rv.Raven_Server {
		max_memory = 4 * mem.Megabyte,
		address    = "127.0.0.1",
		port       = 8080,
	}

	rv.add_route(
		&server,
		"/",
		proc(req: ^rv.Request, res: ^rv.Response) -> ^rv.Response {
			msg := "hello from / handler"
			// fmt.printfln(msg)
			mem.copy(&res.buffer, raw_data(msg), len(msg))
			res.buffer_len = len(msg)
			res.status_code = 200
			return res
		},
	)

	rv.add_route(&server, "/oi", proc(req: ^rv.Request, res: ^rv.Response) -> ^rv.Response {
		msg := "++++ hello from /oi handler......."
		mem.copy(&res.buffer, raw_data(msg), len(msg))
		res.buffer_len = len(msg)
		res.status_code = 200
		return res
	})

	rv.init(server)
	rv.run(&server)
}
