# Cloud Migration Demo

Architecture and requirements documentation for modernizing a small-business Windows environment and retiring its on-premises Active Directory Domain Services (AD DS) dependency.

## Scope

- Six initial users and six company-owned Windows PCs, with room to grow to 6–10 devices.
- Google Workspace remains the primary collaboration platform.
- Microsoft Office and common SaaS applications remain in scope.
- The target removes the local domain controller only after all AD DS dependencies are migrated, replaced, or formally accepted.

## Documents

| Document | Purpose |
|---|---|
| [requirements.md](requirements.md) | Authoritative, solution-neutral requirements and acceptance criteria. |
| [cloud_identity_migration_options.md](cloud_identity_migration_options.md) | Comparison, cost model, risks, recommendation, and migration steps for all three solutions. |
| [entra_id_intune_architecture.md](entra_id_intune_architecture.md) | Detailed design for Solution 1: Microsoft Entra ID + Microsoft Intune. |
| [google_workspace_gcpw_architecture.md](google_workspace_gcpw_architecture.md) | Detailed design for Solution 2: Google Workspace + GCPW. |
| [azure_virtual_desktop_architecture.md](azure_virtual_desktop_architecture.md) | Detailed design for Solution 3: Azure Virtual Desktop. |
| [tailscale_ansible_enterprise_solution.md](tailscale_ansible_enterprise_solution.md) | Enterprise Tailscale + Ansible multi-site architecture and operating model. |
| [tailscale_ansible_hands_on_lab.md](tailscale_ansible_hands_on_lab.md) | Hands-on four-site subnet-routing, SSH, WinRM, and Ansible validation lab. |

## Solutions evaluated

1. **Solution 1 — Microsoft Entra ID + Intune**: the recommended baseline for local Windows productivity, endpoint security, configuration, patching, and AD DS retirement.
2. **Solution 2 — Google Workspace + GCPW**: a viable Google-first alternative when Windows management requirements are simple and feature gaps are validated.
3. **Solution 3 — Azure Virtual Desktop**: a conditional solution for centralized desktops, legacy applications, or controlled access-terminal scenarios; it adds Azure consumption and operational complexity.

## Reliability decisions

- Cached Entra sign-in is enabled and must be tested for every assigned user and device so previously signed-in users can continue local Windows work during short identity or Internet outages.
- Two separately protected emergency accounts and independent recovery methods are required.
- Dual-WAN/5G or cellular Internet remains an optional failover enhancement, selected according to the approved RTO and business case.
- UPS protection, network configuration backups, spare equipment, and recovery testing are required where the approved availability target justifies them.
- A one-host AVD deployment remains a single point of failure; two hosts improve availability but increase cost.

## Budgetary cost model

The current planning model uses Canadian dollars before tax for six users and six devices. It separates one-time deployment, recurring operational cost, and routine maintenance labor.

| Solution | Deployment | Operations / month | Maintenance / month |
|---|---:|---:|---:|
| Solution 1: Entra ID + Intune | CAD 4,000–7,200 | CAD 380–450 | CAD 250–600 |
| Solution 2: Google Workspace + GCPW | CAD 3,500–6,600 | CAD 290–540 | CAD 375–900 |
| Solution 3: Azure Virtual Desktop | CAD 7,250–15,600 | CAD 980–1,850 | CAD 750–1,800 |

These are planning ranges, not quotations. Existing licenses can reduce incremental cost. Hardware replacement, Internet service, optional dual-WAN/5G or UPS, major application remediation, incident response, and vendor support contracts are excluded. See the [cost summary](cloud_identity_migration_options.md#9-cost-summary) for assumptions and pilot/one-host alternatives.

## Architecture diagrams

- [Solution 1 diagram](images/entra_id_intune_target_architecture.png)
- [Solution 2 diagram](images/google_gcpw_target_architecture.png)
- [Solution 3 diagram](images/azure_virtual_desktop_target_architecture.png)

## Current status

This repository contains draft architecture and requirements documentation. Before production approval, complete discovery, application and AD dependency validation, licensing confirmation, pilot testing, backup/restore testing, outage testing, cost approval, rollback planning, and the AD DS decommissioning gate.
