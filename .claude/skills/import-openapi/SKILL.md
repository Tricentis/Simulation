---
name: import-openapi
description: Generate a Tricentis Simulation YAML file from an OpenAPI/Swagger specification. Accepts a file path to a JSON or YAML OpenAPI spec, or a URL.
argument-hint: <path-to-openapi-spec> [output-file]
allowed-tools: Read, Write, Glob, WebFetch
---

Generate a Tricentis Simulation YAML file from an OpenAPI specification.

**Arguments:** $ARGUMENTS

## Your task

Parse the given OpenAPI spec and produce a complete, valid `SimV1` simulation file. Follow these steps precisely.

### Step 1 — Load the spec

Parse `$ARGUMENTS` to extract:
1. **Source** — the first argument is the spec location:
   - If it looks like a file path (`.json`, `.yaml`, `.yml`): read it with the Read tool
   - If it looks like a URL: fetch it with WebFetch
2. **Output path** — the second argument (optional) is where to write the result; default to `<spec-title-kebab-case>.yml` in the current directory

### Step 2 — Gather project context

Glob `**/*.yml` in the current directory to find existing simulation files. Note ports already in use to avoid collisions.

### Step 3 — Analyse the spec

From the OpenAPI document extract:
- **`info.title`** → derive the simulation `name` (PascalCase) and output filename (kebab-case)
- **`servers[0].url`** → base path (strip host; keep path prefix if any)
- **`paths`** → every `{path} × {method}` operation becomes one service:
  - `operationId` or derived name → service name (camelCase verb + subject)
  - `summary` or `description` → service `description`
  - Path parameters (`{param}`) → `Path` trigger + `XB[param]` buffer extraction
  - Query parameters → `Query` buffer extraction
  - `requestBody` schema → `jsonPath` buffer extractions for each property
  - `responses["200"].content` schema → shape the `payload` template

### Step 4 — Generate the SimV1 YAML

**Structure:**
```yaml
schema: SimV1
name: <TitleFromSpec>

connections:
  - name: <TitleFromSpec>Connection
    port: <unused-port-in-17000-17999>
    listen: true

services:
  # one entry per OpenAPI operation
  - name: <operationName>
    description: <summary from spec>
    steps:
      - direction: In
        name: <operationName>Request
        from: <TitleFromSpec>Connection
        trigger:
          # exact path (no params):
          - type: Uri
            value: /base/path/here
          # OR path with params:
          - type: Path
            value: /base/path/*
          - property: Method
            value: GET   # uppercase
        buffer:
          # path params:
          - type: Path
            value: /base/path/{XB[paramName]}
          # body fields:
          - name: fieldName
            jsonPath: fieldName
          # query params:
          - name: qParam
            type: Query
            key: qParam
      - direction: Out
        name: <operationName>Response
        message:
          statusCode: 200
          headers:
            - key: Content-Type
              value: application/json
          payload: |
            <JSON skeleton matching the 200 response schema>
```

**Payload generation rules:**
- For each property in the `200` response schema, emit a placeholder:
  - `string` → `"example"` or `"{b[bufferName]}"` if the value was buffered from the request
  - `integer` / `number` → `0`
  - `boolean` → `false`
  - `array` → `[]`
  - `object` → nested `{}`
- Echo request identifiers back in the response (e.g. if the path had `{id}`, include `"id": "{b[id]}"` in the payload)
- If a `4xx` response is defined, add a second service for the error case (e.g. `404` when a resource is not found), using a `verification` block to trigger it based on a missing/invalid param

**Error service pattern:**
```yaml
  - name: <operationName>NotFound
    description: Returns 404 when resource does not exist
    steps:
      - direction: In
        name: <operationName>NotFoundRequest
        from: <TitleFromSpec>Connection
        trigger:
          - type: Path
            value: /path/*
          - property: Method
            value: GET
        buffer:
          - type: Path
            value: /path/{XB[id]}
      - direction: Out
        name: <operationName>NotFoundResponse
        message:
          statusCode: 404
          headers:
            - key: Content-Type
              value: application/json
          payload: |
            { "error": "Resource not found", "id": "{b[id]}" }
```

**Ordering:** list services in the same order as paths appear in the spec. Place more specific paths (fewer wildcards) before wildcard paths.

### Step 5 — Write the file

Write the generated simulation YAML to the output path.

### Step 6 — Report back

Print a concise summary:
- Output file path
- Port assigned
- Table of all generated services: `METHOD /path → serviceName`
- Any operations skipped or simplified (e.g. missing response schema) and why
- Recommended next steps (load in Tricentis Simulation, point tests at `http://localhost:<port>`)
