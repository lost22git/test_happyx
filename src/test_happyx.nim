import happyx
import std/sugar
import std/sequtils
import std/uri
import std/options
import std/json
import std/jsonutils
import std/oids
import std/times

type Result[T] = object
  data: Option[T]
  code: int
  errmsg: string

proc ok[T](): Result[T] = Result[T](data: none(T), code: 200, errmsg: "")
proc ok[T](data: T): Result[T] = Result[T](data: some(data), code: 0, errmsg: "")
proc ok[T](data: Option[T]): Result[T] = Result[T](data: data, code: 0, errmsg: "")

proc err[T](code: int, errmsg: string): Result[T] = Result[T](data: none(T), code: code, errmsg: errmsg)

# TODO: DateTime json ser/der
proc toJsonHook(dt: DateTime, opt = initToJsonOptions()): JsonNode =
  return newJString $dt

proc fromJsonHook[DateTime](dt: var DateTime, jsonNode: JsonNode, opt = Joptions()) =
  dt = parse($jsonNode, "yyyy-MM-dd'T'HH:mm:sszzz", utc())

type Fighter = object
  id: string
  name: string
  skill: string
  createdAt: DateTime

model FighterCreate:
  name: string
  skill: string

proc toFighter(a: FighterCreate): Fighter = 
  return Fighter(
    id: $genOid(),
    name: a.name,
    skill: a.skill,
    createdAt: now().utc
  )


serve "127.0.0.1", 5000:
  var fighters = @[
    Fighter(id: $genOid(), name: "隆", skill: "波动拳", createdAt: now().utc),
    Fighter(id: $genOid(), name: "肯", skill: "升龙拳", createdAt: now().utc)
  ]
  
  get "/text":
    "Hello happyx"

  get "/json":
    return {"msg": "Hello happyx"}

  get "/redirect":
    req.answer(
      "redirect to [github](https://www.github.com)",
      Http302,
      {"Location": "https://www.github.com"}.newHttpHeaders
    )
  
  post "/fighter[fighterCreate:FighterCreate:json]":
    let newFighter = fighterCreate.toFighter
    fighters.add newFighter
    return ok(newFighter).toJson

  get "/fighter":
    return ok(fighters).toJson

  get "/fighter/{id:string}/details": 
    let found = fighters.filter(x => x.id == id)
    if found.len == 0:
      return ok[Fighter]().toJson 
    else:
      return ok(found[0]).toJson
  
  get "/fighter/{name:string}":
    let nameDecoded = decodeUrl(name)
    let found = fighters.filter(x => x.name == nameDecoded)
    return ok(found).toJson
  
  delete "/fighter/{name:string}":
    let nameDecoded = decodeUrl(name) 
    let removeFighter = fighters.filter(x => x.name == nameDecoded)
    fighters = fighters.filter(x => x.name != nameDecoded)
    return ok(removeFighter).toJson
