---
name: explain-simulation
description: Explain what a Tricentis Simulation YAML file does in plain English. Accepts an optional file path; if omitted, explains all simulation files in the current directory.
argument-hint: [file-path-or-glob]
allowed-tools: Read, Glob
---

Explain the Tricentis Simulation file(s) in plain English.

**Arguments:** $ARGUMENTS

## Your task

Read one or more simulation YAML files and produce a clear, structured explanation aimed at someone who is new to Tricentis Simulation. Follow these steps precisely.

### Step 1 — Find the files

- If `$ARGUMENTS` is a specific file path: read that file
- If `$ARGUMENTS` is a glob or directory: resolve and read all matching `.yml`/`.yaml` files
- If `$ARGUMENTS` is empty: glob `**/*.yml` in the current directory and read all simulation files (files that start with `schema: SimV1`)

Read every identified file in full before writing your explanation.

### Step 2 — Build your understanding

For each simulation file, extract:
- **Name and purpose** — the `name` field and any top-level comments
- **Connections** — ports and protocols being listened on
- **Resources** — backing data stores (CSV Tables, KeyValue stores) and what data they hold
- **Services** — for each service:
  - What HTTP method + path triggers it (from the `trigger` block)
  - What data it extracts from the request (from `buffer`)
  - What it does with that data (resource reads/writes, expressions)
  - What response it sends back (status code, payload shape)
  - Any conditions, verifications, or error branches
- **Templates** — shared logic reused across services
- **Includes** — other files pulled in

### Step 3 — Write the explanation

Structure your output as follows:

---

## [Simulation name or filename]

**In one sentence:** `<what this simulation virtualizes and why it exists>`

### Endpoints

List every endpoint as a brief section:

**`METHOD /path`** — `<service name>`
> <one-sentence description of what this endpoint does>

- **Triggers on:** `<method>` `<path>` — note if path parameters are captured
- **Extracts from request:** list buffered values (path params, query params, body fields)
- **Business logic:** describe any reads/writes to resources, expressions used (e.g. generates a random ID, looks up a row by cartId, increments a counter)
- **Returns:** HTTP `<status>` with `<description of the payload>` — highlight any dynamic values echoed back
- **Side effects:** any resource inserts/updates/deletes that persist state

*(Repeat for each service)*

### Data & State

If the simulation uses resources:
- **`<resourceName>`** (`<type>`): describe what it stores, its columns, and how it is used across endpoints

If no resources: state that this simulation is stateless.

### Key expressions & patterns used

List any non-obvious expression patterns found in the file and briefly explain what they do:
- `{RND[5]}` — generates a 5-digit random number (used as an ID)
- `{FROM[cart][itemDesc][cartId=='{b[cartId]}']}` — looks up `itemDesc` column in the `cart` CSV where `cartId` matches the buffered value
- `{DATE}` — inserts the current timestamp
- etc.

### Gotchas & things to know

Call out anything that might trip up someone new:
- Ordering of services (more specific paths must be listed before wildcards)
- Any verifications that will reject malformed requests
- Stateful behavior (e.g. you must call POST /create before GET /{id} will return data)
- Ports in use

---

If multiple files were explained, put each under its own `##` heading. End with a **"Big picture"** section if the files work together (e.g. one includes another, or they share a port).

### Tone and style

- Write for a QA engineer who understands HTTP and testing but has never seen Tricentis Simulation before
- Avoid repeating raw YAML — paraphrase in plain English
- Be concrete: name actual paths, field names, and status codes from the file
- Keep it scannable: use the structure above, don't write walls of prose
