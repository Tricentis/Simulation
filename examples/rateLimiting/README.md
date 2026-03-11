# ⏱️ Rate Limiting – API Simulation Example

This example demonstrates how to implement rate limiting in API simulation using service virtualization. It showcases stateful request tracking with a KeyValue resource, time-based counters, and conditional response generation based on request frequency.

---

## 📁 Files

| File | Description |
|------|-------------|
| `rateLimiting.yml` | The simulation definition that implements rate limiting with a 10 requests per minute threshold |

---

## 📦 Simulated API Endpoint

### `GET /limit/request`
- **Purpose:** Demonstrates rate-limited API behavior
- **Behavior:** 
  - Tracks the number of requests received in the current minute
  - Returns a success message if within the limit (< 10 requests)
  - Returns a "limit exceeded" message if the threshold is reached (>= 10 requests)
  - Automatically resets the counter when a new minute begins

#### Example Responses:

**Within Limit (requests 1-9):**
```
received request number 5 limit of 10 requests per minute
```

**Limit Exceeded (request 10+):**
```
received request number 12 which exceeds the limit of 10 requests per minute
```

---

## 🔧 How It Works

### 1. KeyValue Resource for State Persistence

The simulation uses a KeyValue resource to persist request counts:

```yaml
resources:
  - name: requests
    type: KeyValue
```

The KeyValue resource stores key-value pairs where:
- **Key:** The current minute (e.g., `"45"` for minute 45)
- **Value:** The number of requests received during that minute

### 2. Capturing the Current Minute

Each incoming request captures the current minute using the TIME expression:

```yaml
buffer:
  - name: time
    value: "{TIME[][][mm]}"
```

This extracts just the minute component (00-59) from the current time, which serves as the key for tracking requests.

### 3. Incrementing the Request Counter

The counter is updated using a combination of TRY, FROM, and MATH expressions:

```yaml
resource:
  insertOrUpdate:
    - ref: requests
      value:
        "{B[time]}": "{MATH[{TRY[{FROM[requests][][{B[time]}]}][0]} + 1]}"
```

**Expression Breakdown:**
- `{FROM[requests][][{B[time]}]}` – Retrieves the current count for this minute from the KeyValue resource
- `{TRY[...][0]}` – Returns `0` if no entry exists yet (first request of the minute)
- `{MATH[... + 1]}` – Increments the counter by 1
- `insertOrUpdate` – Inserts a new entry or updates an existing one

### 4. Internal Gateway Pattern

The simulation uses an internal client-server pattern to route requests based on the count:

```yaml
- to: service client
  insert:
    - uri: /gate/limit
    - value: "{FROM[requests][][{B[time]}]}"
```

This sends the current request count to an internal gateway endpoint, which then triggers the appropriate response handler.

### 5. Conditional Response Generation

Two services handle the response based on the request count:

**Within Limit Handler (< 10 requests):**
```yaml
- name: within limit
  steps:
    - trigger:
        - uri: /gate/limit
        - value: 10
          operator: Less
```

**Limit Exceeded Handler (>= 10 requests):**
```yaml
- name: limit exceeded
  steps:
    - trigger:
        - uri: /gate/limit
        - value: 10
          operator: GreaterOrEqual
```

---

## 💡 Key Service Virtualization Features

This example demonstrates several powerful service virtualization capabilities:

| Feature | Description |
|---------|-------------|
| **Stateful Simulation** | The KeyValue resource maintains state across multiple requests |
| **Time-Based Logic** | Uses TIME expressions to implement time-windowed behavior |
| **Error Handling with TRY** | Gracefully handles the first request when no counter exists |
| **Conditional Routing** | Uses operator triggers (Less, GreaterOrEqual) to route requests |
| **Internal Gateway Pattern** | Decouples request tracking from response generation |
| **Automatic Reset** | Counter resets naturally as the minute changes |

---

## 🛠 How to Use

1. Start the API Simulator and load `rateLimiting.yml`
2. The service will be available on port **17071**
3. Send requests to test the rate limiting:
   ```bash
   # Send multiple requests
   curl http://localhost:17071/limit/request
   ```
4. Observe the responses:
   - First 9 requests return a "within limit" message
   - 10th request and beyond return a "limit exceeded" message
   - Wait for the next minute to see the counter reset

---

## 🎯 Use Cases

This pattern is particularly useful for simulating:

- **API Rate Limiting**: Testing client behavior when rate limits are enforced
- **Throttling Policies**: Simulating quota-based access controls
- **Usage Metering**: Tracking and limiting API consumption
- **DDoS Protection**: Simulating protection mechanisms against request floods
- **Subscription Tiers**: Different limits for different user levels (extendable)

---

## 🔄 Automatic Counter Reset

A key advantage of this implementation is the automatic counter reset:

1. The counter key is the current minute (`{TIME[][][mm]}`)
2. When the clock moves to the next minute, a new key is used
3. The TRY expression returns `0` for the new key (no existing entry)
4. This effectively resets the counter without any explicit cleanup

---

## 📚 Related Features

- **[TRY Expression](../../features/expressions/try/README.md)**: Error handling for graceful fallback values
- **KeyValue Resource**: In-memory key-value storage for stateful simulations
- **TIME Expression**: Extracting time components for time-based logic
- **MATH Expression**: Performing arithmetic operations in expressions

---

🔒 This example demonstrates advanced stateful simulation capabilities and can be extended to support more complex rate limiting scenarios such as sliding windows, user-specific limits, or tiered throttling.
