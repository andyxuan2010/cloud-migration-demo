# Hands-On Lab: Tailscale + Ansible Across Four Sites

**Document status:** Training and validation guide; replace all example addresses, hostnames, identities, and secrets before production use.  
**Document relationship:** Validates [`tailscale_ansible_enterprise_solution.md`](tailscale_ansible_enterprise_solution.md) against a four-site lab  
**Scope:** Sites A–D with the supplied example CIDRs and representative targets  
**Lab objective:** Build a controlled four-site Tailscale overlay, advertise each LAN as a subnet route, and use an Ansible control node at Site B to manage Linux and Windows hosts at Sites A–D.  
**Date:** 2026-09-01  

## 1. What this lab proves

At the end of the lab, the Site B Ansible controller and an approved Site B home PC should be able to:

- reach the four site prefixes through Tailscale subnet routers;
- SSH to Linux subnet routers and Linux managed nodes;
- manage Windows hosts through WinRM/PSRP;
- test approved HTTPS, RDP, SMB, and application ports without exposing them to the public Internet;
- run one Ansible validation play across all four sites;
- demonstrate the difference between route advertisement, route approval, Tailscale policy, and host firewall policy; and
- optionally test exact-prefix subnet-router failover.

This lab uses one router per site for the minimum path. Site A, C, and D therefore have an intentional router single point of failure in the base lab. The enterprise design recommends a second router at every site where the recovery objective requires it.

## 2. Lab topology

| Site | LAN prefix | Lab subnet router | Ansible-relevant systems |
|---|---|---|---|
| A | `192.168.0.0/24` | `tsr-a-01` / `192.168.0.2` Linux VM | `a-ad-01` `.10`, `a-ad-02` `.11`, `a-pc-01` to `a-pc-10` `.101` to `.110` |
| B | `192.168.10.0/24` | `tsr-b-01` / `192.168.10.2` Linux | `ansible-b-01` `.20`, 5 Windows servers `.21` to `.25`, 5 Linux servers `.41` to `.45`, 10 VMs `.61` to `.70` |
| C | `192.168.30.0/24` | `tsr-c-01` / `192.168.30.2` Linux workstation | `c-node-01` `.101` representative Linux workstation; other mobile/PC nodes are optional Tailscale clients |
| D | `192.168.40.0/24` | `tsr-d-01` / `192.168.40.2` Linux workstation | `d-node-01` `.101` representative Linux workstation; other mobile/PC nodes are optional Tailscale clients |

The example uses `.2` for the site router. Reserve the address in DHCP/IPAM or replace it with the actual fixed address. Never use the same prefix at two sites.

### 2.1 Traffic paths

```mermaid
flowchart LR
    HOME[Site B home PC\nor Ansible control node]
    B[Site B subnet router\n192.168.10.2]
    TS((Tailscale tailnet\nWireGuard overlay))
    A[Site A subnet router\n192.168.0.2]
    C[Site C subnet router\n192.168.30.2]
    D[Site D subnet router\n192.168.40.2]
    ALAN[Site A LAN\nAD + PCs]
    CLAN[Site C LAN\nLinux + devices]
    DLAN[Site D LAN\nLinux + devices]

    HOME --- B
    B --- TS
    TS --- A
    TS --- C
    TS --- D
    A --- ALAN
    C --- CLAN
    D --- DLAN
```

The Ansible controller should be a direct Tailscale node. A home PC should also run Tailscale if it needs to reach the remote prefixes directly. A non-Tailscale client on the Site B LAN needs static routes on the Site B gateway and corresponding return-path design.

## 3. Prerequisites and safety

### 3.1 Required

- An organization-owned Tailscale tailnet and an administrator who can create tags, auth keys, Grants, and route approvals.
- One Linux system with Internet access and LAN reachability at each site. Site A’s Linux VM and the Site C/D Linux workstations satisfy the lab minimum.
- One separate Linux Ansible control node at Site B. It must not be the only Site B subnet router for the enterprise pattern.
- At least one reachable Linux target and one reachable Windows target for validation. The full inventory can be expanded after the representative path works.
- Local administrator access to Windows hosts and `sudo` access to Linux hosts.
- A protected place for auth keys, SSH private keys, WinRM credentials, and Ansible Vault passwords.

### 3.2 Safety rules

