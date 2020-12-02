RPI VPN Gateway
===============

Configures your Raspberry Pi with an attatched WiFi dongle or a Raspberry Pi3 with built in WiFi as a gateway to a vpn,
sharing your vpn connection to other devices. Could be useful for remote working!


Features:
---------

* Configured vpn starts automatically on boot, no extra configuration necessary (To Do)

* Once set up, the local network facilites of the Pi will still operate as normal

* Easy setup of either a custom or preconfigured DNS server (Cloudflare Kids (adult and malware filter), Clouflare Famillies(Malware filter), and Cloudflare fastest DNS)

Requirements:
-------------

1. A Raspberry Pi model B or Pi3+ running raspbian

2. An active ethernet/wifi connection


Installation:
-------------

* In the terminal, run:
    curl -s https://raw.githubusercontent.com/tunisiano187/RPI-VPN-Gateway/main/start.sh | sudo bash

* Confirm that you are happy for changes to be made

* Choose a preconfigured DNSalternative DNS or configure a custom DNS

* This should automatically set everything up and leave you ready to go


Notes and configuration
-----------------------

* This setup has been tested on a fresh install of raspbian.

* It is advised that this be set up on a fresh install