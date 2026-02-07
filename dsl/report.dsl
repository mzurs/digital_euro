workspace "2.3.1 Functional domains (three-layer architecture)" {

    model {
        user_domain = softwareSystem "User Domain" {
            paymentInstruments = container "Payment Instruments" "cards, wearables, devices" "UserDomain"
            userInterfaces = container "User-to-App Interfaces" "mobile apps, web portals, banking apps" "UserDomain"
            acceptanceSolutions = container "Acceptance Solutions" "NFC, QR code, payment links" "UserDomain"
        }

        psp_domain = softwareSystem "PSP Domain" {
            distributing = container "Distributing PSP Services"  "PSPDomain"
            acquiring = container "Acquiring PSP Services"   "PSPDomain"
        }

        desp_domain = softwareSystem "DESP Domain" {
            accessSvc = container "Access Management Service" "" "DESPDomain"
            liquiditySvc = container "Liquidity Management Service" "" "DESPDomain"
            transactionSvc = container "Transaction Management Service" "" "DESPDomain"
        }
        
        api_interfaces = softwareSystem "API Interfaces" {
        apiGateway = container "API Interface" "Routes traffic and handles auth based on PSP ID" "Nginx/Kong"
        }
        
        paymentInstruments -> apiGateway  
        userInterfaces -> apiGateway  
        acceptanceSolutions -> apiGateway  
        
        distributing -> apiGateway  
        acquiring -> apiGateway  

        accessSvc -> apiGateway  
        liquiditySvc -> apiGateway  
        transactionSvc -> apiGateway  
        
        # apiGateway -> paymentInstruments
        # apiGateway -> userInterfaces
        # apiGateway -> acceptanceSolutions
        # apiGateway -> distributing
        # apiGateway -> acquiring
        # apiGateway -> accessSvc
        # apiGateway -> liquiditySvc
        # apiGateway -> transactionSvc
    }

    views {
        // Single view showing ALL software systems + their containers + relationships
        container api_interfaces "Functional-Domains" {
            include  apiGateway paymentInstruments userInterfaces  acceptanceSolutions distributing acquiring accessSvc liquiditySvc transactionSvc
            autoLayout tb
        }
        
        theme default

       styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element  "User Domain"  {
                shape Person
                background #08427b
                color #ffffff
            }
            element "DESP Domain" {
                background #438dd5
                color #ffffff
            }
            element "REST API Interface" {
                // Highlight the shared component differently
                background #90EE90
                color #000000
            }
        }
        }
    }


workspace "2.3.2 Operational Mechanics (High-Level Flow) PSP Digital Euro Distribution" "High-level flow: treasury/liquidity → Eurosystem → PSP interface → customer wallets." {

  model {
    psp = softwareSystem "Payment Service Provider (PSP)" "Provides digital euro distribution to customers." {
      treasury = container "Treasury / Liquidity Management" "Manages liquidity and funding for digital euro operations." "Business"
      dca = container "PSP Dedicated Cash Account (DCA)" "Account used for liquidity transfers to/from the Eurosystem." "Bank Account"
      distribution = container "Digital Euro Interface / Distribution Layer" "PSP-facing interface and distribution services for digital euro." "Application"
      wallets = container "Individual Customer Digital Euro Wallets" "End-user wallets holding digital euro balances." "Mobile/Web"
    }

    eurosystem = softwareSystem "Eurosystem (DESP)" "Digital Euro Service Provider: issuance/redemption and settlement execution."

    treasury -> dca "Liquidity transfer to / from"
    dca -> eurosystem "Liquidity transfer / funding and settlement instructions"
    eurosystem -> distribution "Issuance / redemption and settlement execution"
    distribution -> wallets "Distributes digital euro services to"
  }

  views {
    container psp {
      include treasury
      include dca
      include distribution
      include wallets
      include eurosystem
      
    #   autoLayout topBottom
      title "PSP digital euro distribution – container view"
    }

    styles {
      element "Software System" {
        background "#1168bd"
        color "#ffffff"
      }
      element "Container" {
        background "#438dd5"
        color "#ffffff"
      }
    }
  }}

workspace "5.1.1 Digital Euro — In-House Implementation (Logical View)" "Structurizr DSL model for the in-house microservices architecture (scheme-aligned boundary)" {

  !identifiers hierarchical

  model {
    bankCustomer = person "Bank/PSP Customer" "Retail or business user accessing digital euro services via bank/PSP channels."

    bankChannels = softwareSystem "Bank/PSP Customer Interfaces" "Customer-facing channels: Mobile app, Web, Merchant/Acquiring UI, Branch systems, ATM/POS touchpoints." {
      tags "Channel"
    }

    inHousePlatform = softwareSystem "Bank/PSP In-House Digital Euro Platform" "In-house integration layer implementing customer-facing services and scheme connectivity." {
      tags "BankPlatform"

      apiGateway = container "API Gateway & Orchestration" "Entry point for channels; authentication/authorization, routing, idempotency, rate limits, auditing." "API Gateway" {
        tags "Gateway"
      }

      accessWallet = container "Access & Wallet Services" "Onboarding, wallet lifecycle, alias management, customer support tooling." "Microservices" {
        tags "Service"
      }

      payments = container "Payments & Exceptions Services" "Payment initiation, authorization decisioning, exception handling, reconciliation workflows." "Microservices" {
        tags "Service"
      }

      liquidityLimits = container "Liquidity & Limits Services" "Funding/unfunding orchestration, holding-limit support, (reverse) waterfall triggers, notifications." "Microservices" {
        tags "Service"
      }

      riskCompliance = container "Risk/Compliance + Privacy Controls" "Online-flow screening where applicable (AML/sanctions), fraud/risk scoring, reporting; privacy controls (data minimisation/consent)." "Microservices" {
        tags "Service"
      }

      offlineEnablement = container "Offline Enablement Service" "Credential provisioning, offline limits, post-offline sync controls; offline transaction details remain private between payer/payee." "Microservices" {
        tags "Service"
      }

      despConnector = container "DESP Connector / Scheme Interface Adapter" "Scheme-compliant APIs/messaging per rulebook & technical standards; retries/queues/telemetry." "Integration Adapter" {
        tags "Adapter"
      }
    }

    desp = softwareSystem "DESP (External — Eurosystem platform/services)" "Eurosystem digital euro services/platform: settlement/ledger and scheme services exposed via standardised interfaces." {
      tags "External,SystemOfRecord"
    }

    bankCustomer -> bankChannels "Uses" "UI"
    bankChannels -> inHousePlatform.apiGateway "Calls" "HTTPS"

    inHousePlatform.apiGateway -> inHousePlatform.accessWallet "Routes requests to"
    inHousePlatform.apiGateway -> inHousePlatform.payments "Routes requests to"
    inHousePlatform.apiGateway -> inHousePlatform.liquidityLimits "Routes requests to"

    inHousePlatform.accessWallet -> inHousePlatform.riskCompliance "Requests compliance/privacy checks for online onboarding/events"
    inHousePlatform.payments -> inHousePlatform.riskCompliance "Requests risk/compliance checks for online flows"
    inHousePlatform.liquidityLimits -> inHousePlatform.riskCompliance "Requests compliance checks for funding/unfunding where applicable"

    inHousePlatform.riskCompliance -> inHousePlatform.offlineEnablement "Coordinates offline enablement policies/limits (no tx content exposure)"
    inHousePlatform.offlineEnablement -> inHousePlatform.despConnector "Synchronises and reconciles (post-offline)"

    inHousePlatform.payments -> inHousePlatform.despConnector "Sends scheme messages / requests status"
    inHousePlatform.liquidityLimits -> inHousePlatform.despConnector "Manages limits/funding orchestration via scheme interfaces"
    inHousePlatform.accessWallet -> inHousePlatform.despConnector "Registers/updates wallet-related scheme identifiers (as specified)"

    inHousePlatform.despConnector -> desp "Invokes scheme/platform interfaces" "Scheme API/Messaging"
  }

  views {
    container inHousePlatform "InHouse_Microservices_Logical" "Microservices architecture approach (scheme-aligned boundary)" {
      include *
      include bankCustomer
      autoLayout tb
    }

    styles {
      element "Person" {
        shape person
      }
      element "Channel" {
        shape roundedbox
      }
      element "Gateway" {
        shape hexagon
      }
      element "Service" {
        shape roundedbox
      }
      element "Adapter" {
        shape component
      }
      element "External" {
        background #eeeeee
        color #000000
        border dashed
      }
      element "SystemOfRecord" {
        shape cylinder
      }

      relationship "Relationship" {
        routing Orthogonal
        dashed true
      }
    }

    theme default
  }
}

