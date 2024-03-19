<!-- ```mermaid
%%{init: {'theme':'base', 'themeVariables': { 'primaryColor': '#ff7f40', 'edgeLabelBackground':'#ffffff', 'lineColor': '#ff6347', 'mainBkg': '#ffffe0'}}}%%
sequenceDiagram
    participant GitHub as GitHub Workflows
    participant ACR as az-acr Workspace
    participant ACA as az-aca-sbx Workspace
    participant VS as mrb-dotnet-podcasts-vs Variable Set

    GitHub->>ACR: Provision
    Note over ACR: Resource Group\nAzure Container Registry
    ACR->>VS: Update variables with outputs
    Note over GitHub: Build Container Apps
    GitHub->>GitHub: Publish Container Apps using ACR credentials
    GitHub->>ACA: Provision
    Note over ACA: Resource Group\nMSSQL Server\nDatabase\nFirewall Rules\nStorage Account\nStorage Queue\nLog Analytics\nContainer App Env\nContainer App Services
    ACA->>VS: Consume variables

    Note over ACR,ACA: All workspaces access mrb-dotnet-podcasts-vs
```

```mermaid
%%{init: {'theme':'base', 'themeVariables': { 'primaryColor': '#32cd32', 'edgeLabelBackground':'#ffffff', 'lineColor': '#008000', 'mainBkg': '#f0fff0'}}}%%
sequenceDiagram
    participant GH as GitHub Workflows
    participant ACR as az-acr Workspace
    participant ACA as az-aca-sbx Workspace
    participant VS as mrb-dotnet-podcasts-vs Variable Set

    GH->>ACR: 1. Provision az-acr workspace
    Note over ACR: Includes Resource Group,\nAzure Container Registry
    ACR->>GH: Output secrets
    GH->>GH: 2. Build container apps
    GH->>GH: 3. Publish container apps to ACR
    Note over GH: Use outputs from az-acr\nfor credentials
    GH->>ACA: 4. Provision az-aca-sbx workspace
    Note over ACA: Resource Group, MSSQL Server,\nDatabase, Firewall Rules,\nStorage Account, Storage Queue,\nLog Analytics, Container App Env,\nContainer App Services
    ACA->>VS: Consume variables
    Note over ACR,ACA: Access to mrb-dotnet-podcasts-vs

    Note over GH: Orchestrates all jobs and\nmanages workflow progression
``` -->

```mermaid
%%{init: {'theme':'default', 'themeVariables': { 'primaryColor': '#32cd32', 'edgeLabelBackground':'#ffffff', 'mainBkg': '#f0fff0'}}}%%
flowchart LR
    subgraph GH [GitHub Workflows]
        direction LR

        ACR{1. Provision az-acr workspace}
        ACR --> azacr
        subgraph azacr [az-acr Workspace]
            direction TB

            ACR_REGISTRY[
            Resource Group
            Azure Container Registry]
        end

        azacr -- Output Secrets --> vs

        subgraph azacasbx [az-aca-sbx Workspace]
            direction TB

            MSSQL[
            Resource Group
            MSSQL Server
            Database
            Database Firewall Rules
            Storage Account
            Storage Queue
            Log Analytics Workspace
            Container App Environment
            Container App Services]
        end
        
        azacr --> Build{2. Build container apps}        

        subgraph vs [mrb-dotnet-podcasts-vs]
            direction TB

            ACR_OUTPUTS -.-> VS[Variables Updated]
            VS
        end

        Build --> Publish{3. Publish container apps to ACR}
        Publish --> azacasbx{4. Provision az-aca-sbx workspace}
        vs --> azacasbx[Create Resource Group]
    end

    style GH fill:#3ff,stroke:#333,stroke-width:4px
```