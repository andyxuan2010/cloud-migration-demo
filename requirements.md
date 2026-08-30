# Small-Business Cloud Identity and Endpoint Requirements

**Document status:** Draft v0.2  
**Environment:** Lightweight small-business corporate network  
**Scope:** 6–10 Windows PCs, currently joined to on-premises Active Directory  
**Primary SaaS platform:** Google Workspace  
**Date:** 2026-08-30

## 1. Purpose

This document defines the business, functional, security, technical, operational, migration, and acceptance requirements for modernizing a small-business Windows environment and removing its dependency on an on-premises Active Directory Domain Services (AD DS) server.

The requirements are intentionally solution-neutral. They provide a common baseline against which the following types of solutions can be evaluated:

- cloud identity and modern endpoint management;
- Google-centric Windows authentication and management; and
- centrally hosted or virtual desktops.

This document does not select a product, prescribe a detailed architecture, or provide a cost estimate.

## 2. Requirement terminology

| Priority | Meaning |
|---|---|
| **Must** | Mandatory. The solution cannot be accepted if the requirement is not satisfied or formally waived with a documented risk. |
| **Conditional Must** | Mandatory only when the stated optional capability, such as mobility or BYOD, is enabled. |
| **Should** | Important. The solution should satisfy the requirement unless cost, complexity, or a documented constraint justifies an alternative. |
| **Could** | Optional improvement. Implement when it provides sufficient value. |

Each requirement has a unique identifier for traceability during solution design, testing, and approval.

## 3. Current environment

### 3.1 Confirmed characteristics

| Area | Current state |
|---|---|
| Organization size | Lightweight small-business corporate environment |
| Endpoints | 6–10 company-used Windows PCs |
| Operating system | Windows 10-based |
| Device identity | All PCs are joined to the on-premises AD DS domain |
| Primary productivity platform | Google Workspace, including Gmail, Google Drive, Google Docs, and other SaaS applications |
| Other applications | Microsoft Office, communication tools, browsers, and potentially other locally installed business applications |
| Office model | PCs remain in the office on the existing LAN unless an approved virtual-desktop option changes their role to access terminals |
| Target direction | Cloud-first identity, management, applications, and data with removal of the local AD server |

### 3.2 Mandatory Windows 10 lifecycle constraint

Windows 10 reached end of support on October 14, 2025. Standard Windows 10 installations no longer receive routine security updates or technical support. Commercial Extended Security Updates (ESU) provide a temporary paid bridge, not a valid permanent target state.

Accordingly:

- every PC must be assessed for Windows 11 compatibility;
- compatible PCs must be upgraded to a supported Windows 11 Pro or Enterprise release;
- incompatible PCs must be replaced, repurposed as appropriately secured access terminals, or covered temporarily by eligible commercial Windows 10 ESU;
- unsupported Windows 10 PCs without ESU must not be approved as production endpoints; and
- the migration plan must include a dated Windows 10 retirement schedule.

This is a security requirement, not an optional modernization preference.

## 4. Project objectives

| ID       | Requirement | Priority |
|----------|---|---|
| OBJ‑01 | Remove the need to operate an on-premises AD DS domain controller. | Must |
| OBJ‑02 | Preserve secure and reliable access to Google Workspace, Microsoft Office, communication tools, and approved business applications. | Must |
| OBJ‑03 | Retain existing PCs when they meet security, performance, lifecycle, and compatibility requirements. | Should |
| OBJ‑04 | Reduce infrastructure and administration appropriate to an organization with only 6–10 PCs. | Must |
| OBJ‑05 | Use cloud services and SaaS rather than introduce replacement on-premises servers. | Must |
| OBJ‑06 | Avoid unnecessary enterprise-scale complexity, duplicated platforms, and overlapping licenses. | Should |
| OBJ‑07 | Provide a controlled, testable, and reversible migration with minimal disruption. | Must |
| OBJ‑08 | Establish repeatable operations for onboarding, offboarding, device replacement, patching, support, backup, and recovery. | Must |
| OBJ‑09 | Make user access, business data, and standard endpoint configuration portable enough that work can resume from a replacement device or approved location without dependency on the office domain controller. | Should |
| OBJ‑10 | Keep the target environment lightweight, stable, low-cost, and maintainable without a full-time specialist. | Must |
| OBJ‑11 | Prefer supported managed services and standard configuration over custom servers, scripts, or bespoke integration. | Should |
| OBJ‑12 | Preserve an exit path by maintaining data export, configuration documentation, and vendor-independent ownership of domains and identities. | Must |
| OBJ‑13 | Treat mobility as an optional ideal state: enable secure work from approved locations when it can be delivered without materially undermining simplicity, stability, maintainability, or cost control. | Should |

