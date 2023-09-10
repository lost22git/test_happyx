import happyx
import mapster
import stdx/sequtils
import std/sugar
import std/sequtils
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
proc err[T](code: int, errmsg: string): Result[T] = Result[T](data: none(T),
    code: code, errmsg: errmsg)



type StartupInfo = object
  release_mode: bool
  multi_threads: bool
  pid: int
  port: int

proc initStartupInfo(port: int): StartupInfo =
  when defined(release):
    const release_mode = true
  else:
    const release_mode = false

  when compileOption("threads"):
    const multi_threads = true
  else:
    const multi_threads = false

  result = StartupInfo(
    release_mode: release_mode,
    multi_threads: multi_threads,
    pid: os.getCurrentProcessId(),
    port: port
  )

const port = 5000
let startupInfo = initStartupInfo(port)

echo "Startup info: ", startupInfo





type Fighter = ref object
  id: string
  name: string
  skill: seq[string]
  createdAt: DateTime
  updatedAt: Option[DateTime] = none(DateTime)

type FighterCreate = object
  name: string
  skill: seq[string]


type FighterEdit = object
  name: string
  skill: seq[string]

proc toFighter(a: FighterCreate): Fighter {.map.} = 
  result.id = $genOid()
  result.createdAt = now().utc

proc mergeFighter(a: var Fighter, b: FighterEdit) {.inplaceMap.} = 
  a.updatedAt = now().utc.some


serve "127.0.0.1", port:
  var fighters = @[
    Fighter(id: $genOid(), name: "隆", skill: @["波动拳"], createdAt: now().utc),
    Fighter(id: $genOid(), name: "肯", skill: @["升龙拳"], createdAt: now().utc)
  ]

  get "/text":
    "Hello happyx"

  get "/json":
    return { "msg": "Hello happyx" }

  get "/redirect":
    req.answer(
      "redirect to [github](https://www.github.com)",
      Http302,
      {"Location": "https://www.github.com"}.newHttpHeaders
    )

  get "/fighter":
    return ok(fighters).toJson

  get "/fighter/{name:string}":
    let found = fighters.findIt(it.name == name)
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

  put "/fighter":
    let fighterEdit = try:
        parseJson(req.body.get("")).jsonTo(FighterEdit)
      except Exception:
        req.answer("Bad request body", Http400)
        return
    var found = fighters.findIt(it.name == fighterEdit.name)
    if found != nil:
      mergeFighter(found, fighterEdit)
      return ok(found).toJson
    return ok[Fighter]().toJson

  delete "/fighter/{name:string}":
    let found = fighters.findIt(it.name == name)
    fighters = fighters.filterIt(it.name != name)
    return ok(found).toJson