workspace "5.1.1 Integration with Existing Systems" "Structurizr DSL for enterprise-to-digital-euro integration layering" {

  !identifiers hierarchical

  model {
    // --- Software Systems (3 layers + DESP) ----------------------------------

    coreEnterprise = softwareSystem "Core Banking / Enterprise Systems" "Existing bank/PSP systems of record and control functions supporting digital euro distribution." {
      tags "CoreLayer"

      customerKyc = container "Customer Master Data + Identity/KYC" "Customer profile, identity proofing, onboarding status, KYC/AML customer due diligence inputs." "System" {
        tags "CoreSystem"
      }
      linkedAccounts = container "Linked Accounts / Funding Sources" "Deposit accounts and funding sources linked to the digital euro wallet (funding/unfunding orchestration)." "System" {
        tags "CoreSystem"
      }
      treasury = container "Treasury / Liquidity & Limit Governance" "Liquidity policies, limit governance, treasury controls and reporting." "System" {
        tags "CoreSystem"
      }
      glRecon = container "General Ledger + Reconciliation" "Financial postings, reconciliation workflows, audit support." "System" {
        tags "CoreSystem"
      }
      regReporting = container "Regulatory Reporting" "Regulatory reporting pipelines and reporting outputs." "System" {
        tags "CoreSystem"
      }
      consentPrivacy = container "Consent & Privacy Register (GDPR)" "Consent management and data-minimisation controls for personal data processing." "System" {
        tags "CoreSystem"
      }
      siemSoc = container "SIEM/SOC + Incident Response (DORA)" "Security monitoring, incident response, operational resilience controls and evidence." "System" {
        tags "CoreSystem"
      }
    }

    digitalEuroLayer = softwareSystem "Digital Euro Microservices" "Bank/PSP distribution layer implementing wallet, payments and operational controls, and integrating to the scheme boundary." {
      tags "DigitalEuroLayer"

      accessWallet = container "Access & Wallet" "Onboarding, wallet lifecycle, alias management, customer support tooling." "Microservices" {
        tags "Microservices"
      }
      liquidityLimits = container "Liquidity & Limits" "Funding/unfunding orchestration, holding-limit support, waterfall/reverse-waterfall triggers where applicable." "Microservices" {
        tags "Microservices"
      }
      txnMgmt = container "Transaction Management" "Payment initiation, status, exceptions, reconciliation events and workflows." "Microservices" {
        tags "Microservices"
      }
      riskCompliance = container "Risk/Compliance (online + funding/unfunding)" "Controls and reporting for online flows and funding/unfunding; privacy-aware monitoring." "Microservices" {
        tags "Microservices"
      }
      offlineEnablement = container "Offline Enablement" "Credential provisioning, offline limits, post-offline sync and reconciliation controls." "Microservices" {
        tags "Microservices"
      }
      secKeyMgmt = container "Security & Key Management" "HSM/PKI-backed key management, signing/encryption, secrets management, audit evidence and security services." "Security" {
        tags "Security"
      }
    }

    schemeBoundary = softwareSystem "External / Scheme Boundary" "Controlled boundary components that interface with the digital euro scheme/platform and supporting external ecosystems." {
      tags "BoundaryLayer"

      schemeAdapter = container "Scheme Interface Adapter / DESP Connector" "Scheme-compliant adapter: message/API handling, validation, retries, telemetry, versioning." "Integration Adapter" {
        tags "IntegrationAdapter"
      }
      deviceEcosystem = container "Device Security Ecosystem (as applicable)" "Secure element/TEE providers, credential provisioning dependencies, device trust chain components." "External Services" {
        tags "ExternalServices"
      }
      securityLabs = container "Third-party security testing / certification labs (as applicable)" "External penetration testing, certification and independent assurance activities." "External Services" {
        tags "ExternalServices"
      }
    }

    desp = softwareSystem "DESP (External – Eurosystem platform/services)" "External platform/services for the digital euro scheme (settlement/ledger and scheme services via standardised interfaces)." {
      tags "ExternalPlatform"
    }

    // --- Relationships (match the layered arrows) -----------------------------

    // Core -> Digital Euro layer
    coreEnterprise.customerKyc -> digitalEuroLayer.accessWallet "Provides identity/KYC status & customer master data"
    coreEnterprise.consentPrivacy -> digitalEuroLayer.accessWallet "Provides consent/privacy controls"
    coreEnterprise.linkedAccounts -> digitalEuroLayer.liquidityLimits "Provides linked funding sources"
    coreEnterprise.treasury -> digitalEuroLayer.liquidityLimits "Provides liquidity policies & limit governance inputs"
    coreEnterprise.glRecon -> digitalEuroLayer.txnMgmt "Posts/reconciles transactions and events"
    coreEnterprise.regReporting -> digitalEuroLayer.riskCompliance "Consumes compliance/reporting outputs"
    coreEnterprise.siemSoc -> digitalEuroLayer.secKeyMgmt "Monitors security events; incident response coordination"
    coreEnterprise.siemSoc -> digitalEuroLayer.txnMgmt "Monitors operational/security signals"

    // Digital Euro layer -> Scheme boundary
    digitalEuroLayer.accessWallet -> schemeBoundary.schemeAdapter "Invokes scheme interface for wallet-related operations (as specified)"
    digitalEuroLayer.liquidityLimits -> schemeBoundary.schemeAdapter "Invokes scheme interface for limits/funding orchestration (as specified)"
    digitalEuroLayer.txnMgmt -> schemeBoundary.schemeAdapter "Invokes scheme interface for payment initiation/status and reconciliation events"
    digitalEuroLayer.riskCompliance -> schemeBoundary.schemeAdapter "Sends/receives scheme-related compliance events (as applicable)"
    digitalEuroLayer.offlineEnablement -> schemeBoundary.schemeAdapter "Synchronises post-offline events and performs reconciliation controls"
    digitalEuroLayer.secKeyMgmt -> schemeBoundary.schemeAdapter "Supports secure communications and signing/encryption for scheme messages"

    // Boundary -> External platform and ecosystems
    schemeBoundary.schemeAdapter -> desp "Connects to scheme/platform interfaces" "Scheme API/Messaging"
    schemeBoundary.deviceEcosystem -> digitalEuroLayer.offlineEnablement "Supports credential provisioning/device trust (as applicable)"
    schemeBoundary.securityLabs -> digitalEuroLayer.secKeyMgmt "Performs assurance/testing; provides findings and reports"
  }

  views {
    // High-level layered view (systems only)
    systemLandscape "Integration_Landscape" "Integration with Existing Systems (layered view)" {
      include coreEnterprise
      include digitalEuroLayer
      include schemeBoundary
      include desp
      autoLayout tb
    }

    // Detailed view: digital euro containers + the *other* layer containers they integrate with
    container digitalEuroLayer "DigitalEuroLayer_Containers" "Digital Euro microservices and their enterprise/boundary integrations" {

      // all Digital Euro containers (in-scope system)
      include "element.type==Container && element.parent==digitalEuroLayer"

      // enterprise containers participating in integrations
      include "element.type==Container && element.parent==coreEnterprise"

      // boundary containers participating in integrations
      include "element.type==Container && element.parent==schemeBoundary"

      // external platform
      include desp

      autoLayout tb
    }

    styles {
      element "CoreLayer" {
        shape roundedbox
      }
      element "DigitalEuroLayer" {
        shape roundedbox
      }
      element "BoundaryLayer" {
        shape roundedbox
        border dashed
      }
      element "ExternalPlatform" {
        shape cylinder
        border dashed
      }

      element "CoreSystem" {
        shape roundedbox
      }
      element "Microservices" {
        shape roundedbox
      }
      element "Security" {
        shape hexagon
      }
      element "IntegrationAdapter" {
        shape component
      }
      element "ExternalServices" {
        shape roundedbox
        border dashed
      }
    }

    theme default
  }
}

