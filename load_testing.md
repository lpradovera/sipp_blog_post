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

In short, SIPp can simulate one or more calls to your system in an automated fashion by leveraging SIP and RTP protocols, testing the SIP dialogs and generating statistics.

It can run a specified number of concurrent calls, ramping up numbers, a

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

Note that there is no ```make install``` step, you might want to copy or link the ```sipp``` executable to your preferred location.

## The SIPp command line

There are quite a few [command line options](http://sipp.sourceforge.net/doc/reference.html#Online+help+%28-h%29) available for SIPp. We will be explanining a sample command line to get acquainted with what SIPp can do for us.

```
sudo sipp -i 127.0.0.1 -p 8832 -sf load-test-1-simple.xml -l 5 -m 100 -r 2 -s 1 127.0.0.1
```

First of all, ```sipp``` is usually run using ```sudo```, at least on OSX, because it needs to bind to low ports.

```-i``` specifies the local IP to bind to in case you have more than one. Always specify the IP to avoid difficult to diagnose issues. ```-p``` is the binding port.

```-sf``` passes the scenario file to run, which is the XML file containing the steps for the call to be run. ```-l``` is the concurrent call limit, which means the calls that are running at the same time, and they will be added as the scenario progresses up to ```-m```, which is the total number of calls that will be run, at a rate per second of ```-r``` calls.

```-s``` is the service part of the target SIP uri, such as 123 in ```123@host.com```. The host part is simply the main argument for the command.

## Your first scenario

SIPp comes with a number of [built-in scenarios](http://sipp.sourceforge.net/doc/reference.html#Integrated+scenarios), but you will probably want to build your own

## PCAP explained
## A more complex scenario
## SIPp statistics at a glance
## What to look for when doing load testing
## Other tools
