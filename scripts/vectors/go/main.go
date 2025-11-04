package main

import (
    "encoding/json"
    "fmt"
    "io/ioutil"
    "log"
    "os"
    "sort"
    b3 "lukechampine.com/blake3"
)

func canonical(v interface{}) string {
    switch t := v.(type) {
    case map[string]interface{}:
        keys := make([]string, 0, len(t))
        for k := range t { keys = append(keys, k) }
        sort.Strings(keys)
        parts := make([]string, 0, len(keys))
        for _, k := range keys {
            parts = append(parts, fmt.Sprintf("%s:%s", mustJSON(k), canonical(t[k])))
        }
        return fmt.Sprintf("{%s}", join(parts))
    case []interface{}:
        parts := make([]string, 0, len(t))
        for _, x := range t { parts = append(parts, canonical(x)) }
        return fmt.Sprintf("[%s]", join(parts))
    case nil:
        return "null"
    case bool:
        if t { return "true" } else { return "false" }
    case float64:
        // JSON decoder uses float64 for numbers by default; enforce integer
        if t != float64(int64(t)) { log.Fatalf("floats forbidden in canonical positions") }
        return fmt.Sprintf("%d", int64(t))
    case string:
        return mustJSON(t)
    default:
        log.Fatalf("unsupported type %T", t)
    }
    return ""
}

func mustJSON(v interface{}) string {
    b, err := json.Marshal(v)
    if err != nil { log.Fatal(err) }
    return string(b)
}

func join(parts []string) string {
    out := ""
    for i, s := range parts {
        if i > 0 { out += "," }
        out += s
    }
    return out
}

func preimage(entry map[string]interface{}) string {
    // copy without attestations
    e := map[string]interface{}{}
    for k, v := range entry { if k != "attestations" { e[k] = v } }
    return canonical(e)
}

func main() {
    if len(os.Args) < 2 { log.Fatalf("usage: lk_canon_go entry.json") }
    b, err := ioutil.ReadFile(os.Args[1])
    if err != nil { log.Fatal(err) }
    var v map[string]interface{}
    if err := json.Unmarshal(b, &v); err != nil { log.Fatal(err) }
    can := preimage(v)
    h := b3.Sum256([]byte(can))
    fmt.Printf("%x\n", h[:])
}

