# A home lab setup, to have fun, because lego is boring

## Assumptions

* Linux based
* KVM
* Up to date, modern elements
* Easy on resources, to be deployed even on consumer grade or low power machines
* IPv6 exclusively

## Facts

* host is a Fedora 42+ Linux
* guests are by default Debian 13+
* guests don't run firewall
* ansible spins a vm for lab-building module - cicd (contains: gitlab; nexus; )
* ansible works from cicd to spin local lab infrastructure
  * firewall machine (Fedora firewalld)
  * directory machine (keycloak; dnsmasq; )
  * mail machine (postfix)
  * monitoring (grafana)

## Design

### Diagrams

* https://app.diagrams.net/#G15I-t4j3wDTWjsONr5aMKTUMs2lc6csEj#%7B%22pageId%22%3A%220-BMoZhDRUtmbl1ZNayE%22%7D

## cicd.playbox3.local

ext4 tuning: defaults,noatime,data=ordered
