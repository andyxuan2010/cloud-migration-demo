# Cloud Migration Demo for Small Business

Architecture and requirements documentation for modernizing a small-business Windows environment and retiring its on-premises Active Directory Domain Services (AD DS) dependency.

> **Project site:** [andyxuan.ca/cloud-migration-demo/](https://andyxuan.ca/cloud-migration-demo/)

## Scope and assumptions

- Six initial users and up to 10 company-owned Windows 11 PCs.
- One existing on-premises AD DS domain/controller, with retirement gated on dependency removal and successful rollback testing.
- Google Workspace is the current collaboration platform and may be retained where the selected solution requires it.
- Microsoft Office, Gmail, Google Drive, Google Docs, communication tools, printing, scanning, and approved SaaS applications remain in scope.
- Remote work, BYOD, high availability, major application redevelopment, and regulated-data requirements are optional or require separate approval.
- Cost figures are planning estimates in CAD before tax, not quotations.

## Documents

| Document | Purpose |
|---|---|
| [requirements](requirements.md) | Authoritative, solution-neutral requirements and acceptance criteria. |
| [cloud identity migration options](cloud_identity_migration_options.md) | Solution comparison, decision criteria, risks, and migration overview. |
| [entra id intune architecture](entra_id_intune_architecture.md) | Detailed design for Solution 1: Microsoft Entra ID + Microsoft Intune. |
| [google workspace gcpw architecture](google_workspace_gcpw_architecture.md) | Detailed design for Solution 2: Google Workspace + GCPW. |
| [azure virtual desktop architecture](azure_virtual_desktop_architecture.md) | Detailed design for Solution 3: Azure Virtual Desktop. |

## Recommended direction

**Solution 1 — Microsoft Entra ID + Intune** remains the preferred baseline for retaining local Windows productivity while improving identity, endpoint security, configuration, patching, encryption, application deployment, and AD DS retirement.

**Solution 2 — Google Workspace + GCPW** is a conditional Google-first alternative. It is appropriate only if the Windows control-gap pilot confirms that Google-native management and any approved supplemental controls meet the endpoint, security, recovery, and application requirements.

**Solution 3 — Azure Virtual Desktop** is a conditional or exception architecture. It is justified when centrally hosted desktops, controlled legacy application delivery, reduced local data, consistent access from multiple locations, or access-terminal economics provide a documented benefit that outweighs Azure consumption and operational complexity.

## Shared licensing and platform baseline

- Six **Microsoft 365 Business Premium with Teams** licenses are the baseline user subscription across the updated architecture designs. The bundle includes Entra ID P1-level controls, Intune Plan 1, Office, Teams, Exchange Online, SharePoint, OneDrive, Defender for Business, Defender for Office 365 Plan 1, and Purview information-protection/DLP capabilities. Copilot, Entra ID P2, Intune Plan 2/Suite, and independent backup are separate.
- In Solution 1, Entra ID is authoritative and Intune is the Windows management plane. In Solution 2, Google Workspace remains authoritative and GCPW/Google Admin remains the Windows control plane; Intune is included in the common license but is not layered onto GCPW-managed PCs. In Solution 3, Entra ID is authoritative for AVD access and hosted Windows sessions.
- Google Workspace is optional or retained according to the solution. Its license fee is **optional and excluded from the cost calculations**; the required entitlement must still be verified before using Gmail, Drive, Docs, shared drives, or Google device management.
- Solution 1 and Solution 3 require a company-owned Microsoft Entra tenant and Azure subscription foundation. Solution 2 does not require Azure compute or an Azure subscription for GCPW, but an Azure subscription may be created as an optional governance boundary under the company standard. Azure resource consumption is excluded unless separately approved.
- Entra ID Free plus standalone Intune Plan 1 is only a reduced-control exception for Solution 1. It lacks important controls such as custom Conditional Access and device-compliance gates, some self-service password-reset/enrollment paths, dynamic groups, and advanced risk/governance capabilities.

## Solutions evaluated

| Solution | Authoritative identity and control plane | Best fit | Main trade-off |
|---|---|---|---|
| **1 — Entra ID + Intune** | Entra ID and Intune; Google Workspace integrated with SAML/provisioning where approved | Local Windows productivity with centralized endpoint control | Requires Microsoft cloud foundation and AD dependency remediation |
| **2 — Google Workspace + GCPW** | Google Workspace, GCPW, and Google Admin Windows management | Google-first environments with simple Windows requirements | Feature gaps and incompatibility risk with third-party MDM; must pass a control-gap pilot |
| **3 — Azure Virtual Desktop** | Entra ID, AVD host pool, image, profiles, and Azure operations | Centralized desktops, controlled application delivery, or access terminals | Highest recurring cost, Internet dependency, and operational complexity |

## User sign-in and authentication workflows

| Solution | Workflow diagram | Summary |
|---|---|---|
| Solution 1 | [Entra ID + Google Workspace authentication workflow](images/entra_id_google_authentication_workflow.svg) | User signs in to an Entra-joined Windows PC; MFA and Conditional Access are evaluated; Intune compliance and device controls apply; Google Workspace is reached through the approved Entra SAML/provisioning path. |
| Solution 2 | [Google Workspace + GCPW authentication workflow](images/google_gcpw_authentication_workflow.svg) | User signs in through GCPW with a managed Google Account; Google Workspace applies 2-Step Verification and policy; Google Admin manages supported Windows settings and the user accesses Google services. |
| Solution 3 | [AVD Entra authentication workflow](images/avd_entra_authentication_workflow.svg) | User authenticates at an access terminal with Entra MFA/Conditional Access; the AVD broker authorizes the workspace and host session; the hosted Windows profile and applications are then attached. Google Workspace is accessed in the hosted session when retained. |

The detailed architecture documents contain the diagrams, sequence explanations, recovery boundaries, and exception handling for each workflow.

## Architecture diagrams

- [Solution 1 target architecture](images/entra_id_intune_target_architecture.png)
- [Solution 2 target architecture](images/google_gcpw_target_architecture.png)
- [Solution 3 target architecture](images/azure_virtual_desktop_target_architecture.png)

## Azure Well-Architected five-pillar coverage

The three architecture documents validate the proposed designs against the five Azure Well-Architected pillars. The depth of Azure-specific controls varies by solution: Solution 3 has the greatest Azure resource footprint, while Solution 2 uses Azure only if the optional governance boundary is approved.

| Pillar | Cross-solution coverage |
|---|---|
| Reliability | Emergency access, outage behavior, backup/restore evidence, rollback, recovery testing, and explicit AVD host-availability decisions. |
| Security | MFA, Conditional Access where licensed, least-privilege administration, encryption, endpoint protection, recovery-key handling, and no inbound RDP. |
| Cost Optimization | Business Premium baseline, separate optional Google licensing treatment, backup allowances, Azure budgets/alerts, resource tagging, and AVD autoscale/right-sizing. |
| Operational Excellence | Pilot rings, repeatable policy/image build steps, monitoring, incident/change records, support runbooks, and handover evidence. |
| Performance Efficiency | Windows/device compatibility testing, application and profile validation, AVD host sizing and concurrency measurement, and controlled scaling. |

## Effort and cost at a glance

The following ranges use six users, up to 10 PCs, CAD 125–150/hour, annual commitment pricing where applicable, and the current baseline described above. Google Workspace license fees are excluded; Azure consumption is excluded except in the AVD operating ranges.

| Solution | Baseline implementation | One-time implementation cost | Recurring baseline/platform cost | Routine maintenance |
|---|---:|---:|---:|---:|
| **1 — Entra ID + Intune** | 36–54 hours; approximately 6–10 weeks | CAD 4,500–8,100 | CAD 228.80–278.80/month for Business Premium with Teams plus backup; Azure consumption excluded | CAD 375–750/month; CAD 625–1,200/month if Azure resources or frequent packaging/incident support are added |
| **2 — Google Workspace + GCPW** | 30–46 hours; approximately 5–9 weeks | CAD 3,750–6,900 | CAD 228.80–278.80/month for the common Microsoft baseline plus backup; Google license and supplemental endpoint/RMM tooling excluded | CAD 375–900/month |
| **3 — Azure Virtual Desktop** | 58–104 hours; approximately 10–16 weeks | CAD 7,250–15,600 | CAD 808–1,678/month gross for two right-sized hosts, licenses, backup, and estimated Azure consumption; one-host pilot CAD 508–978/month | CAD 750–1,800/month; one-host pilot approximately CAD 500–1,200/month |

The Solution 3 gross AVD range already includes the license-only baseline and should not be added to it a second time. Optional capabilities, hardware replacement, Internet service, dual-WAN/5G, UPS, major application work, incident response, and vendor support contracts are excluded unless a document explicitly includes them.

## Migration phases

All three architecture documents include phase-level effort and elapsed-time estimates. The common sequence is:

1. Discovery, application/AD dependency inventory, and solution-fit confirmation.
2. Tenant, licensing, identity, recovery, and—where applicable—Azure subscription foundation.
3. Pilot identity sign-in, device management, security, applications, data, and recovery.
4. Migrate users and devices in controlled batches with rollback evidence.
5. Replace DNS, DHCP, file, print, script, service-account, and other AD DS dependencies.
6. Stabilize, validate acceptance criteria, and decommission AD DS only after the retirement gate passes.

Solution-specific differences are important: Solution 1 includes Intune policy engineering and Entra-to-Google integration; Solution 2 includes GCPW and Google Windows control-gap validation; Solution 3 includes Azure foundation, image engineering, AVD host-pool, profile/storage, autoscale, and access-terminal pilots.

## Optional small-business value-adds

The architecture baselines intentionally keep optional services separate from the core migration estimate. Potential add-ons include:

- Windows Autopilot for replacement and reprovisioning.
- A SharePoint/Teams operating hub for procedures, templates, onboarding, and Microsoft-owned content.
- Standard Power Automate workflows for approvals, onboarding/offboarding, reminders, and support exceptions.
- Microsoft 365 Copilot Chat enablement and safe-use guidance; a paid Microsoft 365 Copilot pilot is separate and should start with one or two users.
- Copilot Studio for a narrowly scoped internal FAQ or procedure agent, with content ownership and usage-cost controls.
- Intune mobile application management for approved mobile/BYOD access.
- An Azure VM jumpbox or temporary remote server, hardened with private access, Entra MFA/RBAC, budgets, automatic shutdown, and an expiry date.
- Azure Arc for approved retained on-premises hosts, with least-privilege management, extension controls, monitoring, patching, and offboarding.

Each add-on needs an owner, business outcome, implementation estimate, recurring-cost ceiling, data boundary, and rollback or retirement criterion. Do not layer Intune or Autopilot onto GCPW-managed Windows devices without a deliberate control-plane redesign and pilot.

## Completed end state and deliverables

After the approved plan is carried out, the handover package should include:

- A company-owned identity and, where required, Azure tenant/subscription foundation with verified domain, ownership, billing, RBAC, budgets, alerts, policies, and recovery contacts.
- User and administrator accounts, MFA, emergency access, group assignments, onboarding/offboarding, and sign-in/recovery workflows tested and documented.
- All retained PCs or AVD access terminals inventoried, supported, encrypted, patched, protected, and managed by the approved control plane.
- Approved Office, Google Workspace, browser, communication, printing, scanning, and line-of-business workflows tested through user acceptance.
- User and shared data migrated with ownership, retention, backup, restore evidence, RPO/RTO, and vendor-exit procedures documented.
- AD DS dependencies replaced or formally accepted, with DNS/DHCP and other network/service responsibilities documented after domain-controller retirement.
- Final architecture diagrams, policy/configuration register, migration ledger, operating runbooks, support contacts, cost/license register, rollback evidence, and business acceptance sign-off.
- Evidence for every approved optional add-on, including its owner, controls, cost, operating procedure, and expiry/retirement decision.

## Reliability decisions

- Cached Entra sign-in must be tested for each assigned user and device so previously signed-in users can continue local Windows work during short identity or Internet outages where the solution supports local productivity.
- Two separately protected emergency accounts and independent recovery methods are required.
- Dual-WAN/5G or cellular Internet remains an optional failover enhancement, selected according to the approved RTO and business case.
- UPS protection, network configuration backups, spare equipment, and recovery testing are required where the approved availability target justifies them.
- A one-host AVD deployment is a single point of failure; two or more hosts improve availability but increase cost.

## Current status

This repository contains the current draft architecture and requirements set. Before production approval, complete discovery, feature/licensing confirmation, application and AD dependency validation, pilot testing, backup/restore testing, outage testing, cost approval, rollback planning, and the AD DS decommissioning gate. The detailed architecture documents remain the source of truth for each solution’s controls, assumptions, estimates, risks, and acceptance criteria.