workspace "5.3.2 – Hybrid Implementation Architecture" "Hybrid model: bank value-added services + vendor core integration + shared integration layer to Eurosystem/scheme." {

  !identifiers hierarchical

  model {
    customer = person "Bank Customer / User" "Retail or corporate user consuming digital euro services via bank channels."

    bank = softwareSystem "Bank" "PSP providing digital euro services to customers." {
      tags "Bank"

      interfaces = container "Bank Customer Interfaces" "Mobile app, web banking, ATM, POS, corporate treasury channels." "Channels" {
        tags "Bank"
      }

      valueAdded = container "Bank-Developed Value-Added Services" "Advanced fraud, conditional logic, cash/treasury features, analytics overlays." "Microservices" {
        tags "Bank"
      }

      integration = container "Integration Layer / APIs" "Shared integration boundary (APIs/events), routing, protocol adaptation, observability, security controls." "API / Integration" {
        tags "Bank"
      }
    }

    vendor = softwareSystem "Vendor Platform" "Third-party platform providing core digital euro integration capabilities." {
      tags "Vendor"

      vendorCore = container "Vendor Platform Core Integration" "Connectivity, baseline transaction management, baseline liquidity, standard compliance capabilities." "SaaS / Managed Platform" {
        tags "Vendor"
      }
    }

    eurosystem = softwareSystem "Eurosystem / Digital Euro Scheme Services" "External scheme services (settlement, liquidity, scheme APIs, rulebook-governed interfaces)." {
      tags "External"
    }

    customer -> bank.interfaces "Uses digital euro services" "Mobile/Web/ATM/POS"

    bank.interfaces -> bank.valueAdded "Invokes value-added features" "HTTPS/REST"
    bank.interfaces -> vendor.vendorCore "Uses vendor core integration features" "HTTPS/REST"

    bank.valueAdded -> bank.integration "Calls integration APIs / publishes events" "HTTPS/REST + Events"
    vendor.vendorCore -> bank.integration "Calls integration APIs / publishes events" "HTTPS/REST + Events"

    bank.integration -> eurosystem "Connects via scheme interfaces" "Scheme APIs (HTTPS/REST, messaging)"
  }

  views {
    container bank "Hybrid" {
      include *
      autolayout lr
    }

    styles {
      element "Person" {
        shape person
        background #ffffff
        color #000000
      }

      element "Bank" {
        background #1f77b4
        color #ffffff
      }

      element "Vendor" {
        background #ff7f0e
        color #ffffff
      }

      element "External" {
        background #7f7f7f
        color #ffffff
      }

      element "Container" {
        shape roundedbox
      }

      relationship "Relationship" {
        color #707070
        thickness 2
      }
    }

    theme default
  }
}

workspace "8.1 Bank Digital Euro Integration – Implementation Architecture" "Refined implementation stack for a bank/PSP integrating with the Eurosystem Digital Euro Service Platform (DESP)." {

  !identifiers hierarchical

  model {
    customer = person "Customer" "Retail or corporate user initiating and receiving digital euro payments."

    bank = softwareSystem "Bank / PSP" "Digital euro distribution layer operated by a supervised bank/PSP." {
      tags "Bank"

      mobileApp = container "Mobile Banking App" "Customer-facing mobile channel for digital euro wallet and payments." "iOS/Android"
      webPortal = container "Web Portal" "Customer-facing web channel for digital euro wallet and payments." "Web"
      posIntegration = container "POS / Merchant Channel Integration" "Merchant acceptance integration (POS/eCom enablement, merchant tools)." "Channel Integration"
      atmInterface = container "ATM Interface" "ATM channel integration for cash-like funding/defunding operations (where applicable)." "Channel Integration"

      apiGateway = container "API Gateway" "Single entry point for channels; routing, throttling, WAF integration, authN/Z enforcement, and API observability headers." "Kong / AWS API Gateway"
      channelBff = container "Channel API / BFF" "Channel-specific aggregation layer; reduces coupling between channels and domain services." "Microservice"

      orchestration = container "Payment Orchestration & Workflow" "Low-latency orchestration (Saga/workflow) for payment journeys; retries, idempotency coordination, compensations, and audit trails." "Temporal / Camunda / Saga Orchestrator"

      accessSvc = container "Access & Wallet Management Service" "Onboarding, wallet provisioning, alias/device binding, consent, wallet lifecycle." "Go / Java"
      liquiditySvc = container "Liquidity & Limits Service" "Funding/defunding, holding/usage limits, liquidity monitoring, waterfall/reverse-waterfall triggers (where applicable)." "Node.js / Java"
      txnSvc = container "Transaction Processing Service" "Payment initiation, authorization, state machine, status tracking, exceptions/disputes hooks." "Java"
      riskSvc = container "Risk & Compliance Service" "Fraud scoring, AML/CFT screening hooks, sanctions checks, monitoring signals, compliance reporting interfaces." "Python/ML + Rules"
      offlineSvc = container "Offline Wallet & Device Security Service" "Offline wallet lifecycle, secure element/TEE provisioning, offline limits, anti-replay controls, re-sync workflows." "C/C++ + SDKs"

      reconcileSvc = container "Reconciliation & Ledger Posting" "Reconciliation, settlement alignment, postings to core ledger/GL, statements, operational reporting." "Batch + Streaming"

      schemeAdapter = container "DESP Connectivity / Scheme Adapter" "Boundary service to DESP: mTLS, message signing, idempotent request handling, retries, versioning, correlation IDs, and reconciliation feeds." "REST Client / Adapter"

      eventBus = container "Event Bus" "Event streaming for domain events, audit events, and operational telemetry (async integration between services)." "Kafka"
      cache = container "Cache / Session Store" "Caching, rate-limit state, sessions, idempotency keys (where used)." "Redis"

      txnDb = container "Transactional Store" "Transactional persistence for wallet/payment state and reconciliation artefacts." "PostgreSQL" {
        tags "Database"
      }
      docDb = container "Operational Document Store" "Operational documents (cases, investigations, configs, device metadata) where suited." "MongoDB" {
        tags "Database"
      }
      searchDb = container "Search / Analytics Index" "Searchable index for transactions/cases (careful with privacy/data minimisation)." "Elasticsearch / OpenSearch" {
        tags "Database"
      }

      observability = container "Observability Stack" "Central logging, metrics, tracing; SLOs; alerting; dashboards; audit log retention." "OpenTelemetry + SIEM/Monitoring"
      keyMgmt = container "Key Management / HSM" "Key custody and cryptographic operations (signing, encryption), secrets management, key rotation." "HSM / KMS"
    }

    coreBanking = softwareSystem "Core Banking / GL" "Customer accounts, general ledger, statements, postings, master data." {
      tags "External"
    }

    kycAml = softwareSystem "KYC/AML & Sanctions Systems" "Customer due diligence, sanctions lists, AML monitoring/case mgmt (bank tooling)." {
      tags "External"
    }

    treasury = softwareSystem "Treasury / Liquidity Systems" "Funding, liquidity forecasting, intraday monitoring, limits." {
      tags "External"
    }

    eurosystem = softwareSystem "Eurosystem Digital Euro Platform (DESP)" "External infrastructure providing scheme services (settlement/liquidity/scheme APIs) operated by the Eurosystem." {
      tags "External"
    }

    merchantAcq = softwareSystem "Acquirer / Merchant Processing (optional)" "Merchant/acquiring ecosystem integration where bank provides acquiring or partners with an acquirer." {
      tags "External"
    }

    customer -> bank.mobileApp "Uses"
    customer -> bank.webPortal "Uses"

    bank.mobileApp -> bank.apiGateway "Calls" "HTTPS"
    bank.webPortal -> bank.apiGateway "Calls" "HTTPS"
    bank.posIntegration -> bank.apiGateway "Calls" "HTTPS"
    bank.atmInterface -> bank.apiGateway "Calls" "HTTPS"

    bank.apiGateway -> bank.channelBff "Routes requests to" "HTTPS"
    bank.channelBff -> bank.orchestration "Starts/continues workflows" "HTTPS/gRPC"

    bank.orchestration -> bank.accessSvc "Orchestrates wallet lifecycle" "HTTPS/gRPC"
    bank.orchestration -> bank.liquiditySvc "Orchestrates funding/limits flows" "HTTPS/gRPC"
    bank.orchestration -> bank.txnSvc "Orchestrates payment state machine" "HTTPS/gRPC"
    bank.orchestration -> bank.riskSvc "Requests risk/compliance decisions" "HTTPS/gRPC"
    bank.orchestration -> bank.offlineSvc "Coordinates offline lifecycle events" "HTTPS/gRPC"
    bank.orchestration -> bank.reconcileSvc "Triggers reconciliation/posting" "Events/HTTPS"

    bank.accessSvc -> bank.txnDb "Reads/Writes"
    bank.liquiditySvc -> bank.txnDb "Reads/Writes"
    bank.txnSvc -> bank.txnDb "Reads/Writes"
    bank.riskSvc -> bank.docDb "Reads/Writes cases/configs"
    bank.offlineSvc -> bank.docDb "Reads/Writes device metadata"
    bank.reconcileSvc -> bank.txnDb "Reads/Writes"
    bank.txnSvc -> bank.searchDb "Indexes searchable views (minimised)" "Async"
    bank.riskSvc -> bank.searchDb "Indexes case/search views (minimised)" "Async"

    bank.accessSvc -> bank.eventBus "Publishes domain/audit events"
    bank.liquiditySvc -> bank.eventBus "Publishes domain/audit events"
    bank.txnSvc -> bank.eventBus "Publishes domain/audit events"
    bank.riskSvc -> bank.eventBus "Publishes alerts/decisions"
    bank.offlineSvc -> bank.eventBus "Publishes device/offline events"
    bank.reconcileSvc -> bank.eventBus "Publishes reconciliation events"

    bank.eventBus -> bank.observability "Feeds operational telemetry (selected)" "Pipelines"
    bank.apiGateway -> bank.observability "Emits access logs/metrics/traces"
    bank.schemeAdapter -> bank.observability "Emits correlation + error telemetry"
    bank.keyMgmt -> bank.accessSvc "Provides crypto ops" "HSM/KMS API"
    bank.keyMgmt -> bank.schemeAdapter "Provides mTLS keys/signing" "HSM/KMS API"
    bank.keyMgmt -> bank.offlineSvc "Provides secure provisioning keys" "HSM/KMS API"

    bank.accessSvc -> kycAml "KYC/AML checks (onboarding)" "API"
    bank.riskSvc -> kycAml "Sanctions/AML screening + case mgmt hooks" "API"
    bank.liquiditySvc -> treasury "Liquidity operations/monitoring" "API"

    bank.reconcileSvc -> coreBanking "Postings, statements, GL entries" "Batch/Events"
    bank.accessSvc -> coreBanking "Customer master/account linkage" "API"
    bank.txnSvc -> coreBanking "Balance/account inquiries (if needed)" "API"

    bank.posIntegration -> merchantAcq "Merchant acquiring/processing (if applicable)" "API"

    bank.schemeAdapter -> eurosystem "Connects to scheme services" "mTLS + REST"
    bank.txnSvc -> bank.schemeAdapter "Submits payment instructions / status queries" "HTTPS"
    bank.liquiditySvc -> bank.schemeAdapter "Liquidity/limits operations" "HTTPS"
    bank.reconcileSvc -> bank.schemeAdapter "Reconciliation feeds / reports" "HTTPS/Batch"
  }

  views {
    systemContext bank "SystemContext_Bank_DESP" {
      include *
      autoLayout lr
    }

    container bank "ContainerView_Impl_Architecture" {
      include *
      autoLayout lr
    }

    styles {
      element "Person" {
        shape person
        background #ffffff
        color #000000
      }

      element "Bank" {
        background #1f77b4
        color #ffffff
      }

      element "External" {
        background #6c757d
        color #ffffff
      }

      element "Database" {
        shape cylinder
      }

      element "Container" {
        shape roundedbox
      }

      relationship "Relationship" {
        color #707070
        thickness 2
      }
    }

    theme default
  }
}