## 5. Scope

### 5.1 In scope

- Current AD users, groups, computers, and policies required by the business
- 6–10 Windows endpoints and their assigned users
- Cloud identity and user authentication
- Windows sign-in and endpoint management
- Google Workspace access and identity integration
- Microsoft Office licensing and deployment
- SaaS and communication-tool access
- User profiles, local files, shared files, browser data, and required application settings
- Endpoint protection, disk encryption, patching, compliance, and inventory
- Optional secure mobility for approved users, devices, and locations
- Portability of user access, business data, configuration, and recovery procedures
- DNS, DHCP, file, print, certificate, VPN, RADIUS, script, scheduled-task, and service-account dependencies currently hosted by or dependent on the AD server
- Backup, recovery, monitoring, documentation, cutover, rollback, and AD decommissioning

### 5.2 Out of scope unless discovery proves otherwise

- New custom application development
- Replacement of business SaaS products that already meet requirements
- Enterprise-scale high availability or multi-region disaster recovery
- Complex virtual desktop infrastructure unless selected as the target solution
- New office cabling, Wi-Fi replacement, or firewall replacement unless the current equipment cannot meet the requirements
- Formal regulatory certification or audit work unless a specific obligation is identified
- Mobile-device management beyond what is necessary to protect corporate SaaS access

## 6. Business and usability requirements

| ID       | Requirement | Priority |
|----------|---|---|
| BUS‑01 | Each employee must have an individual corporate account. Routine use of shared user accounts is prohibited. | Must |
| BUS‑02 | Users must be able to access Gmail, Google Drive, Google Docs, Microsoft Office, communication tools, printers, scanners, and other approved applications required by their roles. | Must |
| BUS‑03 | The normal sign-in process should require one primary corporate identity and minimize repeated authentication across approved services. | Should |
| BUS‑04 | A user must be able to resume normal work on a replacement PC using a documented provisioning process. | Must |
| BUS‑05 | Planned migration downtime should not exceed an agreed per-user maintenance window. | Must |
| BUS‑06 | The target service must support at least 10 users and 10 PCs without redesign. | Must |
| BUS‑07 | The design should support growth to approximately 20 users or devices through licensing and configuration changes rather than architectural replacement. | Should |
| BUS‑08 | The target operating model must be supportable remotely by a qualified administrator. | Must |
| BUS‑09 | User training must cover the new sign-in process, MFA, password or passkey recovery, file access, and support escalation. | Must |
| BUS‑10 | The solution must not require users to understand or administer infrastructure components. | Must |
| BUS‑11 | Loss or replacement of one office PC must not make a user's business data or essential applications unavailable beyond the approved recovery interval. | Must |
| BUS‑12 | Where mobility is approved, a user should be able to perform normal SaaS-based work from an approved external location without first connecting to the office LAN. | Should |

## 7. Target-state qualities, portability, and mobility requirements

Mobility is an optional or ideal-state capability, not permission for uncontrolled access from any personal device. If enabled, it must use approved identities, MFA, access policies, and endpoint or browser controls. Portability is broader and remains important even when users normally work in the office: the business must be able to replace a PC, change support providers, recover administrative control, and export its data without reconstructing the environment from undocumented knowledge.

The design priority is: mandatory business and security needs first; then stability and recoverability; then simplicity and low operating cost; then optional mobility enhancements. Portability and mobility must not introduce servers, virtual-desktop infrastructure, duplicate management platforms, premium licenses, or recurring specialist effort unless the resulting business benefit is documented and proportionate to a 6–10 PC environment.

### 7.1 Lightweight infrastructure and maintainability