- Do not paste a real Tailscale auth key, password, private key, or certificate into this repository.
- Do not advertise a production prefix from a lab node.
- Do not enable a default route or exit node for this lab.
- Do not expose TCP `22`, `3389`, `445`, `5985`, or `5986` on a public interface.
- The WinRM HTTP path below is a lab-only shortcut. Production Windows management must use WinRM HTTPS or an approved domain/Kerberos design.
- Run the connectivity tests from a permitted source and an intentionally denied source so the access policy is proven rather than assumed.

## 4. Prepare the Tailscale policy

Create these tags and keep tag ownership limited to the network operations group:

| Tag | Purpose |
|---|---|
| `tag:subnet-router-a` | Site A route advertisers |
| `tag:subnet-router-b` | Site B route advertisers |
| `tag:subnet-router-c` | Site C route advertisers |
| `tag:subnet-router-d` | Site D route advertisers |
| `tag:ansible-control` | Site B Ansible controller |
| `tag:linux-managed` | Directly enrolled Linux managed nodes |

Start with a policy equivalent to the example in [the enterprise design](tailscale_ansible_enterprise_solution.md#62-illustrative-grants-policy). For a lab, the minimum logical requirements are:

1. auto-approve only the four exact site routes for the matching router tag, or approve them manually in the admin console;
2. permit `tag:ansible-control` to the site prefixes on ICMP, TCP `22`, TCP `443`, and TCP `5986`;
3. permit lab-only WinRM TCP `5985` if the HTTP path is used;
4. permit human operators to reach the subnet routers on TCP `22` and TCP `443`; and
5. add Tailscale SSH rules only for directly enrolled Linux nodes and approved local users.

Tailscale route approval and access policy are separate. A route can appear in the client routing table and still be denied by the policy, or a policy can allow an address without injecting a route.

## 5. Create scoped enrollment keys

Create separate pre-approved, tagged auth keys for the router roles and a separate key for the Ansible controller. Use placeholders in the commands below:

```bash
# Examples only; obtain keys from the Tailscale admin console or approved secret manager.
export TS_AUTHKEY_ROUTER_A='tskey-auth-REDACTED-A'
export TS_AUTHKEY_ROUTER_B='tskey-auth-REDACTED-B'
export TS_AUTHKEY_ROUTER_C='tskey-auth-REDACTED-C'
export TS_AUTHKEY_ROUTER_D='tskey-auth-REDACTED-D'
export TS_AUTHKEY_ANSIBLE='tskey-auth-REDACTED-ANSIBLE'
```

Use a separate key per site so that revoking Site C enrollment does not affect Site A or the control node. Store the real values in the shell environment, secret manager, or CI secret store only for the duration of enrollment.

## 6. Prepare each Linux subnet router

Run the following on the Linux router at each site. Use the distribution’s package repository in production; the install script is convenient for a disposable lab.

```bash
# Install Tailscale on a supported Linux distribution.
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled

# Enable IPv4 forwarding for subnet routing.
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale-router.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale-router.conf

# Confirm the router has a LAN route and an Internet path before continuing.
ip -4 addr
ip route
```

Enable IPv6 forwarding as well if IPv6 is part of the real site design. Do not enable it merely because the lab does not use IPv6.

### 6.1 Enroll and advertise the site route

Run the site-specific command on each router:

```bash
# Site A
sudo tailscale up --auth-key="$TS_AUTHKEY_ROUTER_A" --hostname=tsr-a-01 --advertise-tags=tag:subnet-router-a
sudo tailscale set --advertise-routes=192.168.0.0/24

# Site B
sudo tailscale up --auth-key="$TS_AUTHKEY_ROUTER_B" --hostname=tsr-b-01 --advertise-tags=tag:subnet-router-b
sudo tailscale set --advertise-routes=192.168.10.0/24

# Site C
sudo tailscale up --auth-key="$TS_AUTHKEY_ROUTER_C" --hostname=tsr-c-01 --advertise-tags=tag:subnet-router-c
sudo tailscale set --advertise-routes=192.168.30.0/24

# Site D
sudo tailscale up --auth-key="$TS_AUTHKEY_ROUTER_D" --hostname=tsr-d-01 --advertise-tags=tag:subnet-router-d
sudo tailscale set --advertise-routes=192.168.40.0/24
```

Replace the auth-key value with the key for the specific site. Use `tailscale status`, `tailscale ip -4`, and `tailscale status --json` to confirm the node is enrolled and advertising the intended route.

### 6.2 Router firewall forwarding

The subnet router must allow forwarding from `tailscale0` to the LAN interface and allow return traffic. The exact implementation depends on `nftables`, `iptables`, `firewalld`, or UFW. The following is a lab example; replace `eth0` with the real LAN interface and persist the rules using the distribution’s firewall manager.

```bash
LAN_IF=eth0
sudo iptables -A FORWARD -i tailscale0 -o "$LAN_IF" -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -i "$LAN_IF" -o tailscale0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

If the host uses firewalld, ensure forwarding and the required masquerade or no-SNAT behavior are represented in firewalld rather than adding unmanaged iptables rules. Do not use a broad `ACCEPT` policy on all interfaces.

### 6.3 Choose the lab routing mode

For the first lab run, keep the default subnet-route SNAT. It minimizes changes to the four existing gateways and lets a directly enrolled Site B controller reach hosts behind the remote routers.

For the enterprise-style extension, disable SNAT only after static return routes are ready:

```bash
sudo tailscale set --snat-subnet-routes=false
```

The no-SNAT mode preserves the originating address but requires each LAN gateway to return remote prefixes through the local subnet router. The extension is documented in [Section 14](#14-optional-no-snat-site-to-site-extension).

## 7. Approve and inspect the routes

In the Tailscale admin console:

1. open **Machines**;
2. filter for devices advertising subnets;
3. inspect the exact advertised route on each router;
4. approve only `192.168.0.0/24`, `192.168.10.0/24`, `192.168.30.0/24`, and `192.168.40.0/24`; and
5. confirm the route is assigned to the intended router and tag.

If using `autoApprovers`, remember that changing the policy does not retroactively approve an already pending route. Re-advertise the route or approve it manually.

## 8. Enroll the Site B Ansible controller

On `ansible-b-01`:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled
sudo tailscale up --auth-key="$TS_AUTHKEY_ANSIBLE" --hostname=ansible-b-01 --advertise-tags=tag:ansible-control

# Linux clients do not automatically accept subnet routes in every setup.
sudo tailscale set --accept-routes

tailscale ip -4
ip route
```

Confirm that the controller has routes for all four prefixes. The controller does not need to advertise Site B’s route unless it is also a subnet router; keep those roles separate in the enterprise design.

### 8.1 Enroll the home PC

Install the Tailscale client on the Site B home PC, authenticate it with the approved user identity, and verify that the client receives the approved subnet routes. Windows clients normally accept subnet routes automatically, but confirm the route and policy in the client status and with PowerShell:

```powershell
Test-NetConnection 192.168.0.10 -Port 22
Test-NetConnection 192.168.30.2 -Port 22
Test-NetConnection 192.168.40.2 -Port 22
```

If the home PC is not directly enrolled, it cannot use the tailnet overlay by itself. Add static routes on the Site B gateway for the remote prefixes via the Site B subnet router, and design the return path before enabling broad home-LAN access.

## 9. Validate raw connectivity before Ansible

Run from `ansible-b-01`:

```bash
# Check the directly enrolled routers.
tailscale ping tsr-a-01
tailscale ping tsr-b-01
tailscale ping tsr-c-01
tailscale ping tsr-d-01

# Check routed LAN addresses. Use only hosts that actually exist.
ping -c 3 192.168.0.10
ping -c 3 192.168.10.41
ping -c 3 192.168.30.2
ping -c 3 192.168.40.2

# Check required management ports.
nc -vz -w 5 192.168.0.10 22
nc -vz -w 5 192.168.0.10 5986
nc -vz -w 5 192.168.30.2 22
```

Ping may be disabled by a host firewall. A failed ping is not conclusive; use the service-port test and the host firewall logs. A failed TCP test can indicate an unapproved route, a denied Grant, a missing return route, a local firewall rule, or a service that is not listening.

## 10. Bootstrap Linux SSH

On each Linux target, create a dedicated automation account and install the controller’s public key. Run the bootstrap with the existing approved administrative method, not through the new path until the path is validated.

```bash
sudo useradd --create-home --shell /bin/bash ansible
sudo install -d -m 0700 -o ansible -g ansible /home/ansible/.ssh
sudo install -m 0600 -o ansible -g ansible /tmp/ansible-b-01.pub /home/ansible/.ssh/authorized_keys

# Prefer a narrow sudoers policy per role. This broad lab rule is not a production standard.
echo 'ansible ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/ansible-lab
sudo chmod 0440 /etc/sudoers.d/ansible-lab
```

From the controller:

```bash
ssh -i ~/.ssh/ansible_ed25519 -o IdentitiesOnly=yes ansible@192.168.0.2 hostname
ssh -i ~/.ssh/ansible_ed25519 -o IdentitiesOnly=yes ansible@192.168.30.2 hostname
ssh -i ~/.ssh/ansible_ed25519 -o IdentitiesOnly=yes ansible@192.168.40.2 hostname
```

For directly enrolled Linux routers, Tailscale SSH can be enabled for operator access with `sudo tailscale set --ssh`. It is optional and must be permitted in the tailnet policy. It is not the mechanism used to reach arbitrary Linux hosts behind a subnet router.

## 11. Bootstrap Windows management

Ansible supports Windows through WinRM/PSRP or SSH. This lab uses WinRM because it is common for Windows Server, AD servers, and Windows workstations. Configure Windows hosts before adding them to the inventory.

### 11.1 Lab-only WinRM HTTP path

Run as an elevated PowerShell session on the Windows test host. Set `$allowedRouterIp` to the LAN address of the subnet router at that site when the default Tailscale SNAT path is used.

```powershell
Enable-PSRemoting -Force

# NTLM over HTTP uses WinRM message encryption in the lab profile.
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $false
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $false

$allowedRouterIp = '192.168.0.2'  # Use 192.168.10.2, .30.2, or .40.2 at other sites.
Disable-NetFirewallRule -DisplayGroup 'Windows Remote Management'
New-NetFirewallRule -DisplayName 'Ansible WinRM lab from Tailscale router' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5985 -RemoteAddress $allowedRouterIp -Profile Any
```

Use this only on an isolated lab or where the Tailscale path and host firewall have been explicitly approved. Do not set `AllowUnencrypted` to `$true`, and do not enable Basic authentication over HTTP.

### 11.2 Enterprise WinRM HTTPS path

For production, create a WinRM HTTPS listener with a certificate trusted by the Ansible controller, restrict the Windows firewall to the approved management sources, and use TCP `5986`. In a domain environment, Kerberos is preferred when the DNS, SPN, and delegation design is ready. For local accounts, use NTLM or certificate authentication over trusted HTTPS.

Follow the current [Ansible Windows Remote Management guide](https://docs.ansible.com/projects/ansible-core/devel/os_guide/windows_winrm.html) for listener creation, authentication, encryption, and CA trust. A self-signed certificate with `ansible_winrm_server_cert_validation: ignore` is a lab exception only and must not become the production configuration.

## 12. Install Ansible on the controller

Use a dedicated Python virtual environment on `ansible-b-01`:

```bash
sudo apt-get update
sudo apt-get install -y python3-venv python3-pip openssh-client
python3 -m venv ~/venvs/ansible-tailscale
source ~/venvs/ansible-tailscale/bin/activate
python -m pip install --upgrade pip
python -m pip install ansible-core pywinrm
ansible-galaxy collection install ansible.windows
```

Install `pypsrp` instead of or in addition to `pywinrm` when the inventory uses the PSRP connection plugin. Pin the versions in the real project and test upgrades in a staging tailnet.

## 13. Build the Ansible inventory

Create `inventory/hosts.yml`. This is a representative full-site skeleton; add the remaining mobile and PC nodes only when they expose an approved management protocol.

```yaml
all:
  children:
    site_a:
      children:
        site_a_linux: {}
        site_a_windows: {}
    site_b:
      children:
        site_b_linux: {}
        site_b_windows: {}
    site_c:
      children:
        site_c_linux: {}
    site_d:
      children:
        site_d_linux: {}

    site_a_linux:
      hosts:
        tsr-a-01:
          ansible_host: 192.168.0.2
    site_a_windows:
      hosts:
        a-ad-01:
          ansible_host: 192.168.0.10
        a-ad-02:
          ansible_host: 192.168.0.11
        a-pc-01:
          ansible_host: 192.168.0.101
        a-pc-02:
          ansible_host: 192.168.0.102
        a-pc-03:
          ansible_host: 192.168.0.103
        a-pc-04:
          ansible_host: 192.168.0.104
        a-pc-05:
          ansible_host: 192.168.0.105
        a-pc-06:
          ansible_host: 192.168.0.106
        a-pc-07:
          ansible_host: 192.168.0.107
        a-pc-08:
          ansible_host: 192.168.0.108
        a-pc-09:
          ansible_host: 192.168.0.109
        a-pc-10:
          ansible_host: 192.168.0.110

    site_b_linux:
      hosts:
        ansible-b-01:
          ansible_host: 192.168.10.20
        tsr-b-01:
          ansible_host: 192.168.10.2
        b-linux-01:
          ansible_host: 192.168.10.41
        b-linux-02:
          ansible_host: 192.168.10.42
        b-linux-03:
          ansible_host: 192.168.10.43
        b-linux-04:
          ansible_host: 192.168.10.44
        b-linux-05:
          ansible_host: 192.168.10.45
        b-vm-01:
          ansible_host: 192.168.10.61
        b-vm-02:
          ansible_host: 192.168.10.62
        b-vm-03:
          ansible_host: 192.168.10.63
        b-vm-04:
          ansible_host: 192.168.10.64
        b-vm-05:
          ansible_host: 192.168.10.65
        b-vm-06:
          ansible_host: 192.168.10.66
        b-vm-07:
          ansible_host: 192.168.10.67
        b-vm-08:
          ansible_host: 192.168.10.68
        b-vm-09:
          ansible_host: 192.168.10.69
        b-vm-10:
          ansible_host: 192.168.10.70
    site_b_windows:
      hosts:
        b-win-srv-01:
          ansible_host: 192.168.10.21
        b-win-srv-02:
          ansible_host: 192.168.10.22
        b-win-srv-03:
          ansible_host: 192.168.10.23
        b-win-srv-04:
          ansible_host: 192.168.10.24
        b-win-srv-05:
          ansible_host: 192.168.10.25

    site_c_linux:
      hosts:
        tsr-c-01:
          ansible_host: 192.168.30.2
    site_d_linux:
      hosts:
        tsr-d-01:
          ansible_host: 192.168.40.2

    linux:
      children:
        site_a_linux: {}
        site_b_linux: {}
        site_c_linux: {}
        site_d_linux: {}
      vars:
        ansible_connection: ssh
        ansible_user: ansible
        ansible_become: true
        ansible_python_interpreter: /usr/bin/python3
        ansible_ssh_private_key_file: ~/.ssh/ansible_ed25519

    windows:
      children:
        site_a_windows: {}
        site_b_windows: {}
      vars:
        ansible_connection: winrm
        ansible_user: ansible_admin
        ansible_password: "{{ vault_windows_password }}"
        ansible_port: 5985
        ansible_winrm_transport: ntlm
        ansible_winrm_message_encryption: always
```

For the enterprise profile, change Windows to TCP `5986`, set `ansible_winrm_server_cert_validation: validate`, and configure `ansible_winrm_ca_trust_path` when a private CA is used. Keep the Windows password in an Ansible Vault file, not in the inventory.

The inventory layout follows Ansible’s supported pattern of stable aliases, `ansible_host` connection addresses, and separate group variables. Use `ansible-inventory --graph` to verify the group hierarchy before connecting.

## 14. Optional no-SNAT site-to-site extension

Complete the base SNAT lab first. Then, if the site gateways are under your control, add static routes before disabling SNAT.

### 14.1 Gateway route plan

Each route points remote site prefixes to the local subnet router. Add routes for the Tailscale CGNAT range as well if remote LAN hosts must return traffic to directly enrolled tailnet clients without SNAT.

| Gateway | Static routes via local router |
|---|---|
| Site A gateway | `192.168.10.0/24`, `192.168.30.0/24`, `192.168.40.0/24`, and optionally `100.64.0.0/10` via `192.168.0.2` |
| Site B gateway | `192.168.0.0/24`, `192.168.30.0/24`, `192.168.40.0/24`, and optionally `100.64.0.0/10` via `192.168.10.2` |
| Site C gateway | `192.168.0.0/24`, `192.168.10.0/24`, `192.168.40.0/24`, and optionally `100.64.0.0/10` via `192.168.30.2` |
| Site D gateway | `192.168.0.0/24`, `192.168.10.0/24`, `192.168.30.0/24`, and optionally `100.64.0.0/10` via `192.168.40.2` |

The exact CLI is vendor-specific. Confirm that the gateway installs the route in the forwarding table and that the host firewall allows the source and destination ranges.

### 14.2 Disable SNAT and test

```bash
# Run on each subnet router only after the gateway routes are active.
sudo tailscale set --snat-subnet-routes=false

# On the controller, keep route acceptance enabled.
sudo tailscale set --accept-routes

ip route get 192.168.0.10
traceroute -n 192.168.0.10
nc -vz -w 5 192.168.0.10 22
```

Confirm the target’s logs show the intended source address. If a connection works with SNAT but fails without it, the first suspects are the return route and the target firewall.

## 15. Run Ansible validation

Create `validate_fabric.yml`:

```yaml
---
- name: Validate Linux management paths
  hosts: linux
  gather_facts: false
  tasks:
    - name: Verify SSH and sudo path
      ansible.builtin.ping:

    - name: Collect Linux hostname
      ansible.builtin.command: hostname --fqdn
      register: linux_hostname
      changed_when: false

    - name: Show Linux site target
      ansible.builtin.debug:
        msg: "{{ inventory_hostname }} -> {{ linux_hostname.stdout }}"

- name: Validate Windows management paths
  hosts: windows
  gather_facts: false
  tasks:
    - name: Verify WinRM path
      ansible.windows.win_ping:

    - name: Collect Windows hostname
      ansible.windows.win_shell: '$env:COMPUTERNAME'
      register: windows_hostname
      changed_when: false

    - name: Show Windows site target
      ansible.builtin.debug:
        msg: "{{ inventory_hostname }} -> {{ windows_hostname.stdout | trim }}"
```

Run the inventory and validation in increasing scope:

```bash
source ~/venvs/ansible-tailscale/bin/activate
ansible-inventory -i inventory/hosts.yml --graph
ansible-inventory -i inventory/hosts.yml --list > /tmp/tailscale-ansible-inventory.json

ansible-playbook -i inventory/hosts.yml validate_fabric.yml --limit tsr-a-01,tsr-c-01,tsr-d-01
ansible-playbook -i inventory/hosts.yml validate_fabric.yml --limit a-ad-01,b-win-srv-01
ansible-playbook -i inventory/hosts.yml validate_fabric.yml
```

The first run limits blast radius. Do not move to the full inventory until the representative Linux and Windows nodes pass.

## 16. Test other approved services

From `ansible-b-01`, use a separate service test for each destination class. Do not infer that SSH success means SMB, RDP, or an application port is permitted.

```bash
# Linux/SSH
nc -vz -w 5 192.168.0.2 22
nc -vz -w 5 192.168.30.2 22

# Windows WinRM HTTPS production path
nc -vz -w 5 192.168.0.10 5986

# HTTPS application endpoint, if explicitly approved
curl --fail --connect-timeout 5 https://192.168.30.101/health

# Optional file-management path; use only for named servers
nc -vz -w 5 192.168.10.21 445
```

For RDP and Windows-side checks from the home PC:

```powershell
Test-NetConnection 192.168.0.10 -Port 3389
Test-NetConnection 192.168.10.21 -Port 445
Test-NetConnection 192.168.30.101 -Port 443
```

Add or remove ports in the Tailscale Grants and local firewalls as separate changes with an owner and review date.

## 17. Optional exact-prefix failover lab

To test Tailscale subnet-router failover, deploy a second Linux router on the same LAN and advertise the exact same prefix with the same site tag:

```bash
# Example for a second Site B router.
sudo tailscale up --auth-key="$TS_AUTHKEY_ROUTER_B" --hostname=tsr-b-02 --advertise-tags=tag:subnet-router-b
sudo tailscale set --advertise-routes=192.168.10.0/24
```

Approve the second advertisement if auto-approval is not enabled. Start a continuous permitted service test, stop Tailscale on `tsr-b-01`, and verify that the exact `/24` route becomes available through `tsr-b-02`. Allow approximately 15 seconds for the documented failover behavior and record the observed result.

Do not use a `/16` on one router and a `/24` on another as an HA test. Those are not equivalent failover candidates. For HA routers advertising the same local prefix, do not enable `accept-routes` on the standby unless the design specifically requires it, because the standby can select the remote copy of its own local route.

## 18. Troubleshooting guide

| Symptom | Likely cause | Check |
|---|---|---|
| Route is not visible on controller | Controller does not accept routes, route is not approved, or auto-approval did not apply | `sudo tailscale set --accept-routes`, admin console route state, `tailscale status --json` |
| Router appears online but LAN host is unreachable | IP forwarding, router firewall, host firewall, or return route | `sysctl net.ipv4.ip_forward`, forwarding rules, `ip route`, host logs |
| Tailscale route exists but connection is denied | Grant or host firewall denies the protocol/port | Review `grants`, source tag, destination CIDR, and local firewall logs |
| SSH to Linux times out | `sshd` is not listening, TCP 22 is blocked, or return traffic is asymmetric | `ss -lntp`, `nc -vz`, firewall rules, route mode |
| WinRM fails on 5985 | Listener, NTLM, local account, firewall scope, or message-encryption mismatch | `winrm enumerate winrm/config/listener`, Ansible connection vars, Windows event logs |
| WinRM HTTPS fails on 5986 | Certificate name/trust, CA path, listener, or port mismatch | Certificate SAN, `ansible_winrm_server_cert_validation`, CA trust, `Test-NetConnection` |
| Tailscale SSH cannot reach a routed Linux host | Destination does not run Tailscale SSH | Use standard SSH over the subnet route or enroll the destination directly |
| Only Tailscale-enabled clients work | LAN gateway lacks routes for non-Tailscale clients | Add gateway routes and return routes, or keep scope limited to enrolled clients |
| Failover does not occur | Routes differ, second route is pending, or policy does not permit the standby | Compare exact prefixes, approval state, tags, and policy |
| DNS name fails but IP works | MagicDNS does not resolve arbitrary routed LAN hosts | Use internal DNS/search suffixes or stable IPs in inventory; do not weaken policy to solve DNS |

## 19. Lab completion criteria

The lab is complete when:

- all four exact site routes are advertised, approved, and visible on the controller;
- the controller reaches one Linux and one Windows representative where available at each site;
- Linux validation passes through SSH and Windows validation passes through WinRM/PSRP;
- the home PC can reach only approved remote services;
- at least one denied source/port test is recorded;
- the route mode, source NAT behavior, and return paths are documented;
- the Ansible inventory is rendered successfully and the full validation play is idempotent;
- the temporary WinRM HTTP exception is removed or explicitly documented as a lab-only state; and
- if HA is tested, the second router advertises the exact same prefix and the observed failover time is recorded.

## 20. Cleanup

When the lab is finished:

1. remove or disable the four lab route advertisements;
2. delete or revoke the temporary enrollment keys;
3. remove lab nodes from the tailnet and delete stale device records;
4. remove lab firewall rules and temporary WinRM listeners;
5. remove lab SSH accounts and keys from target systems;
6. delete temporary Vault material and inventory exports; and
7. retain the test results, policy version, route plan, and lessons learned separately from secrets.

## 21. References

- [Tailscale subnet routers](https://tailscale.com/docs/features/subnet-routers)
- [Tailscale site-to-site networking](https://tailscale.com/docs/features/site-to-site)
- [Tailscale route injection](https://tailscale.com/docs/reference/route-injection)
- [Tailscale subnet-router high availability](https://tailscale.com/docs/how-to/set-up-high-availability)
- [Tailscale Grants syntax](https://tailscale.com/docs/reference/syntax/grants)
- [Tailscale auth keys](https://tailscale.com/docs/features/access-control/auth-keys)
- [Tailscale SSH](https://tailscale.com/docs/features/tailscale-ssh)
- [Install Tailscale on Linux](https://tailscale.com/docs/install/linux)
- [Ansible inventory guide](https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_inventory.html)
- [Managing Windows hosts with Ansible](https://docs.ansible.com/projects/ansible/latest/os_guide/intro_windows.html)
- [Ansible Windows Remote Management guide](https://docs.ansible.com/projects/ansible-core/devel/os_guide/windows_winrm.html)
- [Ansible WinRM connection plugin](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/winrm_connection.html)