workspace "8.1_Access Management Service (PSP Distribution Layer) Digital Euro – Access Management Service" "Access & wallet lifecycle service for a bank/PSP integrating digital euro capabilities." {

  !identifiers hierarchical

  model {
    customer = person "Customer" "Retail/corporate customer using the bank channels."

    bank = softwareSystem "Bank / PSP" "Digital euro distribution layer operated by the bank/PSP." {
      tags "Bank"

      apiGateway = container "API Gateway" "Entry point for channels; authN/Z, throttling, routing, WAF integration." "Kong / AWS API Gateway"

      accessSvc = container "Access Management Service" "Onboarding/offboarding, wallet identity binding, alias management, consent and lifecycle events." "Go" {

        accessApi = component "Access API" "HTTP handlers for onboarding/offboarding/alias/status endpoints." "Go"
        onboardingOrch = component "Onboarding Orchestrator" "Implements idempotent onboarding flow; drives KYC + provisioning; records state transitions." "Go"
        offboardingOrch = component "Offboarding Orchestrator" "Implements closure workflow; revokes bindings; coordinates with liquidity/wallet closure." "Go"
        aliasManager = component "Alias Manager" "Validates ownership/consent; registers aliases; ensures uniqueness; emits alias events." "Go"
        identityKycAdapter = component "Identity/KYC Adapter" "Encapsulates calls to KYC/ID systems; circuit breaker + retries; normalizes responses." "Go"
        provisioningAdapter = component "Provisioning Adapter" "Calls wallet provisioning; persists scheme identifier mapping; handles retries safely." "Go"
        statusAggregator = component "Status Aggregator" "Returns lifecycle state; optionally calls Liquidity service for balance/limits." "Go"
        auditLogger = component "Audit Logger" "Creates immutable audit events for key lifecycle actions." "Go"
        idempotencyManager = component "Idempotency Manager" "Stores/replays results for safe retries; prevents duplicate wallets/aliases." "Go"
      }

      accessDb = container "Access DB" "Stores user/wallet mappings, alias references, lifecycle state, idempotency keys (no raw KYC docs)." "PostgreSQL" {
        tags "Database"
      }

      eventBus = container "Event Bus" "Publishes lifecycle and audit events for downstream services." "Kafka"
      observability = container "Observability" "Central logs/metrics/traces + alerting; supports audit retention." "OpenTelemetry + SIEM"
      keyMgmt = container "Key Management/HSM" "Cryptographic keys for mTLS, signing, secrets, and sensitive operations." "HSM/KMS"
    }

    kyc = softwareSystem "KYC/AML & Identity Verification" "Customer verification, sanctions screening hooks, document validation and CDD checks." {
      tags "External"
    }

    customerMaster = softwareSystem "Customer Master / Core Banking" "Authoritative customer master data and account linkage." {
      tags "External"
    }

    walletProvisioning = softwareSystem "Wallet Provisioning Service" "Creates/initialises digital euro wallet/account reference; returns scheme identifier." {
      tags "External"
    }

    liquidity = softwareSystem "Liquidity / Limits Service" "Authoritative balance/limits/holding checks and funding/defunding orchestration." {
      tags "External"
    }

    notifications = softwareSystem "Notification Service" "Customer notifications (email/SMS/push) for lifecycle events." {
      tags "External"
    }

    // --- Container-level relationships ---
    customer -> bank.apiGateway "Calls via channel apps" "HTTPS"
    bank.apiGateway -> bank.accessSvc "Routes Access API calls" "HTTPS"

    bank.accessSvc -> bank.accessDb "Reads/Writes lifecycle state, mappings, idempotency keys" "SQL"
    bank.accessSvc -> kyc "Requests verification / receives results" "API"
    bank.accessSvc -> customerMaster "Fetches customer master/account linkage" "API"
    bank.accessSvc -> walletProvisioning "Requests wallet provisioning" "API"
    bank.accessSvc -> liquidity "Reads balance/limits view (optional aggregation for /status)" "API"
    bank.accessSvc -> notifications "Sends customer notifications" "API"

    bank.accessSvc -> bank.eventBus "Publishes lifecycle/audit events" "Events"
    bank.accessSvc -> bank.observability "Emits logs/metrics/traces" "OTel"
    bank.accessSvc -> bank.keyMgmt "Uses keys for mTLS/signing/secrets" "HSM/KMS API"

    // --- Component relationships (use component identifiers) ---
    bank.accessSvc.accessApi -> bank.accessSvc.onboardingOrch "Invokes for /users/onboard"
    bank.accessSvc.accessApi -> bank.accessSvc.offboardingOrch "Invokes for /users/offboard"
    bank.accessSvc.accessApi -> bank.accessSvc.aliasManager "Invokes for /aliases/register"
    bank.accessSvc.accessApi -> bank.accessSvc.statusAggregator "Invokes for /users/{id}/status"

    bank.accessSvc.onboardingOrch -> bank.accessSvc.idempotencyManager "Checks/records idempotency"
    bank.accessSvc.onboardingOrch -> bank.accessSvc.identityKycAdapter "Runs KYC/ID verification"
    bank.accessSvc.onboardingOrch -> bank.accessSvc.provisioningAdapter "Requests wallet provisioning"
    bank.accessSvc.onboardingOrch -> bank.accessDb "Persists state + mappings" "SQL"
    bank.accessSvc.onboardingOrch -> bank.accessSvc.auditLogger "Writes audit event"
    bank.accessSvc.onboardingOrch -> bank.eventBus "Publishes onboarding event"

    bank.accessSvc.aliasManager -> bank.accessSvc.idempotencyManager "Ensures safe retries"
    bank.accessSvc.aliasManager -> bank.accessDb "Stores alias mapping references" "SQL"
    bank.accessSvc.aliasManager -> bank.accessSvc.auditLogger "Writes audit event"
    bank.accessSvc.aliasManager -> bank.eventBus "Publishes alias event"

    bank.accessSvc.offboardingOrch -> bank.accessDb "Updates lifecycle state" "SQL"
    bank.accessSvc.offboardingOrch -> liquidity "Coordinates closure/defunding as needed" "API"
    bank.accessSvc.offboardingOrch -> walletProvisioning "Requests wallet closure/deactivation (if supported)" "API"
    bank.accessSvc.offboardingOrch -> bank.accessSvc.auditLogger "Writes audit event"
    bank.accessSvc.offboardingOrch -> bank.eventBus "Publishes offboarding event"

    bank.accessSvc.statusAggregator -> bank.accessDb "Reads lifecycle state/mappings" "SQL"
    bank.accessSvc.statusAggregator -> liquidity "Fetches balance/limits (optional)" "API"
  }

  views {
    container bank "AccessMgmt_Container"  {
      include *
      autoLayout lr
    }

    component bank.accessSvc "AccessMgmt_Component"{
      include *
      autoLayout lr
    }

    styles {
      element "Person" {
        shape person
      }

      element "Bank" {
        background #1f77b4
        color #ffffff
      }

      element "External" {
        background #6c757d
        color #ffffff
        border dashed
      }

      element "Database" {
        shape cylinder
      }

      relationship "Relationship" {
        color #707070
        thickness 2
      }
    }

    theme default
  }
}


