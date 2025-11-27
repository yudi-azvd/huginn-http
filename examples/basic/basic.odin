package example_basic

import "core:fmt"
import "core:mem"

import rv "../../src"


main :: proc() {
	fmt.printfln("Hello Raven")

	server := rv.Raven_Server {
		max_memory = 4 * mem.Megabyte,
		address    = "127.0.0.1",
		port       = 8080,
	}

	rv.add_route(&server, "/", proc(req: ^rv.Request, res: ^rv.Response) -> ^rv.Response {
		fmt.printfln("Hello from /")
		res.status_code = 200
		return res
	})

	rv.init(server)
	rv.run(server)
}