| ID       | Requirement | Priority |
|----------|---|---|
| NFR‑01 | The permanent target should contain no customer-managed domain controller or general-purpose infrastructure server unless a confirmed business application requires it. | Should |
| NFR‑02 | The number of identity, endpoint-management, security, backup, and monitoring platforms must be minimized. Each additional platform must address a documented gap. | Must |
| NFR‑03 | The design must favor supported SaaS and managed services over self-hosted servers and custom components. | Must |
| NFR‑04 | Routine administration for up to 10 users and PCs should normally require no more than approximately four hours per month, excluding incidents, projects, and major upgrades. | Should |
| NFR‑05 | Common operations must be executable through documented administrative procedures without custom development. | Must |
| NFR‑06 | Configuration must use standard policies, groups, templates, or repeatable automation rather than undocumented one-off settings on individual PCs. | Must |
| NFR‑07 | The business must not need a full-time cloud, Windows, or virtual-desktop specialist to operate the target environment. | Must |
| NFR‑08 | Monitoring must be exception-based: administrators should receive actionable alerts rather than manually inspect every system each day. | Should |
| NFR‑09 | Product features that add continuous operational burden without satisfying a mandatory requirement should not be deployed. | Should |
| NFR‑10 | Optional portability or mobility features should reuse the core identity, endpoint, security, and SaaS controls rather than create a separate remote-access operating model. | Should |

### 7.2 Cost control

| ID       | Requirement | Priority |
|----------|---|---|
| CST‑01 | The selected solution must have an approved monthly operating-cost ceiling covering licenses, cloud resources, backup, endpoint security, and support. | Must |
| CST‑02 | Monthly charges must be predictable for the normal 6–10 user workload. Consumption-based services must have budgets and alerts. | Must |
| CST‑03 | Existing Google Workspace, Microsoft Office, Windows, security, and backup entitlements must be inventoried before new licenses are purchased. | Must |
| CST‑04 | Duplicate email, storage, identity, security, or endpoint-management licenses must be justified by a requirement rather than vendor bundling alone. | Must |
| CST‑05 | Solution selection must compare at least three-year total cost of ownership, including implementation, subscriptions, cloud consumption, hardware replacement, support, and administration. | Must |
| CST‑06 | Reserved capacity, long-term commitments, or premium service tiers should be purchased only after a pilot confirms sustained need. | Should |
| CST‑07 | Costs must be reviewable per user, per device, and per shared infrastructure component. | Should |
| CST‑08 | The incremental licensing, infrastructure, support, and administration cost of optional mobility must be separately identified and approved before enablement. | Must |

### 7.3 Stability and service continuity

| ID       | Requirement | Priority |
|----------|---|---|
| STB‑01 | The target must use generally available, vendor-supported services and configurations for production workloads. Preview features must not be production dependencies. | Must |
| STB‑02 | A failure of one endpoint must not cause organization-wide authentication, application, or data loss. | Must |
| STB‑03 | No irreplaceable business data, administrative credential, recovery key, or configuration may exist only on one office PC. | Must |
| STB‑04 | Routine platform and endpoint maintenance must be schedulable and must not require organization-wide downtime. | Should |
| STB‑05 | Changes must be piloted, reversible where practical, and introduced in small batches. | Must |
| STB‑06 | The design must define expected behavior during Internet, SaaS, identity-provider, and endpoint-management outages. | Must |
| STB‑07 | Business-critical cloud dependencies must have documented vendor status pages, support routes, and local escalation procedures. | Should |
| STB‑08 | The solution must avoid a single undocumented administrator, personal account, or privately owned domain as a control point. | Must |

### 7.4 User and device mobility

| ID       | Requirement | Priority |
|----------|---|---|
| MOB‑01 | The architecture should permit approved users to access Gmail, Google Drive, Google Docs, communication tools, and other browser-based SaaS from an approved remote location. | Could |
| MOB‑02 | Remote or mobile access must use the same corporate identity, MFA, access policy, logging, and offboarding controls as office access. | Conditional Must |
| MOB‑03 | Approved remote work must not require direct inbound RDP, SMB, LDAP, or administrative access to the office network. | Conditional Must |
| MOB‑04 | The organization must define whether mobility is limited to managed corporate devices or includes BYOD. BYOD access must be restricted by documented browser, application, data-download, and session controls. | Conditional Must |
| MOB‑05 | Lost or stolen mobile endpoints must be blockable immediately; corporate sessions and tokens must be revocable. | Conditional Must |
| MOB‑06 | Users should be able to move between an assigned PC and a replacement or approved secondary device without manual reconstruction of business data and core SaaS access. | Should |
| MOB‑07 | Offline access should be limited to specifically approved data and applications, with encryption and synchronization behavior documented. | Could |
| MOB‑08 | Remote performance must be tested for videoconferencing, file synchronization, browser applications, and any virtual-desktop traffic before mobility is approved. | Conditional Must |
| MOB‑09 | Mobility should use direct, policy-controlled access to cloud SaaS from managed endpoints where feasible; traffic should not be routed through the office or a hosted desktop without a demonstrated application, security, or data-control requirement. | Should |

