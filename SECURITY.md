# Security Policy

Thank you for helping keep Shopiz and its users safe.

## Reporting a vulnerability

Please report vulnerabilities privately through [GitHub Security Advisories](https://github.com/iamlehuyphuong/shopiz/security/advisories/new). Do not open public issues or post details on social media before a fix is released.

A good report includes:

- The affected feature, endpoint or file.
- Steps to reproduce, ideally against a fresh self-hosted instance.
- A clear, realistic description of the impact.

Shopiz is maintained by volunteers. We will acknowledge your report as soon as we can, keep you updated on the fix, and credit you in the advisory if you wish. We do not run a paid bug bounty.

If the issue also affects upstream Chatwoot (code we have not modified), please report it to Chatwoot as well through their [security advisory form](https://github.com/chatwoot/chatwoot/security/advisories/new).

## Supported versions

Only the latest commit on the `main` branch receives security fixes.

## In scope

> Test only against your own self-hosted instance. Do not test against production services you do not own.

- Remote code execution
- SQL injection
- Authentication bypass
- Privilege escalation, including access to data from another account
- Cross-site scripting (XSS)
- CSRF
- Leaks of stored credentials (API keys, payment gateway keys, channel tokens)
- Payment webhook forgery (SePay, PayOS, Tingee)

## Out of scope

- Missing HTTP security headers
- Missing or incomplete SPF/DKIM
- Reports from automated scanners without a working proof of concept
- Theoretical attacks without proof of exploitability
- Social engineering and physical attacks
- Reflected file download
- Weak SSL/TLS/SSH algorithms or protocols
- Attacks that need physical access to a device or an already compromised network
- Users attacking themselves
- Denial of service and brute-force attacks
- DNSSEC
- Account restrictions applied by Zalo to accounts that use the unofficial Zalo Personal integration
