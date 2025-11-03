package main

import (
    "encoding/json"
    "fmt"
    "io/ioutil"
    "log"
    "os"
    cbor "github.com/fxamacker/cbor/v2"
    b3 "lukechampine.com/blake3"
)

func main() {
    if len(os.Args) < 2 { log.Fatalf("usage: lk_cbor_go entry.json") }
    b, err := ioutil.ReadFile(os.Args[1])
    if err != nil { log.Fatal(err) }
    var v map[string]interface{}
    if err := json.Unmarshal(b, &v); err != nil { log.Fatal(err) }
    delete(v, "attestations")
    encOpts := cbor.CanonicalEncOptions()
    em, err := encOpts.EncMode()
    if err != nil { log.Fatal(err) }
    can, err := em.Marshal(v)
    if err != nil { log.Fatal(err) }
    h := b3.Sum256(can)
    fmt.Printf("%x\n", h[:])
}