### 7.5 Data and configuration portability

| ID       | Requirement | Priority |
|----------|---|---|
| PRT‑01 | Corporate domains, DNS registrations, tenant ownership, billing accounts, and administrator recovery methods must remain under company control. | Must |
| PRT‑02 | User and shared business data must be exportable in documented, commonly usable formats within the approved recovery or exit period. | Must |
| PRT‑03 | Identity, group, device, application, policy, license, and administrative-role inventories must be exportable or reproducible from current documentation. | Must |
| PRT‑04 | Standard endpoint settings and application deployment must be reproducible on replacement hardware without relying on the original PC. | Must |
| PRT‑05 | The organization must maintain a documented process to transfer support responsibility to another qualified administrator or service provider. | Must |
| PRT‑06 | The design should minimize proprietary dependencies that provide no material business or security benefit. | Should |
| PRT‑07 | A vendor or product exit plan must identify how identities, data, DNS, applications, backups, and administrative access would be recovered or migrated. | Should |
| PRT‑08 | Portability must not weaken security by copying unrestricted corporate data to unmanaged devices or personal accounts. | Must |

## 8. Identity and access requirements

| ID       | Requirement | Priority |
|----------|---|---|
| IAM‑01 | One approved directory must be the authoritative source for employee identity and lifecycle status. | Must |
| IAM‑02 | If both Microsoft and Google directories are retained, automated provisioning, federation, or another documented lifecycle process must prevent orphaned and inconsistent accounts. | Must |
| IAM‑03 | Usernames and primary email addresses must follow one documented convention across Windows, Google Workspace, Microsoft services, and integrated SaaS applications. | Must |
| IAM‑04 | MFA must be enforced for every user, with stronger authentication required for administrators. | Must |
| IAM‑05 | Phishing-resistant methods such as FIDO2 security keys, passkeys, or certificate-backed authentication should be used where practical. | Should |
| IAM‑06 | At least two emergency administrative accounts must exist, be protected separately, be monitored, and be tested periodically. | Must |
| IAM‑07 | Administrators must use separate privileged and normal user accounts. | Must |
| IAM‑08 | Administrative privileges must follow least privilege and be assigned by role or group. | Must |
| IAM‑09 | New-user access must be provisioned using a documented checklist. | Must |
| IAM‑10 | Terminated-user access must be revoked promptly across the identity provider, Windows devices, Google Workspace, Microsoft services, and other SaaS applications. | Must |
| IAM‑11 | Account recovery must not depend on a single employee, telephone number, or device. | Must |
| IAM‑12 | Single sign-on using SAML or OpenID Connect should be enabled for supported SaaS applications. | Should |
| IAM‑13 | Sign-in, administrator, provisioning, and access-policy audit logs must be available and retained for an agreed period. | Must |
| IAM‑14 | Conditional or context-aware access should block or challenge access from noncompliant devices, high-risk sessions, or unexpected locations where licensing supports it. | Should |
| IAM‑15 | Shared mailboxes, group addresses, delegated Drive content, and service identities must have named owners and must not depend on an employee's personal credentials. | Must |

## 9. Windows endpoint requirements

| ID       | Requirement | Priority |
|----------|---|---|
| END‑01 | Every production endpoint must run an operating system release that is supported by Microsoft or be covered temporarily by valid commercial ESU. | Must |
| END‑02 | The permanent target must be a supported Windows 11 Pro, Pro for Workstations, Enterprise, or Education edition appropriate to the selected management platform. | Must |
| END‑03 | Windows Home editions must be upgraded or replaced because they do not support Microsoft Entra Join and lack required business-management capabilities. | Must |
| END‑04 | Every PC must be recorded in a central inventory with device name, serial number, model, assigned user, operating-system version, ownership, encryption state, compliance state, and last contact. | Must |
| END‑05 | Full-disk encryption using BitLocker must be enabled on each capable device. Recovery keys must be escrowed centrally and accessible only to authorized administrators. | Must |
| END‑06 | Supported antivirus or endpoint detection and response, Windows Firewall, reputation protection, and browser protections must be enabled and centrally monitored. | Must |
| END‑07 | Windows quality and security updates must be deployed automatically within a defined deadline. Update status and failures must be reportable. | Must |
| END‑08 | Feature upgrades must be planned, tested, and completed before the installed Windows release reaches end of service. | Must |
| END‑09 | Users must not receive permanent local-administrator rights. | Must |
| END‑10 | A managed support administrator account must exist on every PC, with a unique automatically rotated password or an equivalent secure mechanism. | Must |
| END‑11 | Screen locking, password or PIN requirements, inactivity timeout, and failed-sign-in controls must be centrally configured. | Must |
| END‑12 | Required applications and settings must be deployable through a repeatable documented method. | Must |
| END‑13 | Unapproved or high-risk software must be detectable and removable. | Should |
| END‑14 | Lost, stolen, compromised, or retired devices must be blockable and remotely wipeable where the selected platform supports it. | Must |
| END‑15 | USB storage, clipboard, local drive, printer, camera, microphone, and browser-extension controls must be configurable where business risk requires them. | Should |
| END‑16 | The endpoint design must preserve access to approved printers, scanners, webcams, headsets, multiple monitors, and other required peripherals. | Must |
| END‑17 | A replacement or rebuilt PC should be ready for normal user work within one business day after hardware availability. | Should |
| END‑18 | Remote support must use an approved authenticated support tool. Direct Internet exposure of RDP is prohibited. | Must |

