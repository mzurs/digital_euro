So the topic is about how banks can implemenent and integrate the Digital Euro into their systems and which  implementation model fits different banks sizes

1. 
- This table is basically a responsibility map which depicts which parts banks needs to implement and which will be provided by DESP.

#### Access & User Management
- This is how a customer gets started: such as  onboarding,wallet setup, DEAN & alias assignment.
- Banks manages customer relationship and DESP provides services like alias lookups.

#### Liquidity Management
- This is the money movement part, such as topping up and withdrawing digital euro.
- Bank initiates conversion and DESP updates digital euro holdings.

#### Transaction Initiation & Authorisation
- This is where the customer actually pays through different channels.
- Banks needs to authenticate the user and checks limits before sending the transaction object to DESP.

#### Settlement, Issuance & General Ledger
- This is an offical ledger for final settlement.

#### Risk, Fraud, Compliance & Disputes
- This is Risk, Fraud, Compliance & Disputes where banks run AML/fraud checks and handles disputes as well

#### Offline Service
- Offline means you can pay and recieve even without internet.
- Banks support devices,wallet and DESP defines rules.

2. 
This section shows Bank integration dimensions when integrating Digital Euro
- This is the core banking integration where we need to link customers to DEAN, apply limits and post funding and defunding in ledgers and statements.  And these are the general component we will talk about in the next slide.
- This layer is the bridge b/w PSP and DESP.
- The component affected are API Gateway, ESB and more.
- For Different Channels mobile apps are being affected.
- For Back office operations the system affected are Treasury system,fraud engine.
- For Security and Key Management, the Identiy and Access Managment, Public Keys Certificats are being affected.

3. 

#### This is a high level and generalize view of Technical Architechture
- Customer-facing channels: So these are the customer facing channels.
- API Gateway: This is bank controlled gateway to entertain each channel

- BFF (Back-end for Front-end): This layer separate small UI changes with core services

- Payment workflow: This layer co-ordinates multiple-process


- Access & Wallet Management: This components creates and manages wallet, alias and connect customer to scheme identifiers.

- Liquidity & Limits Service: This components: This component connects to treasury and triggers reconciliation events.


- Transaction Processing Service: It processes payment requests.

- Offline Wallet & Device Security: Manages offline wallet configs and syncing

- Event bus:  Publishes events like ‘payment completed’

- Reconciliation & ledger posting: Matches DESP confirmations with internal accounting and statements

- DESP Connectivity / Scheme Adapter: This is the connector which forwards\recivees all request from/to DESP.


Online flow

“Customer pays → gateway routes → workflow checks limits/fraud → adapter sends to DESP → confirmation returns → reconciliation posts to statements.” 


Offline flow 
“Customer pays without internet → device stores proof → later sync happens → bank checks anomalies → reconciles into records.”