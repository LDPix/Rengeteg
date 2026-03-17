```mermaid
flowchart TD
    A[Game Director<br>Choose highest-value next feature] --> B[Systems Designer<br>Define rules, scope, and success criteria]
    B --> C{Does it affect UI<br>or map structure?}

    C -->|UI / flow| D[UI/UX Designer<br>Design readability, layout, and player flow]
    C -->|Map / content| E[Content & Map Designer<br>Design objectives, POIs, encounters, and rewards]
    C -->|Mostly systems only| F[Gameplay Programmer<br>Implement approved design]

    D --> F
    E --> F

    F --> G[Content & Map Designer<br>Populate with real content and map data]
    G --> H[QA & Balance Analyst<br>Test, tune, and identify issues]
    H --> I{Good enough?}

    I -->|No| B
    I -->|Yes| J[Game Director<br>Approve and choose next priority]
    J --> A