workspace "8.1.2 Liquidity Management Service Digital Euro - Liquidity Management Service (PSP/Bank)" "Refined architecture aligned with digital euro liquidity management, waterfall and reverse-waterfall flows." {

  !identifiers hierarchical

  model {
    user = person "Digital Euro User" "Retail or business user initiating payments and funding/defunding via the PSP channels."
    ops = person "Treasury / Operations" "PSP treasury and ops staff monitoring DCA and liquidity triggers."

    bank = softwareSystem "Bank / PSP Digital Euro Distribution Layer" "PSP distribution layer hosting liquidity management capabilities." {
      tags "Bank"

      apiGateway = container "API Gateway" "Ingress control for all channel/API traffic (authn/z, routing, throttling)." "Kong / Apigee / AWS API Gateway"
      txMgmt = container "Transaction Management Service" "Payment initiation + orchestration and pre-settlement checks; calls liquidity pre-checks and executes waterfall/reverse-waterfall steps." "Java / Kotlin"

      liquiditySvc = container "Liquidity Management Service" "Implements funding/defunding, DCA position management, waterfall & reverse-waterfall execution, and reconciliation." "Node.js" {

        liquidityApi = component "Liquidity API" "Public + internal endpoints (manual fund/defund, pre-check, execute waterfall/reverse-waterfall)." "Node.js / Express"
        limitEngine = component "Holding Limit Engine" "Computes holding-limit breach and excess amounts; supports post-settlement check triggers." "Node.js"
        precheck = component "Pre-check Evaluator" "Implements payer/payee pre-check decisions for reverse-waterfall and waterfall requirements." "Node.js"
        waterfallOrch = component "Waterfall Orchestrator" "Executes defunding of excess and coordinates settlement-integrated steps." "Node.js"
        reverseWaterfallOrch = component "Reverse Waterfall Orchestrator" "Executes funding to cover insufficient holdings; handles rollback on failure." "Node.js"
        dcaManager = component "DCA Position Manager" "Tracks PSP DCA balance/reserves; updates availability and reserved liquidity." "Node.js"
        triggerMgr = component "Trigger Manager" "Applies minimum/target reserve policies; initiates replenishment or defunding actions." "Node.js"
        forecast = component "Forecast Engine" "Generates liquidity forecast using transaction trends and scheduled events." "Node.js"
        recon = component "Reconciliation Worker" "Reconciles internal tx state vs DESP confirmations and statements; raises exceptions." "Node.js"
        cbAdapter = component "Core Banking Adapter" "Encapsulates reserve/debit/credit operations and idempotent posting." "Node.js"
        despClient = component "DESP Client" "Formats and sends scheme instructions via DESP connector; handles confirmations." "Node.js"
        outbox = component "Outbox/Event Publisher" "Publishes events from DB-backed outbox for audit-grade delivery." "Node.js"
        audit = component "Audit Logger" "Writes immutable audit records with correlation IDs and evidence." "Node.js"
        idem = component "Idempotency Manager" "Prevents double execution across retries; stores keys and prior outcomes." "Node.js"

        liquidityApi -> precheck "Invokes decisions for pre-check endpoints"
        precheck -> limitEngine "Computes holding-limit excess and required waterfall"
        liquidityApi -> waterfallOrch "Starts waterfall execution"
        liquidityApi -> reverseWaterfallOrch "Starts reverse-waterfall execution"

        waterfallOrch -> cbAdapter "Credits linked non-digital euro account after confirmation"
        reverseWaterfallOrch -> cbAdapter "Reserves/debits linked account; reverses on failure"

        waterfallOrch -> despClient "Sends scheme defunding instruction"
        reverseWaterfallOrch -> despClient "Sends scheme funding instruction"

        despClient -> outbox "Emits settlement/confirmation events"
        recon -> despClient "Queries/validates confirmations and statements"

        dcaManager -> triggerMgr "Feeds availability metrics"
        triggerMgr -> despClient "Initiates PSP-level replenishment actions where needed"

        liquidityApi -> idem "Checks idempotency for execute endpoints"
        waterfallOrch -> audit "Records evidence"
        reverseWaterfallOrch -> audit "Records evidence"
      }

      liquidityDb = container "Liquidity DB" "Transactional store: liquidity state, DCA position snapshots, user funding agreements, idempotency keys, tx state." "PostgreSQL" {
        tags "Database"
      }
      cache = container "Liquidity Cache" "Low-latency cache for DCA position and user opt-in flags." "Redis"
      eventBus = container "Event Bus" "Event streaming for liquidity lifecycle events and audit integration." "Kafka"
      scheduler = container "Scheduler / Rules Engine" "Runs periodic liquidity monitoring, trigger evaluation, and reconciliation jobs." "Temporal / Quartz / Kubernetes CronJobs"

      despConnector = container "DESP Connectivity Adapter" "Shared connectivity client (mTLS, request signing, retries, correlation IDs) for scheme-facing calls." "REST Client + mTLS"
      observability = container "Observability & SIEM" "Metrics/logs/traces + security monitoring." "OpenTelemetry + SIEM"
      kms = container "Key Management / HSM" "Key custody and cryptographic operations for mTLS and signing." "HSM / Cloud KMS"

      coreBanking = container "Core Banking / Payments Ledger" "Reserves/debits/credits linked non-digital euro payment accounts; posts accounting events." "Core Banking"
      treasury = container "Treasury System" "Treasury dashboarding and internal liquidity controls; interfaces for reserve strategy and alerts." "Treasury Platform"
    }

    desp = softwareSystem "DESP (Eurosystem)" "Eurosystem platform providing scheme services (funding/defunding, confirmations, statements)." {
      tags "External"
    }

    user -> bank.apiGateway "Uses channel APIs (fund/defund, status, preferences)"
    ops -> bank.treasury "Monitors liquidity strategy and KPIs"
    ops -> bank.apiGateway "Queries DCA position and forecast"

    bank.apiGateway -> bank.liquiditySvc "Routes liquidity requests (manual fund/defund, forecast, triggers)" "HTTPS + OAuth2/mTLS"
    bank.txMgmt -> bank.liquiditySvc "Calls pre-check and execute endpoints for waterfall/reverse-waterfall" "HTTPS + mTLS"

    bank.liquiditySvc -> bank.liquidityDb "Reads/writes tx state, agreements, idempotency" "SQL"
    bank.liquiditySvc -> bank.cache "Reads/writes hot state" "TCP"
    bank.liquiditySvc -> bank.eventBus "Publishes liquidity and audit events" "Kafka"
    bank.scheduler -> bank.liquiditySvc "Invokes trigger evaluation and reconciliation jobs" "Internal API / Worker"

    bank.liquiditySvc -> bank.coreBanking "Reserve/debit/credit linked non-digital euro payment accounts" "Internal APIs / ISO 20022 / Ledger APIs"
    bank.liquiditySvc -> bank.treasury "Pushes DCA metrics, alerts, and forecast outputs" "Internal APIs"

    bank.liquiditySvc -> bank.despConnector "Uses standardized scheme connectivity" "Local call"
    bank.despConnector -> desp "Sends funding/defunding + waterfall/reverse-waterfall instructions; receives confirmations" "REST + mTLS"

    bank.liquiditySvc -> bank.observability "Emits logs/metrics/traces" "OTel"
    bank.despConnector -> bank.kms "Uses keys/certs for mTLS and signing" "PKCS#11 / KMS APIs"

    bank.liquiditySvc.outbox -> bank.eventBus "Publishes lifecycle events"
  }

  views {
    systemContext bank "SystemContext" "System Context - Liquidity Management" {
      include *
      autoLayout lr
    }

    container bank "Containers" "Container View - Liquidity Management Service" {
      include *
      autoLayout lr
    }

    component bank.liquiditySvc "LiquidityComponents" "Component View - Liquidity Management Service (Node.js)" {
      include *
      autoLayout lr
    }

    styles {
      element "Person" {
        shape person
      }
      element "Software System" {
        shape roundedbox
      }
      element "Container" {
        shape roundedbox
      }
      element "Component" {
        shape box
      }
      element "Database" {
        shape cylinder
      }
    }

    theme default
  }
}

