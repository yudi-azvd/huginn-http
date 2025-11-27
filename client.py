import requests as r
import sys

route = '/'
if len(sys.argv) > 1:
    route = sys.argv[1]
    print("request to", route)

x = r.get("http://127.0.0.1:8080" + route)
print(x)
print(x.content)
print(x.text)