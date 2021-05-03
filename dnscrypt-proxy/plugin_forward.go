package main

import (
	"fmt"
	"math/rand"
	"net"
	"strings"

	"github.com/jedisct1/dlog"
	"github.com/miekg/dns"
)

type PluginForwardEntry struct {
	domain   string
	servers  []string
	fallback string
}

type PluginForward struct {
	forwardMap  []PluginForwardEntry
	fallbackTTL uint32
}

func (plugin *PluginForward) Name() string {
	return "forward"
}

func (plugin *PluginForward) Description() string {
	return "Route queries matching specific domains to a dedicated set of servers"
}

func (plugin *PluginForward) Init(proxy *Proxy) error {
	dlog.Noticef("Loading the set of forwarding rules from [%s]", proxy.forwardFile)
	bin, err := ReadTextFile(proxy.forwardFile)
	plugin.fallbackTTL = proxy.ForwardFallbackTTL
	if err != nil {
		return err
	}
	for lineNo, line := range strings.Split(string(bin), "\n") {
		line = TrimAndStripInlineComments(line)
		if len(line) == 0 {
			continue
		}

		domain, serversStr, fallback, ok := StringThreeFields(line)
		if !ok {
			domain, serversStr, ok = StringTwoFields(line)
			if !ok {
				return fmt.Errorf(
					"Syntax error for a forwarding rule at line %d. Expected syntax: example.com 9.9.9.9,8.8.8.8",
					1+lineNo,
				)
			}
		}
		domain = strings.ToLower(domain)
		var servers []string
		for _, server := range strings.Split(serversStr, ",") {
			server = strings.TrimSpace(server)
			if net.ParseIP(server) != nil {
				server = fmt.Sprintf("%s:%d", server, 53)
			}
			servers = append(servers, server)
		}
		if len(servers) == 0 {
			continue
		}
		plugin.forwardMap = append(plugin.forwardMap, PluginForwardEntry{
			domain:   domain,
			servers:  servers,
			fallback: fallback,
		})
	}
	return nil
}

func (plugin *PluginForward) Drop() error {
	return nil
}

func (plugin *PluginForward) Reload() error {
	return nil
}

func (plugin *PluginForward) Eval(pluginsState *PluginsState, msg *dns.Msg) error {
	qName := pluginsState.qName
	qNameLen := len(qName)
	var servers []string
	var fallback string
	for _, candidate := range plugin.forwardMap {
		candidateLen := len(candidate.domain)
		if candidateLen > qNameLen {
			continue
		}
		if qName[qNameLen-candidateLen:] == candidate.domain && (candidateLen == qNameLen || (qName[qNameLen-candidateLen-1] == '.')) {
			servers = candidate.servers
			fallback = candidate.fallback
			break
		}
	}
	if len(servers) == 0 {
		return nil
	}
	server := servers[rand.Intn(len(servers))]
	pluginsState.serverName = server
	client := dns.Client{Net: pluginsState.serverProto, Timeout: pluginsState.timeout}
	respMsg, _, err := client.Exchange(msg, server)
	if err != nil {
		return err
	}
	if respMsg.Truncated {
		client.Net = "tcp"
		respMsg, _, err = client.Exchange(msg, server)
		if err != nil {
			return err
		}
	}
	if edns0 := respMsg.IsEdns0(); edns0 == nil || !edns0.Do() {
		respMsg.AuthenticatedData = false
	}

	if respMsg.Rcode == dns.RcodeNameError && fallback != "" {
		dlog.Noticef("Generating fallback response, fallback: %s", fallback)
		synth := EmptyResponseFromMessage(msg)
		synth.Rcode = dns.RcodeSuccess
		synth.Answer = []dns.RR{}
		parsedIP := ParseIP(fallback)
		if parsedIP != nil {
			rr := new(dns.A)
			rr.Hdr = dns.RR_Header{Name: msg.Question[0].Name, Rrtype: dns.TypeA, Class: dns.ClassINET, Ttl: plugin.fallbackTTL}
			rr.A = parsedIP
			synth.Answer = append(synth.Answer, rr)

		} else {
			rr := new(dns.CNAME)
			rr.Hdr = dns.RR_Header{Name: msg.Question[0].Name, Rrtype: dns.TypeCNAME, Class: dns.ClassINET, Ttl: plugin.fallbackTTL}
			rr.Target = dns.Fqdn(fallback)
			synth.Answer = append(synth.Answer, rr)
		}

		respMsg = synth
	}

	respMsg.Id = msg.Id
	pluginsState.synthResponse = respMsg
	pluginsState.action = PluginsActionSynth
	pluginsState.returnCode = PluginsReturnCodeForward
	return nil
}
