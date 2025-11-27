package examples_client

import "core:fmt"
import "core:net"
import os "core:os/os2"

main :: proc() {
	addr := net.parse_address("127.0.0.1")
	if addr == nil {
		fmt.eprintfln("Error parsing address")
		os.exit(1)
	}

	ep := net.Endpoint {
		address = addr,
		port    = 8080,
	}

	net_err: net.Network_Error = nil
	client := net.TCP_Socket{}
	client, net_err = net.dial_tcp_from_endpoint(ep)
	if net_err != nil {
		fmt.eprintfln("Error dialing enpoint: %v", net_err)
		os.exit(1)
	} else {
		fmt.printfln("Dial OK")
	}

	msg: string = "Hello via TCP"
	buffer := transmute([]u8)(msg)
	written := 0
	written, net_err = net.send_tcp(client, buffer)
	if net_err != nil {
		fmt.eprintfln("Error writing to socket: %v", net_err)
	} else {
		fmt.printfln("Wrote %v bytes", written)
	}

	net.close(client)
}
