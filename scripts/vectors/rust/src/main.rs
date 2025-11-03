use serde_json::Value;
use std::env;
use std::fs;

fn canonical(v: &Value) -> String {
    match v {
        Value::Object(map) => {
            let mut keys: Vec<&String> = map.keys().collect();
            keys.sort();
            let parts: Vec<String> = keys
                .into_iter()
                .map(|k| format!("{}:{}", serde_json::to_string(k).unwrap(), canonical(&map[k])))
                .collect();
            format!("{{{}}}", parts.join(","))
        }
        Value::Array(arr) => {
            let parts: Vec<String> = arr.iter().map(canonical).collect();
            format!("[{}]", parts.join(","))
        }
        Value::Null => "null".to_string(),
        Value::Bool(b) => if *b { "true" } else { "false" }.to_string(),
        Value::Number(n) => {
            if let Some(i) = n.as_i64() { i.to_string() } else { panic!("floats forbidden in canonical positions") }
        }
        Value::String(s) => serde_json::to_string(s).unwrap(),
    }
}

fn preimage(entry: &Value) -> String {
    let mut e = entry.clone();
    if let Some(obj) = e.as_object_mut() { obj.remove("attestations"); }
    canonical(&e)
}

fn main() {
    let p = env::args().nth(1).expect("usage: lk_canon_rust entry.json");
    let data = fs::read_to_string(p).unwrap();
    let v: Value = serde_json::from_str(&data).unwrap();
    let can = preimage(&v);
    let id = blake3::hash(can.as_bytes());
    println!("{}", id.to_hex());
}