workspace "8.1.3 Transaction Management Service Digital Euro - Transaction Management Service (PSP/Bank)" "Refined TMS architecture aligned to scheme processing, validations, waterfall/reverse-waterfall integration, and NFR framing." {

  !identifiers hierarchical

  model {
    user = person "Digital Euro User" "Retail or business user paying/receiving digital euro via PSP channels."
    merchant = person "Merchant / Payee" "Merchant or payee initiating POS/e-commerce flows (often via payee PSP channel)."
    ops = person "Operations / Support" "Monitoring, exception handling, dispute support, reporting."

    bank = softwareSystem "Bank / PSP Digital Euro Distribution Layer" "Distribution layer hosting transaction management capabilities." {

      apiGateway = container "API Gateway" "Ingress control, authN/Z, routing, throttling, correlation IDs." "Kong / Apigee / AWS API Gateway"

      accessSvc = container "Access Management Service" "Onboarding, DEAN/wallet binding, alias lifecycle." "Go / Java"
      directory = container "Alias/Directory Resolver" "Resolves alias -> DEAN/wallet identifier; may be internal or shared." "Service"

      liquiditySvc = container "Liquidity Management Service" "Funding/defunding orchestration, DCA position, waterfall/reverse-waterfall checks and execution." "Node.js"

      txSvc = container "Transaction Management Service" "Orchestrates digital euro payment lifecycle: initiation, validation, fraud checks, submission/confirmation with DESP, state persistence, reconciliation." "Java / Spring Boot" {

        txApi = component "Transaction API" "Endpoints: initiate, status, history; validates inputs and triggers orchestration." "Spring MVC"
        stateMachine = component "Transaction State Machine" "Deterministic state transitions; persists state and enforces allowed moves." "Java"
        orchestrator = component "Payment Orchestrator" "Coordinates payee/payer validation, DESP submission, callbacks, and compensation." "Java"
        idempotency = component "Idempotency Manager" "Prevents duplicates across retries/timeouts; stores prior outcomes." "Java"
        aliasAdapter = component "Alias Resolver Adapter" "Resolves alias -> DEAN/wallet; handles caching and fallbacks." "Java"
        liquidityAdapter = component "Liquidity Adapter" "Calls liquidity pre-check and execute endpoints for waterfall/reverse-waterfall." "Java"
        fraudEngine = component "Fraud & Risk Checks" "Performs PSP-side checks; integrates DESP fraud score consumption for ECOM/P2P." "Java"
        despClient = component "DESP Client" "Builds scheme messages; interacts via DESP Connectivity Adapter; handles correlation IDs." "Java"
        reconWorker = component "Reconciliation Worker" "Reconciles settlement confirmations; handles late callbacks and exceptions." "Java"
        audit = component "Audit Logger" "Persists evidence: who/what/when, correlation IDs, reason codes." "Java"
        eventPublisher = component "Event Publisher" "Publishes lifecycle events via outbox -> Kafka." "Java"
        notifier = component "Notification Dispatcher" "Triggers notifications/receipts according to user preferences." "Java"

        txApi -> idempotency "Checks idempotency"
        txApi -> orchestrator "Starts orchestration"

        orchestrator -> aliasAdapter "Resolves payee alias"
        orchestrator -> liquidityAdapter "Pre-check + execute waterfall/reverse-waterfall"
        orchestrator -> fraudEngine "Fraud scoring/checks"
        orchestrator -> despClient "Submits/Responds to DESP"
        orchestrator -> stateMachine "Applies state transitions"
        orchestrator -> audit "Records evidence"
        orchestrator -> eventPublisher "Emits events"
        orchestrator -> notifier "Notifies user"

        reconWorker -> despClient "Processes confirmations/rejections"
        reconWorker -> stateMachine "Finalizes state"
        reconWorker -> audit "Records reconciliation evidence"
        reconWorker -> notifier "Triggers final notifications"
      }

      txDb = container "Transaction DB" "Transactional store: payment state machine, idempotency keys, correlation IDs, audit metadata." "PostgreSQL" {
        tags "Database"
      }
      outbox = container "Outbox" "Reliable event publication pattern for transaction events." "DB-backed outbox"
      eventBus = container "Event Bus" "Events for downstream consumers (notifications, analytics, ops tooling)." "Kafka"

      coreBanking = container "Core Banking / Internal Ledger" "Account status, posting, reservation where applicable; supports user balance views and internal accounting." "Core Banking"
      notification = container "Notification Service" "User notifications/receipts per preferences (push/SMS/email)." "Service"

      despConnector = container "DESP Connectivity Adapter" "mTLS/signing, retries, correlation IDs; standardized scheme-facing interface." "REST Client + mTLS"
      kms = container "Key Management / HSM" "Key custody and cryptographic operations for mTLS/signing." "HSM / Cloud KMS"

      observability = container "Observability & SIEM" "Metrics/logs/traces, security monitoring, incident response support." "OpenTelemetry + SIEM"
    }

    desp = softwareSystem "DESP (Eurosystem)" "Eurosystem scheme platform for transaction messages and confirmations." {
      tags "External"
    }

    // Relationships
    user -> bank.apiGateway "Initiates payments; queries status/history"
    merchant -> bank.apiGateway "Initiates payee-side requests (POS/e-com) via payee PSP channel"
    ops -> bank.observability "Monitors errors, SLIs/SLOs, exceptions"

    bank.apiGateway -> bank.txSvc "Routes payment API calls" "HTTPS + OAuth2/mTLS"
    bank.txSvc -> bank.txDb "Reads/writes transaction state + idempotency" "SQL"
    bank.txSvc -> bank.outbox "Writes events for reliable publication" "Local"
    bank.outbox -> bank.eventBus "Publishes transaction lifecycle events" "Kafka"

    bank.txSvc -> bank.accessSvc "Checks account status / wallet binding where needed" "Internal API"
    bank.txSvc -> bank.directory "Resolves alias to DEAN/wallet identifier" "Internal API"

    bank.txSvc -> bank.liquiditySvc "Balance pre-check + (reverse) waterfall requirement/execution" "Internal API"
    bank.txSvc -> bank.coreBanking "Account status / postings / internal accounting hooks" "Internal API"

    bank.txSvc -> bank.despConnector "Submits messages; receives callbacks (validation request, settlement confirmation)" "Local"
    bank.despConnector -> desp "Scheme-facing transaction messages and confirmations" "REST + mTLS"
    bank.despConnector -> bank.kms "Uses keys/certs for mTLS/signing" "PKCS#11 / KMS APIs"

    bank.txSvc -> bank.notification "Sends user receipts/notifications after settlement/rejection" "Internal API"
    bank.txSvc -> bank.observability "Emits logs/metrics/traces" "OTel"
  }

  views {
    systemContext bank "SystemContext" "System Context - Transaction Management in PSP Digital Euro Distribution Layer" {
      include *
      autoLayout lr
    }

    container bank "Containers" "Container View - Transaction Management Service" {
      include *
      autoLayout lr
    }

    component bank.txSvc "TransactionComponents" "Component View - Transaction Management Service (Java/Spring Boot)" {
      include *
      autoLayout lr
    }

    styles {
      element "Person" {
        shape person
      }
      element "Software System" {
        shape roundedbox
      }
      element "Container" {
        shape roundedbox
      }
      element "Component" {
        shape box
      }
      element "Database" {
        shape cylinder
      }
    }

    theme default
  }
}

