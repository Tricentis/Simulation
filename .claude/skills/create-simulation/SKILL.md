---
name: create-simulation
description: Scaffold a new Tricentis Simulation YAML file. Accepts a free-form description of the service to simulate (e.g. "a GET /users/{id} endpoint that returns user details, port 17080").
argument-hint: <description of the service to simulate>
allowed-tools: Read, Write, Glob, WebFetch
---

Create a new Tricentis Simulation YAML file based on the user's description: **$ARGUMENTS**

## Your task

Generate a complete, valid `SimV1` simulation file and write it to disk. Follow these steps precisely.

### Step 1 — Gather context

Read any existing simulation files in the current directory (glob `**/*.yml`) so you can:
- Match the port numbering convention already in use (avoid collisions)
- Follow naming conventions used in the project

### Step 1b — Consult official documentation when needed

If the user's description involves features you are uncertain about — such as unfamiliar trigger types, buffer extraction patterns, resource operations, expressions, or multi-step flow control — fetch the official Tricentis Simulation documentation **before** generating the YAML:

```
https://docs.tricentis.com/tosca-cloud/en-us/content/api_simulation/sim_get_started.htm
```

Typical reasons to fetch the docs:
- The description mentions a feature not covered by the patterns in Step 3 (e.g. `verify`, `use`, `templates`, `includes`, XML/SOAP handling, learning mode, forwarding)
- You are unsure of the correct field name, allowed values, or nesting for a construct
- The description asks for an expression (`{MATH[...]}`, `{TRY[...]}`, `{REGEX[...]}`, etc.) whose syntax you cannot recall precisely

If the top-level page does not contain the detail you need, follow any relevant links on that page to sub-topics (e.g. trigger reference, expression reference, resource operations).

You do **not** need to fetch the docs if the description maps cleanly to the patterns already in Step 3.

### Step 2 — Determine file details

From the user's description, infer:
- **Service name**: PascalCase, e.g. `UserService`
- **Output filename**: kebab-case matching the service, e.g. `user-service.yml`, placed in the current directory (or an appropriate subdirectory if the project uses one)
- **Port**: pick an unused port in the 17000–17999 range
- **Endpoints**: derive path, HTTP method(s), and expected request/response shape from the description

If the description is ambiguous about required fields, use sensible defaults and add a comment in the YAML noting the assumption.

### Step 3 — Generate the YAML

Follow these rules strictly:

**Top-level structure** (in this order):
```yaml
schema: SimV1
name: <ServiceName>
# include resources block only if stateful (CSV/KeyValue backing) was requested
connections:
  - name: <ServiceName>Connection
    port: <port>
    listen: true
services:
  - ...
```

**Each service** must have:
- `name`: verb + subject in camelCase, e.g. `getUser`, `createOrder`
- `description`: one sentence
- `steps`: always exactly two steps — `In` then `Out`

**`In` step** pattern:
```yaml
- direction: In
  name: <serviceName>Request
  from: <ConnectionName>
  trigger:
    - type: Uri          # for exact paths
      value: /path/here
    # OR:
    - type: Path         # for paths with parameters
      value: /path/*
    - property: Method
      value: GET         # uppercase HTTP verb
  buffer:
    # Extract path params using XB:
    - type: Path
      value: /path/{XB[paramName]}
    # Extract JSON body fields:
    - name: fieldName
      jsonPath: fieldName
    # Extract query params:
    - name: paramName
      type: Query
      key: paramName
```

**`Out` step** pattern:
```yaml
- direction: Out
  name: <serviceName>Response
  message:
    statusCode: 200
    headers:
      - key: Content-Type
        value: application/json
    payload: |
      {
        "field": "{b[bufferName]}"
      }
```

**Expression cheatsheet** — use these in `payload` and `value` fields:
- `{b[name]}` — value from buffer
- `{RND[5]}` — random 5-digit number (use for generated IDs)
- `{DATE}` — current timestamp
- `{FROM[resource][column][pkCol=='{b[id]}']}` — lookup from CSV resource

**Resource blocks** — only add if the user asked for stateful/CRUD behavior:
```yaml
resources:
  - name: <resourceName>
    type: Table
    file: <resourceName>.csv
```
And in the `Out` step:
```yaml
resource:
  insert:
    - ref: <resourceName>
      value: ["{b[id]}", "{b[field]}"]
  # or read / update / delete as appropriate
```

### Step 4 — Write the file

Write the generated YAML to the determined output path.

### Step 5 — Report back

Print a brief summary:
- File path written
- Port used
- List of endpoints simulated (METHOD /path)
- Any assumptions made
- Next steps (e.g. "register in appsettings, point your test at http://localhost:<port>")

Do not ask clarifying questions before generating — make reasonable assumptions and document them in your report.