## 10. Google Workspace and SaaS requirements

| ID       | Requirement | Priority |
|----------|---|---|
| GWS‑01 | Existing Gmail addresses, aliases, groups, calendars, shared drives, Drive ownership, and sharing relationships must be preserved. | Must |
| GWS‑02 | Google Workspace access must use the approved corporate identity and MFA policy. | Must |
| GWS‑03 | If another identity provider becomes authoritative, Google Workspace must be integrated through supported federation and lifecycle provisioning. | Must |
| GWS‑04 | At least one emergency Google super-administrator method must remain usable if federated sign-in is unavailable. | Must |
| GWS‑05 | Google Drive for desktop, browser access, offline behavior, local caching, shared drives, and user sign-out behavior must be tested on the target endpoint or desktop design. | Must |
| GWS‑06 | SaaS applications must be inventoried with business owner, administrator, user assignment, authentication method, licensing, data classification, and offboarding procedure. | Must |
| GWS‑07 | OAuth application access and third-party integrations must be reviewed; unapproved or excessive permissions must be removed. | Must |
| GWS‑08 | External sharing must be restricted according to business need and reviewed periodically. | Must |
| GWS‑09 | Google Workspace and critical SaaS audit logs must be available to the designated administrator. | Must |
| GWS‑10 | SaaS availability, support, data export, and account-recovery dependencies must be documented for critical services. | Should |

## 11. Application requirements

| ID       | Requirement | Priority |
|----------|---|---|
| APP‑01 | Every locally installed application must be inventoried with name, version, owner, installer, license, data location, update method, and business criticality. | Must |
| APP‑02 | Every application must be assessed for dependencies on AD groups, domain computer accounts, LDAP, Kerberos, NTLM, integrated Windows authentication, mapped drives, file shares, or domain service accounts. | Must |
| APP‑03 | Applications with an AD dependency must be upgraded, reconfigured, replaced, isolated behind an approved interim service, or declared a blocker to AD retirement. | Must |
| APP‑04 | Microsoft Office must remain properly licensed for the selected physical-PC or virtual-desktop model. | Must |
| APP‑05 | Office activation, updates, add-ins, templates, macros, file associations, and integration with Google Drive must be tested. | Must |
| APP‑06 | Browser bookmarks, approved extensions, certificates, saved business data, and application settings required for work must be migrated or reproducibly configured. | Must |
| APP‑07 | Application installers, configuration instructions, license information, and support contacts must be retained in an administrator-accessible repository. | Must |
| APP‑08 | Unsupported applications must not be carried forward without a documented exception and risk treatment. | Must |

## 12. Data, backup, and recovery requirements