workspace "8.1.4 Offline Management Service Digital Euro - Offline Management Service (Offline Distribution)" "Reference architecture for SE-backed offline wallets, intermediary-side provisioning, funding/defunding, and online reconciliation." {

  !identifiers hierarchical

  model {
    user = person "Digital Euro User" "End user with an offline-capable wallet (mobile or card-based form factor)."
    merchant = person "Merchant / Payee" "Merchant with an offline-capable POS/device for proximity payments."
    ops = person "Operations / Support" "Monitors provisioning, reconciliation exceptions, device risk signals, and KPIs."

    device = softwareSystem "Offline Digital Euro Device" "User device/wallet (mobile or card form factor) supporting offline digital euro."
    pos = softwareSystem "Offline-capable Merchant Device / POS" "Merchant POS/device capable of offline proximity acceptance."

    bank = softwareSystem "Bank / PSP Offline Distribution" "Intermediary-side components for offline wallet lifecycle, funding/defunding, and online reconciliation." {
      apiGateway = container "API Gateway" "Ingress control for device/app calls; authN/Z, throttling, correlation IDs." "Kong / Apigee / AWS"

      offlineSvc = container "Offline Management Service (OMS)" "Provisioning, lifecycle mgmt, policy distribution, funding/defunding orchestration, reconciliation packaging/forwarding, auditability." "C++ (native service) + REST/gRPC" {

        deviceApi = component "Device/Wallet API" "REST/gRPC endpoints for provisioning, session setup, funding/defunding, reconciliation upload." "C++/gRPC"
        seProvisioning = component "SE Provisioning Coordinator" "Drives SE install/activate workflow via SE adapter; manages SE keys/certs." "C++"
        attestationClient = component "Attestation Client" "Calls attestation service; enforces allow/deny decisions." "C++"
        policyManager = component "Policy Bundle Manager" "Fetches policy parameters and produces signed policy bundles for devices." "C++"
        fundingOrch = component "Funding/Defunding Orchestrator" "Coordinates ATM/core-banking calls; maintains idempotency and lifecycle state." "C++"
        reconPackager = component "Reconciliation Packager" "Builds reconciliation packages; validates uploads; forwards to Eurosystem." "C++"
        outboxPublisher = component "Outbox/Event Publisher" "Publishes provisioning/reconciliation outcomes and risk events to Kafka." "C++"
        auditLogger = component "Audit Logger" "Writes immutable audit records with correlation IDs and evidence." "C++"

        // internal component flow
        deviceApi -> seProvisioning "Starts provisioning flows"
        deviceApi -> policyManager "Requests policy bundle/version"
        deviceApi -> fundingOrch "Invokes fund/defund flows"
        deviceApi -> reconPackager "Uploads offline records and triggers packaging"

        seProvisioning -> attestationClient "Requires device trust decision"
        policyManager -> auditLogger "Records policy issuance evidence"
        fundingOrch -> auditLogger "Records funding/defunding evidence"
        reconPackager -> auditLogger "Records reconciliation evidence"
        reconPackager -> outboxPublisher "Emits reconciliation outcome events"
      }

      offlineDb = container "Offline Wallet Registry & Reconciliation Store" "Wallet bindings, device metadata, policy versions, reconciliation sessions, uploaded offline records, idempotency." "PostgreSQL" {
        tags "Database"
      }

      cache = container "Offline Policy/Session Cache" "Hot cache for policy bundles, session tokens, attestation decisions." "Redis"
      eventBus = container "Event Bus" "Async events for ops alerts, fraud analytics, device risk, reconciliation outcomes." "Kafka"
      kms = container "Key Management / HSM" "Key custody for signing policy bundles, verifying device attestation, mTLS client keys." "HSM / Cloud KMS"
      atm = container "ATM / Funding Device Channel" "ATM-like device enabling cash-based funding/defunding where supported." "ATM network"
      coreBanking = container "Core Banking / Customer Accounts" "Commercial bank account debits/credits for funding/defunding operations." "Core banking"
      observability = container "Observability & SIEM" "Logs/metrics/traces; security monitoring; audit trails for lifecycle and reconciliation." "OpenTelemetry + SIEM"

      seProv = container "SE Provisioning Adapter" "Delivers applet packages, drives SE install/activate flows via device app; collects SE public keys/certs." "Provisioning service"
      attestation = container "Device Attestation Service" "Verifies device + app integrity (non-rooted, code authenticity), certificate validity; issues trust decisions." "Service"
      policySvc = container "Offline Policy Distribution" "Receives Eurosystem-configurable policy parameters; produces signed policy bundles for SE enforcement." "Service"
    }

    eurosystem = softwareSystem "Eurosystem Offline Issuance / Verification" "Eurosystem offline verification/issuance services."
    desp = softwareSystem "DESP (Eurosystem)" "Eurosystem online scheme services (context/optional linkage)." {
      tags "External"
    }

    // Relationships - proximity offline payments
    user -> device "Uses offline wallet (mobile/card) to pay/receive offline" "Local UI"
    merchant -> pos "Accepts offline proximity payments" "POS UI"
    device -> pos "Offline payment in physical proximity" "NFC / QR"

    // Device online interactions (provisioning, funding/defunding, reconciliation)
    device -> bank.apiGateway "Provisioning, funding/defunding, reconciliation session setup" "HTTPS"
    bank.apiGateway -> bank.offlineSvc "Routes device/app requests" "REST/gRPC"

    // Container integrations
    bank.offlineSvc -> bank.offlineDb "Stores wallet binding, reconciliation sessions, offline record uploads" "SQL"
    bank.offlineSvc -> bank.cache "Reads/writes policy bundles and session state" "Redis"
    bank.offlineSvc -> bank.kms "Signs/validates policy bundles; manages mTLS/signing keys" "PKCS#11 / KMS APIs"
    bank.offlineSvc -> bank.eventBus "Publishes reconciliation/provisioning outcomes, risk events" "Kafka"
    bank.offlineSvc -> bank.observability "Emits logs/metrics/traces and audit signals" "OTel"

    bank.offlineSvc -> bank.seProv "Requests SE applet delivery/activation workflow" "Internal API"
    bank.offlineSvc -> bank.attestation "Verifies device/app integrity and authenticity" "Internal API"
    bank.offlineSvc -> bank.policySvc "Fetches signed, immutable offline policy parameters" "Internal API"

    bank.offlineSvc -> bank.coreBanking "Debits/credits user commercial bank account for funding/defunding" "Internal API"
    bank.offlineSvc -> bank.atm "Supports funding/defunding via ATM channel where applicable" "ISO 8583 / API"

    bank.offlineSvc -> eurosystem "Uploads offline reconciliation package; receives verification outcome and reset instructions" "Secure channel (mTLS)"
    bank.offlineSvc -> desp "May reference online identifiers for lifecycle consistency (optional)" "Secure API"

    // Hook some component-to-external/container relationships so they show in the component view
    bank.offlineSvc.deviceApi -> bank.offlineDb "Reads/writes sessions, bindings, uploads" "SQL"
    bank.offlineSvc.policyManager -> bank.policySvc "Fetches policy parameters" "Internal API"
    bank.offlineSvc.policyManager -> bank.kms "Signs bundles" "HSM/KMS API"
    bank.offlineSvc.seProvisioning -> bank.seProv "Triggers SE install/activate" "Internal API"
    bank.offlineSvc.attestationClient -> bank.attestation "Verifies device/app" "Internal API"
    bank.offlineSvc.fundingOrch -> bank.coreBanking "Debits/credits account" "Internal API"
    bank.offlineSvc.fundingOrch -> bank.atm "ATM fund/defund (if used)" "ISO 8583 / API"
    bank.offlineSvc.reconPackager -> eurosystem "Uploads reconciliation package" "mTLS"
    bank.offlineSvc.outboxPublisher -> bank.eventBus "Publishes events" "Kafka"
    bank.offlineSvc.auditLogger -> bank.observability "Emits audit traces/logs" "OTel"
  }

  views {
    systemContext bank "SystemContext" "System Context - Offline Distribution (OMS) for Digital Euro" {
      include *
      autoLayout lr
    }

    container bank "Containers" "Container View - Offline Management Service (OMS) and Interactions" {
      include *
      autoLayout lr
    }

    component bank.offlineSvc "OfflineComponents" "Component View - Offline Management Service (OMS)" {
      include *
      autoLayout lr
    }

    styles {
      element "Person" {
        shape person
      }
      element "Software System" {
        shape roundedbox
      }
      element "Container" {
        shape roundedbox
      }
      element "Database" {
        shape cylinder
      }
      element "Component" {
        shape box
      }
    }

    theme default
  }
}

