import happyx
import std/sugar
import std/sequtils
import std/uri
import std/options
import std/json
import std/jsonutils
import std/oids
import std/times

# json serialize/deserialize DateTime
proc toJsonHook(dt: DateTime, opt = initToJsonOptions()): JsonNode = % $dt
proc fromJsonHook(dt: var DateTime, jsonNode: JsonNode) =
  dt = jsonNode.getStr().parse("yyyy-MM-dd'T'HH:mm:sszzz", utc())


type Result[T] = object
  data: Option[T]
  code: int
  errmsg: string

proc ok[T](): Result[T] = Result[T](data: none(T), code: 200, errmsg: "")
proc ok[T](data: T): Result[T] = Result[T](data: some(data), code: 0, errmsg: "")
proc ok[T](data: Option[T]): Result[T] = Result[T](data: data, code: 0, errmsg: "")
proc err[T](code: int, errmsg: string): Result[T] = Result[T](data: none(T), code: code, errmsg: errmsg)


type Fighter = object
  id: string
  name: string
  skill: seq[string]
  createdAt: DateTime

type FighterCreate = object
  name: string
  skill: seq[string]

proc toFighter(a: FighterCreate): Fighter = 
  return Fighter(
    id: $genOid(),
    name: a.name,
    skill: a.skill,
    createdAt: now().utc
  )


serve "127.0.0.1", 5000:
  var fighters = @[
    Fighter(id: $genOid(), name: "隆", skill: @["波动拳"], createdAt: now().utc),
    Fighter(id: $genOid(), name: "肯", skill: @["升龙拳"], createdAt: now().utc)
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
  
  get "/fighter":
    return ok(fighters).toJson

  get "/fighter/{id:string}/details": 
    let found = fighters.filterIt(it.id == id)
    if found.len > 0:
      return ok(found[0]).toJson
    else:
      return ok[Fighter]().toJson
  
  get "/fighter/{name:string}":
    let nameDecoded = decodeUrl(name)
    let found = fighters.filterIt(it.name == nameDecoded)
    return ok(found).toJson

  post "/fighter":
    let fighterCreate = try:
        parseJson(req.body.get("")).jsonTo(FighterCreate)
      except Exception:
        req.answer("Bad request body", Http400)
        return
    let newFighter = fighterCreate.toFighter
    fighters.add newFighter
    return ok(newFighter).toJson
  
  delete "/fighter/{id:string}":
    let removeFighter = fighters.filterIt(it.id == id)
    fighters = fighters.filterIt(it.id != id)
    return ok(removeFighter).toJson
