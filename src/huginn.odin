package main

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:net"
import "core:strconv"
import "core:strings"
import "core:sys/posix"

import os "core:os/os2"


Huginn_Server :: struct {
	address:    string,
	port:       int,
	max_memory: int,
	routes:     map[string]Route_Handler,
}

Request :: struct {
	method:         Http_Method,
	uri:            string,
	version:        string,
	origin_address: string,
	headers:        map[string]string,
}

Http_Method :: enum {
	GET,
	POST,
	DELETE,
	PATCH,
	PUT,
	OPTIONS,
	HEAD,
	TRACE,
	CONNECT,
}

Response :: struct {
	status_code: int,
	buffer:      [1024]u8,
	buffer_len:  int,
}


DEFAULT_RAVEN_SERVER := Huginn_Server {
	max_memory = 4 * mem.Megabyte,
	port       = 8080,
}

run :: proc(s: ^Huginn_Server) {
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
			_handle_client(s, client, src)
		}
	}
}

@(private = "file")
_handle_client :: proc(s: ^Huginn_Server, client: net.TCP_Socket, src: net.Endpoint) {
	recv_buffer := [1024]u8{}
	bytes_read, read_err := net.recv_tcp(client, recv_buffer[:])
	if read_err != nil {
		fmt.eprintfln("Error reading from client: %v", read_err)
	} else {
		request_str := string(recv_buffer[:bytes_read])
		assert(bytes_read < 1024) // FIXME: temporário
		req := _parse_http_request(request_str)
		res_headers := map[string]string{}
		handler := s.routes[req.uri]
		if handler == nil {
			fmt.printfln("WARNING: Did not find handler for %v", req.uri)
			// TODO: responder 404 ou algo parecido
		} else {
			written := 0
			send_err: net.TCP_Send_Error = nil

			res := Response{}
			// USER CODE
			res = handler(&req, &res)^ // Redundante kkk
			// USER CODE

			res_str := transmute(string)res.buffer[:res.buffer_len]

			res_headers["Content-Type"] = "text/html"

			b := strings.Builder{}
			fmt.sbprintf(&b, "HTTP/1.0 200 OK\r\n")
			for header, value in res_headers {
				fmt.sbprintf(&b, "%v: %v\r\n", header, value)
			}
			fmt.sbprintf(&b, "Content-Length: %v\r\n", len(res_str))
			fmt.sbprintf(&b, "\r\n%v", res_str)
			final_string := strings.to_string(b)
			fmt.printfln("-------------------------------------------------")
			fmt.printfln("%v", final_string)
			fmt.printfln("-------------------------------------------------")
			final_buffer := transmute([]u8)final_string
			written, send_err = net.send_tcp(client, final_buffer)
			if send_err != nil {
				fmt.eprintfln("Error sending bytes: %v", send_err)
			}
		}

	}
	net.close(client)
}

@(private = "file")
_parse_http_request :: proc(req: string) -> Request { 	// ->(Request, Parse_Http_Request_Error)
	request := Request{}
	offset := 0
	str := req
	request_line := ""
	request_line, offset = _consume_line(str, offset)

	ok := _parse_request_line(&request, request_line)
	fmt.printfln("Route: %v", request.uri)
	fmt.printfln("Method: %v", request.method)
	fmt.printfln("Version: %v", request.version)

	for offset >= 0 && offset < len(str) {
		line, new_offset := _consume_line(str, offset)
		if strings.compare(line, "\r\n") == 0 {
			// Chegou o fim dos cabçalhos, mas ainda pode vir o corpo
			break
		}
		// fmt.printfln("line = %v", line)
		divisor := strings.index(line, ":")
		header := line[:divisor]
		value := line[divisor + 2:] // 2: pula o ': '
		value = value[:len(value) - 2] // "remove" o \r\n no final
		request.headers[header] = value
		// fmt.printfln("line: %v", line)
		offset = new_offset
	}

	for header, value in request.headers {
		fmt.printfln("%v: %v", header, value)
	}

	return request
}

@(private = "file")
_consume_line :: proc(str: string, offset: int) -> (line: string, new_offset: int) {
	s := str[offset:]
	index := strings.index(s, "\r\n")
	new_offset = offset + index
	assert(str[new_offset] == '\r')
	new_offset += 2
	assert(str[new_offset - 1] == '\n')
	// Se acabou a string, new_offset == offset
	// assert(new_offset > offset)
	line = str[offset:new_offset]
	return line, new_offset
}

@(private = "file")
_build_http_reponse :: proc(
	 /* vai virar res: Response */s: string,
) -> []u8 {
	response := transmute([]u8)s
	return response
}

@(private = "file")
_parse_request_line :: proc(req: ^Request, request_line: string) -> (ok: bool) {
	uri_idx := strings.index(request_line, " /") // TODO: nem sempre, pode ser * também
	assert(uri_idx > 0)
	uri_idx += 1
	assert(request_line[uri_idx] == '/') // TODO: nem sempre, pode ser * também

	version_idx := strings.index(request_line, "HTTP/")
	assert(version_idx > 0)
	req.uri = request_line[uri_idx:version_idx - 1]
	assert(len(req.uri) > 0)

	method := request_line[:uri_idx - 1]
	if method == "GET" {
		req.method = .GET
	} else {
		fmt.printfln("WARNING: new HTTP method: %v", method)
	}

	req.version = request_line[version_idx:]

	return true
}

Route_Handler :: #type proc(req: ^Request, res: ^Response) -> ^Response

add_route :: proc(using s: ^Huginn_Server, route: string, handler: Route_Handler) {
	r, found := routes[route]
	// Tem problema mais de um handler por rota?
	// if found {
	// 	fmt.printfln("Warning: ")
	// }
	routes[route] = handler
}

get :: proc(using s: ^Huginn_Server, route: string, handler: Route_Handler) {
	method :: string("GET")
	b := strings.Builder{}
	entry := fmt.sbprintf(&b, "%s %s", method, route)

	add_route(s, entry, handler)
}


post :: proc(using s: ^Huginn_Server, route: string, handler: Route_Handler) {
	method :: string("POST")
	b := strings.Builder{}
	entry := fmt.sbprintf(&b, "%s %s", method, route)

	add_route(s, entry, handler)
}