workspace "8.1.5_Deployment_Arch Digital Euro - Bank/PSP Deployment Architecture" "Multi-region Kubernetes deployment for Digital Euro integration services (Access, Liquidity, Transaction, Offline) with DESP connectivity, observability, and CI/CD." {

  !identifiers hierarchical

  model {
    bank = softwareSystem "Bank/PSP Digital Euro Integration Platform" "Microservices-based platform integrating channels with Digital Euro scheme connectivity." {

      apiGateway = container "API Gateway" "Ingress, authN/Z, throttling, routing, correlation IDs." "Kong / Apigee / AWS API Gateway"
      accessSvc = container "Access Management Service" "Onboarding, wallet/account binding, alias lifecycle hooks." "Go/Java"
      liquiditySvc = container "Liquidity Management Service" "DCA monitoring, waterfall/reverse-waterfall orchestration, liquidity triggers." "Node.js"
      txSvc = container "Transaction Management Service" "Payment orchestration, validation, state machine, reconciliation handling." "Java/Spring Boot"
      offlineSvc = container "Offline Management Service" "SE provisioning orchestration, offline lifecycle, reconciliation packaging." "C++/Native"
      notificationSvc = container "Notification Service" "User/merchant notifications and receipts." "Service"
      despConnector = container "DESP Connectivity Adapter" "mTLS, signing, retries, correlation IDs, scheme version handling." "REST Client + mTLS"

      txDb = container "Transaction Database" "System-of-record for transaction state, idempotency, audit metadata." "PostgreSQL (HA)" {
        tags "Database"
      }
      identityDb = container "Identity/Wallet Database" "Wallet bindings, alias metadata, onboarding state." "PostgreSQL (HA)" {
        tags "Database"
      }
      cache = container "Cache" "Session cache, hot reads, rate limit state." "Redis"
      eventBus = container "Event Bus" "Async events for downstream consumers and operational decoupling." "Kafka"
      observability = container "Observability & SIEM" "Central metrics/logs/traces and security monitoring." "Prometheus/OTel + SIEM"
      kms = container "Key Management / HSM" "Key custody for mTLS/signing; rotation and cryptographic controls." "HSM/KMS"
      cicd = container "CI/CD Platform" "Build, test, scan, sign, deploy (GitOps supported)." "Jenkins/GitHub Actions + ArgoCD"
    }

    // -------------------------
    // Deployment environment
    // -------------------------
    deploymentEnvironment "Production" {

      // Shared global services (still EU-resident)
      deploymentNode "EU Shared Services" "EU" "Shared platform services (audit, security, CI/CD control plane)." {
        infrastructureNode "WAF / DDoS Protection" "Edge protection and rate limiting." "WAF"
        infrastructureNode "Private Container Registry" "Signed images + SBOM storage." "Registry"
        infrastructureNode "Secrets Manager" "Central secret storage with rotation." "Secrets"
        containerInstance bank.cicd
        containerInstance bank.kms
        containerInstance bank.observability
      }

      // -------------------------
      // Region 1: EU-Central (Active)
      // -------------------------
      deploymentNode "EU-Central Region" "EU" "Primary active region (multi-AZ)." {
        deploymentNode "Kubernetes Cluster (EU-Central)" "Kubernetes" "Managed control plane; multi-AZ worker pools." {

          deploymentNode "Ingress Node Pool" "K8s Node Pool" "Ingress controllers and edge routing." {
            infrastructureNode "Ingress Controller" "L7 routing to services." "Nginx/Envoy"
            containerInstance bank.apiGateway
          }

          deploymentNode "Core Services Node Pool" "K8s Node Pool" "Business services (stateless)." {
            containerInstance bank.accessSvc
            containerInstance bank.liquiditySvc
            containerInstance bank.txSvc
            containerInstance bank.offlineSvc
            containerInstance bank.notificationSvc
          }

          deploymentNode "DESP Connectivity Zone" "K8s Node Pool" "Restricted egress, allow-listed outbound to scheme endpoints." {
            infrastructureNode "Egress Gateway" "Allow-listed outbound connectivity." "Firewall/NAT"
            containerInstance bank.despConnector
          }

          deploymentNode "Data Services (EU-Central)" "Managed Services" "Stateful platform services (HA within region)." {
            deploymentNode "PostgreSQL HA Cluster" "Database" "Synchronous replicas across AZs." {
              containerInstance bank.txDb
              containerInstance bank.identityDb
            }
            deploymentNode "Kafka Cluster" "Streaming" "Regional event streaming." {
              containerInstance bank.eventBus
            }
            deploymentNode "Redis Cluster" "Cache" "Regional cache." {
              containerInstance bank.cache
            }
          }
        }
      }

      // -------------------------
      // Region 2: EU-North (Active)
      // -------------------------
      deploymentNode "EU-North Region" "EU" "Secondary active region (multi-AZ)." {
        deploymentNode "Kubernetes Cluster (EU-North)" "Kubernetes" "Active-active for stateless; scaled data services." {

          deploymentNode "Ingress Node Pool" "K8s Node Pool" "Ingress controllers and edge routing." {
            infrastructureNode "Ingress Controller" "L7 routing to services." "Nginx/Envoy"
            containerInstance bank.apiGateway
          }

          deploymentNode "Core Services Node Pool" "K8s Node Pool" "Business services (stateless)." {
            containerInstance bank.accessSvc
            containerInstance bank.liquiditySvc
            containerInstance bank.txSvc
            containerInstance bank.offlineSvc
            containerInstance bank.notificationSvc
          }

          deploymentNode "DESP Connectivity Zone" "K8s Node Pool" "Restricted egress, allow-listed outbound to scheme endpoints." {
            infrastructureNode "Egress Gateway" "Allow-listed outbound connectivity." "Firewall/NAT"
            containerInstance bank.despConnector
          }

          deploymentNode "Data Services (EU-North)" "Managed Services" "Read-heavy + DR-ready data services." {
            deploymentNode "PostgreSQL (Replica/Failover-ready)" "Database" "Asynchronous replication from EU-Central." {
              containerInstance bank.txDb
              containerInstance bank.identityDb
            }
            deploymentNode "Kafka Cluster" "Streaming" "Regional event streaming; replicated topics." {
              containerInstance bank.eventBus
            }
            deploymentNode "Redis Cluster" "Cache" "Regional cache." {
              containerInstance bank.cache
            }
          }
        }
      }

      // -------------------------
      // Region 3: EU-South (Warm Standby / Recovery)
      // -------------------------
      deploymentNode "EU-South Region" "EU" "Warm standby / recovery region (scaled down until failover)." {
        deploymentNode "Kubernetes Cluster (EU-South)" "Kubernetes" "Standby workloads; scale up on failover." {

          deploymentNode "Core Services Node Pool" "K8s Node Pool" "Minimal footprint; autoscale on failover." {
            containerInstance bank.accessSvc
            containerInstance bank.liquiditySvc
            containerInstance bank.txSvc
            containerInstance bank.offlineSvc
            containerInstance bank.notificationSvc
            containerInstance bank.despConnector
          }

          deploymentNode "Data Services (EU-South)" "Managed Services" "DR replicas." {
            deploymentNode "PostgreSQL (DR Replica)" "Database" "Asynchronous replication (DR)." {
              containerInstance bank.txDb
              containerInstance bank.identityDb
            }
            deploymentNode "Kafka (DR)" "Streaming" "DR replication / standby." {
              containerInstance bank.eventBus
            }
          }
        }
      }
    }
  }

  views {
    deployment bank "Production" "prod" "Production multi-region deployment (2 active regions + 1 warm standby)." {
      include *
      autoLayout lr
    }

    styles {
      element "Software System" {
        shape roundedbox
      }
      element "Container" {
        shape roundedbox
      }
      element "Database" {
        shape cylinder
      }
    }

    theme default
  }
}
