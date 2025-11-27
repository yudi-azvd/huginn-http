package main

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:net"
import "core:strings"
import "core:sys/windows"

import os "core:os/os2"

import "core:sys/posix"


Raven_Server :: struct {
	address:    string,
	port:       int,
	max_memory: int,
	routes:     map[string]Route_Handler,
}

Request :: struct {
	origin_address: string,
	version:        string,
}

Response :: struct {
	status_code: int,
}


DEFAULT_RAVEN_SERVER := Raven_Server {
	max_memory = 4 * mem.Megabyte,
	port       = 8080,
}

create_server :: proc() -> Raven_Server {
	s := Raven_Server{}

	return s
}

init :: proc(s: Raven_Server) {
	fmt.println("Init Raven")
}

/*

Response      = Status-Line               ; Section 6.1
				*(( general-header        ; Section 4.5
				| response-header        ; Section 6.2
				| entity-header ) CRLF)  ; Section 7.1
				CRLF
				[ message-body ]          ; Section 7.2

*/

generic_response := `HTTP/1.0 200 OK\r
`


run :: proc(s: Raven_Server) {
	posix.signal(.SIGQUIT, proc "c" (s: posix.Signal) {
		context = runtime.default_context()
		fmt.printfln("Shutting down")
		os.exit(0)
	})

	addr := net.parse_address(s.address)
	if addr == nil {
		fmt.eprintfln("Error parsing address: %v", addr)
		os.exit(1)
	}
	addr_as_str := net.address_to_string(addr)

	ep := net.Endpoint {
		address = addr,
		port    = s.port,
	}
	// Qual é a diferença entre esse socket e o retornado por net.create_socket?
	// Pra que serve net.create_socket?
	tcp_socket, listen_err := net.listen_tcp(ep)
	if listen_err != nil {
		fmt.eprintfln("Error at listening: %v", listen_err)
	}

	msg := fmt.tprintfln("Running: http://%v:%v", addr_as_str, s.port)
	fmt.print(msg)

	for true {
		client, src, accept_err := net.accept_tcp(tcp_socket)
		if accept_err != nil {
			// fmt.eprintln("Error accepting client: %v", accept_err)
		} else {
			_handle_client(client, src)
		}
	}
}

@(private = "file")
_handle_client :: proc(client: net.TCP_Socket, src: net.Endpoint) {
	recv_buffer := [1024]u8{}
	bytes_read, read_err := net.recv_tcp(client, recv_buffer[:])
	if read_err != nil {
		fmt.eprintfln("Error reading from client: %v", read_err)
	} else {
		fmt.printfln("")
		fmt.printfln("client: %v", net.endpoint_to_string(src))
		fmt.printfln("read  %v bytes", bytes_read)
		fmt.printfln("--- request content: ---\n%v", transmute(string)recv_buffer[:])
		req := _parse_http_request(recv_buffer[:])
		written := 0
		send_err: net.TCP_Send_Error = nil
		buffer := _build_http_reponse(generic_response)
		written, send_err = net.send_tcp(client, buffer)
		if send_err != nil {
			fmt.eprintfln("Error sending bytes: %v", send_err)
		}
	}
	net.close(client)
}

@(private = "file")
_parse_http_request :: proc(req_buffer: []u8) -> Request { 	// ->(Request, Parse_Http_Request_Error)
	req := Request{}

	str := transmute(string)req_buffer
	i := 0
	for i > 0 && i < len(req_buffer) {
		i = _find_next_line(str, i)

	}

	return req
}

@(private = "file")
_find_next_line :: proc(s: string, offset: int) -> int {
	return offset
}

@(private = "file")
_build_http_reponse :: proc(
	 /* vai virar res: Response */s: string,
) -> []u8 {
	response := transmute([]u8)s
	return response
}

Route_Handler :: #type proc(req: ^Request, res: ^Response) -> ^Response

add_route :: proc(using s: ^Raven_Server, route: string, handler: Route_Handler) {
	r, found := routes[route]
	// Tem problema mais de um handler por rota?
	// if found {
	// 	fmt.printfln("Warning: ")
	// }
	routes[route] = handler
}