| ID       | Requirement | Priority |
|----------|---|---|
| DAT‑01 | All business data locations must be identified, including server shares, local Desktop/Documents folders, browser downloads, email, Google Drive, removable media, and application-specific data. | Must |
| DAT‑02 | Business data must be stored in an approved company-controlled location rather than only in a local user profile. | Must |
| DAT‑03 | File ownership, permissions, shared-drive membership, external sharing, and retention must be defined before migration. | Must |
| DAT‑04 | Data synchronization must not be treated as backup. A separate recovery method must protect critical Google Workspace, endpoint, and application data. | Must |
| DAT‑05 | Backup scope, frequency, retention, encryption, storage location, and administrative ownership must be documented. | Must |
| DAT‑06 | Required recovery point objective and recovery time objective must be approved for user data and critical business services. | Must |
| DAT‑07 | At least one sample file, user account, and configuration recovery must be tested before AD decommissioning. | Must |
| DAT‑08 | Deleted-user data transfer, retention, and eventual deletion must be included in offboarding. | Must |
| DAT‑09 | Sensitive data must be encrypted in transit and at rest using supported service capabilities. | Must |
| DAT‑10 | Canadian data-residency or sector-specific privacy requirements must be confirmed before platform selection; they must not be assumed. | Must |

## 13. Network and office infrastructure requirements

| ID       | Requirement | Priority |
|----------|---|---|
| NET‑01 | The office must retain a supported business-grade router/firewall with current firmware and protected administrative access. | Must |
| NET‑02 | The firewall/router or another approved service must provide DHCP if DHCP currently runs on Windows Server. | Must |
| NET‑03 | AD-integrated DNS must be replaced with a documented DNS design before the domain controller is removed. | Must |
| NET‑04 | Business and guest Wi-Fi must be separated. Guest devices must not have unrestricted access to corporate endpoints. | Must |
| NET‑05 | No endpoint or management service may require direct inbound exposure of RDP, SMB, LDAP, or administrative interfaces to the Internet. | Must |
| NET‑06 | Required cloud-service endpoints must be reachable through documented firewall and DNS rules. | Must |
| NET‑07 | Internet bandwidth, latency, stability, and data caps must support normal concurrent use of Google Workspace, Office, communications, backup, and the selected desktop architecture. | Must |
| NET‑08 | A secondary Internet service or cellular failover should be provided if loss of cloud access would stop business operations. | Should |
| NET‑09 | Network equipment configuration must be backed up, and administrative credentials must be held in the approved password-management system. | Must |
| NET‑10 | If remote work is required, access must use the selected cloud service or an approved VPN/zero-trust service rather than exposing office PCs directly. | Must |

## 14. Security and compliance requirements

| ID       | Requirement | Priority |
|----------|---|---|
| SEC‑01 | The organization must define a minimum security baseline covering identity, endpoint, SaaS, network, backup, and administrator controls. | Must |
| SEC‑02 | Security policies must be centrally configured and reportable. Manual per-PC configuration alone is insufficient. | Must |
| SEC‑03 | High-risk sign-ins, repeated authentication failures, endpoint malware, disabled protection, encryption failures, and noncompliant devices must generate actionable alerts where supported. | Must |
| SEC‑04 | Corporate secrets, recovery codes, license keys, and administrative credentials must be stored in an approved password or secrets manager. | Must |
| SEC‑05 | Administrator activity and security events must be logged and reviewable. | Must |
| SEC‑06 | Security responsibilities must have named primary and backup owners. | Must |
| SEC‑07 | Cyber-insurance, contractual, privacy, and legal requirements must be collected and mapped to controls before final approval. | Must |
| SEC‑08 | A basic incident-response procedure must define account containment, device isolation, credential reset, evidence preservation, recovery, and notification. | Must |
| SEC‑09 | Access, device inventory, external sharing, and administrative roles should be reviewed at least quarterly. | Should |
| SEC‑10 | The environment must not depend on security-by-obscurity, shared passwords, unsupported software, or unmonitored administrator accounts. | Must |

## 15. Operational and support requirements

| ID       | Requirement | Priority |
|----------|---|---|
| OPS‑01 | Routine user, license, device, policy, application, security, and backup administration must be documented. | Must |
| OPS‑02 | Onboarding, role change, leave of absence, and offboarding procedures must be documented and tested. | Must |
| OPS‑03 | A current list of service providers, subscriptions, renewal dates, administrators, support contacts, and billing owners must be maintained. | Must |
| OPS‑04 | Monitoring must identify inactive accounts, stale devices, failed updates, endpoint threats, backup failures, and cloud-service incidents. | Must |
| OPS‑05 | A standard device naming, ownership, and assignment convention must be used. | Should |
| OPS‑06 | Configuration changes must be recorded with date, operator, purpose, and rollback information. | Should |
| OPS‑07 | The organization must retain at least two people or one internal owner plus an external support provider capable of recovering administrative access. | Must |
| OPS‑08 | Documentation must be sufficient for a qualified replacement administrator to operate the environment without relying on undocumented personal knowledge. | Must |
| OPS‑09 | Recurring licensing and cloud consumption must be reviewable and accompanied by cost alerts where applicable. | Must |
| OPS‑10 | The selected design must remain proportionate to a 6–10 PC environment and avoid infrastructure that requires continuous specialist administration unless a specific business requirement justifies it. | Must |

