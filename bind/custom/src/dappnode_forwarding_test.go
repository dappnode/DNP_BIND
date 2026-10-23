package main

import (
	"net"
	"strings"
	"testing"
	"time"

	"codeberg.org/miekg/dns"
)

func TestDappnodeForwardingRules(t *testing.T) {
	plugin := &PluginForward{}
	_, rules, err := plugin.parseForwardFile("dappnode 127.0.0.11\ndappnode.private 127.0.0.11\neth 127.0.0.11 my.dappnode\n")
	if err != nil {
		t.Fatal(err)
	}
	if len(rules) != 3 || rules[0].fallback != "" || rules[2].fallback != "my.dappnode" {
		t.Fatalf("unexpected forwarding rules: %+v", rules)
	}
	if rules[2].sequence[0].servers[0] != "127.0.0.11:53" {
		t.Fatalf("unexpected resolver: %+v", rules[2])
	}

	// The fallback extension must retain upstream resolver sequence support.
	plugin.bootstrapResolvers = []string{"1.1.1.1:53"}
	_, rules, err = plugin.parseForwardFile("*.eth [::1]:5353,$BOOTSTRAP my.dappnode")
	if err != nil || len(rules) != 1 || len(rules[0].sequence) != 2 || rules[0].fallback != "my.dappnode" {
		t.Fatalf("resolver sequence: %+v, %v", rules, err)
	}
	if _, _, err := plugin.parseForwardFile("bad*domain 127.0.0.11 my.dappnode"); err == nil {
		t.Fatal("wildcards inside a domain must still be rejected")
	}
	_, rules, err = plugin.parseForwardFile("eth 127.0.0.11, 1.1.1.1")
	if err != nil || len(rules) != 1 || rules[0].fallback != "" || len(rules[0].sequence[0].servers) != 2 {
		t.Fatalf("spaced resolver list: %+v, %v", rules, err)
	}
}

func TestDappnodeFallbackTTL(t *testing.T) {
	config := newConfig()
	if config.ForwardFallbackTTL != 600 {
		t.Fatalf("default fallback TTL = %d", config.ForwardFallbackTTL)
	}
	config.ForwardFallbackTTL = 123
	proxy := &Proxy{}
	configurePlugins(proxy, &config)
	if proxy.forwardFallbackTTL != 123 {
		t.Fatalf("configured fallback TTL = %d", proxy.forwardFallbackTTL)
	}
}

func TestDappnodeForwardingResponses(t *testing.T) {
	for _, tc := range []struct {
		name     string
		rcode    uint16
		fallback string
		want     string
	}{
		{"successful answer", dns.RcodeSuccess, "my.dappnode", "192.0.2.1"},
		{"unknown ENS name", dns.RcodeNameError, "my.dappnode", "my.dappnode."},
		{"resolver failure", dns.RcodeServerFailure, "my.dappnode", "my.dappnode."},
		{"refused query", dns.RcodeRefused, "my.dappnode", "my.dappnode."},
		{"IP fallback", dns.RcodeNameError, "192.0.2.2", "192.0.2.2"},
		{"no fallback", dns.RcodeNameError, "", ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			conn, err := net.ListenPacket("udp", "127.0.0.1:0")
			if err != nil {
				t.Fatal(err)
			}
			t.Cleanup(func() { conn.Close() })
			go func() {
				buffer := make([]byte, 4096)
				n, addr, err := conn.ReadFrom(buffer)
				if err != nil {
					return
				}
				query := &dns.Msg{Data: buffer[:n]}
				if query.Unpack() != nil {
					return
				}
				response := EmptyResponseFromMessage(query)
				response.Rcode = tc.rcode
				if tc.rcode == dns.RcodeSuccess {
					rr, err := dns.New("example.eth. 60 IN A 192.0.2.1")
					if err != nil {
						return
					}
					response.Answer = []dns.RR{rr}
				}
				if response.Pack() == nil {
					conn.WriteTo(response.Data, addr)
				}
			}()

			plugin := &PluginForward{fallbackTTL: 123}
			_, rules, err := plugin.parseForwardFile("eth " + conn.LocalAddr().String() + " " + tc.fallback)
			if err != nil {
				t.Fatal(err)
			}
			plugin.forwardMap = rules
			query := dns.NewMsg("example.eth.", dns.TypeA)
			state := &PluginsState{qName: "example.eth", timeout: time.Second}
			if err := plugin.Eval(state, query); err != nil {
				t.Fatal(err)
			}
			response := state.synthResponse
			if response == nil || response.ID != query.ID || state.returnCode != PluginsReturnCodeForward {
				t.Fatalf("unexpected response state: %+v", state)
			}
			if tc.want == "" {
				if response.Rcode != tc.rcode || len(response.Answer) != 0 {
					t.Fatalf("negative response changed: %v", response)
				}
				return
			}
			if response.Rcode != dns.RcodeSuccess || len(response.Answer) != 1 || !strings.HasSuffix(response.Answer[0].String(), tc.want) {
				t.Fatalf("unexpected answer: %v", response)
			}
			if tc.rcode != dns.RcodeSuccess && (response.Answer[0].Header().TTL != 123 || response.AuthenticatedData) {
				t.Fatalf("incorrect fallback TTL or DNSSEC flag: %v", response)
			}
		})
	}
}

func TestDappnodeForwardingTransportFailure(t *testing.T) {
	plugin := &PluginForward{
		fallbackTTL: 600,
		forwardMap: []PluginForwardEntry{{
			domain: "eth", fallback: "my.dappnode",
			sequence: []SearchSequenceItem{{typ: Explicit, servers: []string{"127.0.0.1:0"}}},
		}},
	}
	query := dns.NewMsg("example.eth.", dns.TypeA)
	state := &PluginsState{qName: "example.eth", timeout: 50 * time.Millisecond}
	if err := plugin.Eval(state, query); err != nil {
		t.Fatal(err)
	}
	if state.synthResponse == nil || len(state.synthResponse.Answer) != 1 {
		t.Fatalf("missing transport failure fallback: %+v", state)
	}
}
