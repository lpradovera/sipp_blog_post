# Load Testing with SIPp

## What is load testing?

The development of a voice application ideally involves many testing steps. Unit, functional and integration tests give a developer a good degree of confidence about the application internals.

But what about the platform as a whole?

Telephony involves a larger number of moving parts compared to a web application, often requiring more server-side resources per user in addition to the usual persistence and logic layers. That complexity creates a series of scaling challenges, where a single machine often serves a number of concurrent calls that is in the low hundreds.

Since a telephony platform such as FreeSWITCH could be installed on any kind of machine from a P4 to a 32-core virtualized setup, it is necessary for a voice application nearing the production stage to generate concrete statistics about resource needs and usage.

You do not want to find out that your new business idea is so successful your platform melts under pressure!

## SIPp

Enter [SIPp](http://sipp.sourceforge.net/), the testing tool of choice. SIPp can be used not only for load testing, which will be our primary focus, but also to exercise a SIP implementation for compliance and compatibility purposes.

From the SIPp documentation:

> SIPp is a performance testing tool for the SIP protocol. It includes a few basic SipStone user agent scenarios (UAC and UAS) and establishes and releases multiple calls with the INVITE and BYE methods. It can also reads XML scenario files describing any performance testing configuration. It features the dynamic display of statistics about running tests (call rate, round trip delay, and message statistics), periodic CSV statistics dumps, TCP and UDP over multiple sockets or multiplexed with retransmission management, regular expressions and variables in scenario files, and dynamically adjustable call rates.

> SIPp can be used to test many real SIP equipements like SIP proxies, B2BUAs, SIP media servers, SIP/x gateways, SIP PBX, ... It is also very useful to emulate thousands of user agents calling your SIP system.

## Installing SIPp

SIPp comes with a few compile-time options to enable various functionalities. For our purposes, we will be compiling SIPp from the stable download, using a patch to enable dynamic PCAP play (more on what that means later!).

The [installation instructions](http://sipp.sourceforge.net/doc/reference.html#Stable+release) are pretty straightforward. but we will be adding a patch originated on [this mailing list post](http://permalink.gmane.org/gmane.comp.telephony.sipp.user/5751). Unfortunately the patch is no longer available but I have built a small repository for it [here](https://github.com/polysics/sipp_dynamic_pcapp_play).

For stable, first download the [latest version](http://sourceforge.net/projects/sipp/files/latest/download?source=files), then:

```
tar -xvzf sipp-xxx.tar.gz
cd sipp-xxx
patch -p1 -i /path/to/sipp_support_dynamic_pcap_play.diff
autoreconf -ivf
./configure --with-pcap
make
```

On OSX there are no prerequisites other than the usual build chain. On Linux, you might want to refer to your distribution's documentation, but libpcap and libncurses will be needed.

Note that there is no ```make install``` step, you might want to

## Your first scenario
## PCAP explained
## A more complex scenario
## SIPp statistics at a glance
## What to look for when doing load testing
## Other tools