## 16. Discovery requirements before solution approval

The following evidence must be collected before any final architecture, cost, or decommissioning date is approved:

| ID       | Required discovery evidence | Priority |
|----------|---|---|
| DIS‑01 | AD forest/domain name, functional level, domain controllers, users, groups, computers, organizational units, and trusts | Must |
| DIS‑02 | Complete GPO inventory with settings, links, security filtering, and disposition | Must |
| DIS‑03 | Windows Server roles and features, including DNS, DHCP, file, print, AD Certificate Services, NPS/RADIUS, VPN, WSUS, and backup | Must |
| DIS‑04 | File shares, mapped drives, permissions, quotas, login scripts, redirected folders, and data volume | Must |
| DIS‑05 | Domain service accounts, Windows services, scheduled tasks, scripts, and stored credentials | Must |
| DIS‑06 | Applications and devices using LDAP, Kerberos, NTLM, integrated authentication, RADIUS, or AD groups | Must |
| DIS‑07 | PC hardware inventory, TPM status, Secure Boot status, Windows edition/build, Windows 11 compatibility, disk health, and free space | Must |
| DIS‑08 | User-to-PC assignment, local profiles, local data, printers, scanners, webcams, USB devices, and accessibility requirements | Must |
| DIS‑09 | Google Workspace edition, users, groups, aliases, shared drives, storage, administrators, OAuth apps, retention, and existing endpoint policies | Must |
| DIS‑10 | Microsoft 365, Office, Windows, endpoint-security, backup, remote-support, and other SaaS licenses | Must |
| DIS‑11 | Firewall, router, switches, Wi-Fi, Internet circuit, addressing, DHCP, DNS, VPN, and remote-access configuration | Must |
| DIS‑12 | Backup configuration, latest successful jobs, retention, offsite copies, and sample restore result | Must |
| DIS‑13 | Regulatory, contractual, insurance, data-residency, RTO, RPO, and acceptable-downtime requirements | Must |

## 17. Migration requirements

| ID       | Requirement | Priority |
|----------|---|---|
| MIG‑01 | A pilot must be completed with one representative user and one non-critical PC before broad migration. | Must |
| MIG‑02 | The current domain controller must remain available during the pilot and rollback period. | Must |
| MIG‑03 | A current server backup, endpoint data backup, configuration export, and verified recovery method must exist before each cutover wave. | Must |
| MIG‑04 | The migration procedure must define prechecks, user communication, data copy, profile handling, domain removal, target enrollment, application validation, rollback triggers, and support escalation. | Must |
| MIG‑05 | Existing AD user profiles must be migrated or associated using a tested method. Creating a new cloud identity must not silently abandon local data or application settings. | Must |
| MIG‑06 | Migration should occur in small waves, preferably one or two PCs at a time. | Should |
| MIG‑07 | Each migrated PC must pass the acceptance checklist before the next wave proceeds. | Must |
| MIG‑08 | Domain credentials, cached access, old agents, obsolete certificates, and stale device objects must be removed after acceptance and rollback expiry. | Must |
| MIG‑09 | The project must include user-facing instructions and heightened support during cutover. | Must |
| MIG‑10 | A stabilization period must be completed before AD DS decommissioning. | Must |

## 18. AD decommissioning gate

The AD DS server must not be demoted, disconnected, or destroyed until every item below is confirmed:

| ID       | Decommissioning condition | Priority |
|----------|---|---|
| DEC‑01 | All users can authenticate with the target cloud identity and complete MFA. | Must |
| DEC‑02 | All production PCs are migrated, centrally managed, encrypted, patched, protected, and accepted. | Must |
| DEC‑03 | Required GPO settings have been replaced, made unnecessary, or formally waived. | Must |
| DEC‑04 | DNS and DHCP have been migrated and validated. | Must |
| DEC‑05 | File shares, print queues, scripts, scheduled tasks, services, and profile dependencies have been migrated or retired. | Must |
| DEC‑06 | No required system depends on LDAP, Kerberos, NTLM, RADIUS, AD groups, domain computer accounts, or domain service accounts. | Must |
| DEC‑07 | Certificate-services and certificate-enrollment dependencies have been replaced or proven absent. | Must |
| DEC‑08 | Google Workspace, Microsoft Office, communication tools, SaaS applications, printers, scanners, and peripherals pass acceptance tests. | Must |
| DEC‑09 | Data backup and sample recovery tests have succeeded. | Must |
| DEC‑10 | Onboarding, offboarding, administrator recovery, device replacement, and incident-response procedures have been tested. | Must |
| DEC‑11 | The rollback window and stabilization period have expired without an unresolved critical defect. | Must |
| DEC‑12 | Final approval has been recorded by the business owner and technical owner. | Must |

