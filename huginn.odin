package huginn

import hu "./src"

// TODO: Queria expor os membros públicos de um jeito mais fácil

DEFAULT_HUGINN_SERVER := hu.DEFAULT_HUGINN_SERVER

Http_Method :: hu.Http_Method
Huginn_Server :: hu.Huginn_Server
Request :: hu.Request
Response :: hu.Response
Route_Handler :: hu.Route_Handler

run :: hu.run
add_route :: hu.add_route
get :: hu.get
put :: hu.put
