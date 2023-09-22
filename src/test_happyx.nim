import happyx
import mapster
import jsony
import debby/sqlite
import std/[options, times]


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



# ------ jsony -------------------------

proc dumpHook*(s: var string, v: DateTime) =
  s.add '"'
  s.add $v
  s.add '"'
proc parseHook*(s: string, i: var int, v: var DateTime) =
  var str: string
  parseHook(s, i, str)
  v = parse(str, "yyyy-MM-dd'T'HH:mm:sszzz", utc())


# ------ orm --------------------------

type Fighter = ref object
  id: int
  name: string
  skill: seq[string]
  createdAt: DateTime
  updatedAt: Option[DateTime] = none DateTime


var fighters = @[
  Fighter(name: "隆", skill: @["波动拳"], createdAt: now().utc),
  Fighter(name: "肯", skill: @["升龙拳"], createdAt: now().utc)
]

let db = openDatabase("fighter.db")
db.dropTableIfExists(Fighter)
db.createTable(Fighter)
db.createIndexIfNotExists(Fighter, "name")
db.withTransaction:
  db.insert(fighters)



# ------ model -------------------------

type FighterCreate = object
  name: string
  skill: seq[string]

type FighterEdit = object
  name: string
  skill: seq[string]

proc toFighter(a: FighterCreate): Fighter {.map.} =
  result.createdAt = now().utc

proc mergeFighter(a: var Fighter, b: FighterEdit) {.inplaceMap.} =
  a.updatedAt = now().utc.some



# ------ server ------------------------

serve "127.0.0.1", port:
  get "/baseline/text":
    return "lost"

  get "/baseline/json":
    return ok("lost").toJson

  get "/redirect":
    req.answer(
      "redirect to [github](https://www.github.com)",
      Http302,
      {"Location": "https://www.github.com"}.newHttpHeaders
    )

  get "/fighter":
    {.cast(gcsafe).}:
      let all = db.filter(Fighter, 1 == 1)
      return ok(all).toJson

  get "/fighter/{name:string}":
    {.cast(gcsafe).}:
      let found = db.filter(Fighter, it.name == name)
      return ok(found).toJson

  post "/fighter":
    let fighterCreate = try:
        req.body.get("").fromJson(FighterCreate)
      except Exception:
        req.answer("Bad request body", Http400)
        return
    let newFighter = fighterCreate.toFighter
    {.cast(gcsafe).}:
      db.withTransaction:
        db.insert(newFighter)
    return ok(newFighter).toJson

  put "/fighter":
    let fighterEdit = try:
        req.body.get("").fromJson(FighterEdit)
      except Exception:
        req.answer("Bad request body", Http400)
        return
    var found: seq[Fighter]
    {.cast(gcsafe).}:
      db.withTransaction:
        found = db.filter(Fighter, it.name == fighterEdit.name)
        for v in found.mitems():
          mergeFighter(v, fighterEdit)
          db.update(v)
    return ok(found).toJson

  delete "/fighter/{name:string}":
    var found: seq[Fighter]
    {.cast(gcsafe).}:
      db.withTransaction:
        found = db.filter(Fighter, it.name == name)
        db.delete(found)
    return ok(found).toJson