## 19. Acceptance criteria

The selected solution is accepted only when the following measurable outcomes are met:

1. All in-scope users can sign in using their assigned corporate identities and required MFA.
2. All production PCs appear in the management inventory and report a compliant state.
3. Every production PC runs a supported Windows release or has documented temporary commercial ESU coverage and an approved retirement date.
4. BitLocker is enabled and a recovery key can be retrieved by an authorized administrator for every capable PC.
5. Endpoint security is active, current, centrally visible, and tested with an approved non-malicious validation method.
6. Windows update status is centrally reportable and no production PC has an unapproved overdue critical security update.
7. Standard users cannot obtain permanent local-administrator privileges.
8. Gmail, Drive, Docs, Office, communication tools, printers, scanners, browsers, and required applications pass documented user acceptance tests.
9. A replacement-device or rebuild test demonstrates that a representative user can resume work using the documented process.
10. A sample business file and one selected configuration or account item can be recovered from backup.
11. Disabling a test user prevents further access to the endpoint and business SaaS services within the approved offboarding interval.
12. No unresolved AD DS dependency remains in the discovery and decommissioning register.
13. The on-premises domain controller can be shut down during a controlled validation period without affecting accepted business functions.
14. Operations, recovery, licensing, architecture, inventory, and support documentation have been handed over.
15. A representative user can resume approved core work from a replacement device without retrieving data or configuration from the failed PC.
16. Company administrators can export current identity, group, device, policy, license, and data inventories using the documented procedures.
17. The validated recurring cost remains within the approved operating budget and all consumption-based services have working budget alerts.
18. The final design has no undocumented server, account, credential, device, or administrator that constitutes a single point of organizational control.
19. If mobility is enabled, a representative remote-access test passes identity, MFA, access-policy, SaaS, communications, performance, token-revocation, and lost-device scenarios.
20. Any optional mobility component has a documented business benefit, incremental cost, support owner, and removal path, and does not create an unjustified parallel management platform.

## 20. Open decisions

The following decisions are required before converting this draft into an approved requirements baseline:

- Exact number of named users and PCs
- Required remote-work model
- Whether mobility is required, preferred, or deferred
- Whether remote access is limited to managed corporate devices or permits controlled BYOD
- Approved monthly operating-cost ceiling and three-year total-cost target
- Acceptable routine administration effort for the environment
- Authoritative cloud identity provider
- Required level of Windows management and software deployment
- Windows 11 compatibility and replacement schedule for every PC
- Temporary Windows 10 ESU need and duration
- Existing Google Workspace edition and whether an upgrade is required
- Existing Microsoft Office and Windows licensing
- Required endpoint-security and backup products
- Business-critical applications and any AD dependencies
- Internet failover requirement
- RTO, RPO, acceptable migration downtime, and stabilization period
- Data-residency, privacy, cyber-insurance, and legal-retention obligations
- Internal technical owner and external support arrangement

## 21. References

- [Microsoft: Windows 10 support ended on October 14, 2025](https://support.microsoft.com/en-us/windows/deployment/updates-lifecycle/windows-10-support-has-ended-on-october-14-2025)
- [Microsoft: Windows 10 Extended Security Updates for organizations](https://learn.microsoft.com/en-us/windows/whats-new/extended-security-updates)
- [Microsoft: Microsoft Entra joined devices](https://learn.microsoft.com/en-us/entra/identity/devices/concept-directory-join)
- [Google: Enhanced desktop security for Windows](https://knowledge.workspace.google.com/admin/devices/overview-enhanced-desktop-security-for-windows)
- [Google: Device requirements for Google endpoint management](https://knowledge.workspace.google.com/admin/devices/device-requirements-for-google-endpoint-management)
- [Google: Prepare to install Google Credential Provider for Windows](https://knowledge.workspace.google.com/admin/devices/prepare-to-install-gcpw)
