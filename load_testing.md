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

It can run a specified number of concurrent calls, ramping up numbers, up to a maximum number of calls, and many other uses. SIPp is *not*, however, suited for functional testing as the action set is quite limited compared to what could be achieved with something like [ahn-loadbot](https://github.com/mojolingo/ahn-loadbot).

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

```-sf``` passes the scenario file to run. ```-l``` is the concurrent call limit, which means the calls that are running at the same time, and they will be added as the scenario progresses up to ```-m```, which is the total number of calls that will be run, at a rate per second of ```-r``` calls.

```-s``` is the service part of the target SIP uri, such as 123 in ```123@host.com```. The host part is simply the main argument for the command.

## SIPp scenarios

A scenario is an XML file containing the steps for the call to be run. Steps mainly consist of ```<send>```ing SIP packets, setting a ```<recv>``` expectation on the counterpart sending a specified SIP command, plus some other tags that can be used to execute actions and to pause the scenario.

The scenario will then be run sequentially, and SIPp will display the various steps, number of successful completions and failures for each, plus some other information. It is important to note that SIPp will consider anything that is not exactly happening as specified as an error.

SIPp comes with a number of [built-in scenarios](http://sipp.sourceforge.net/doc/reference.html#Integrated+scenarios), but you will probably want to [build your own](http://sipp.sourceforge.net/doc/reference.html#xmlsyntax).

To start looking at a scenario, a good way is to use the ```-sd``` option to dump a built-in scenario, either to console or to a file. For example ```sipp -sd uac_pcap >> integrated_uac_pcap_scenario.xml``` will write out the client scenario with PCAP, which is the common starting point for most usage we will be exploring in this post. The result for that command can be seen [here](https://github.com/polysics/sipp_blog_post/blob/master/scenarios/integrated_uac_pcap_scenario.xml).

The scenario starts with an INVITE expecting an optional 100 TRYING and/or 180 RINGING, followed by a mandatory 200 OK. After ACKing the response, the scenario plays some PCAP file, then pauses for the duration of the recording. This is necessary because playback is a sort of an "async" action here, and execution would continue before the RTP replay is done. We then see the scenario send a DTMF digit, some more pausing, and a BYE signaling the end of the call. A final 200 OK is expected in response to the BYE.

As you can see, this scenario could easily be used to test an IVR. I have copied the relevant PCAP files to the [blog post repository](https://github.com/polysics/sipp_blog_post).

You might be asking yourself now, what is a PCAP file? Why cannot you just use your own .wav files?

## PCAP explained

SIPp does not understand audio in the way some other more high-level software does. It only speaks two protocols: SIP and RTP. The only way to have SIPp send audio is thus to replay a recorded packet capture of an RTP stream. That entails a series of difficulties, both at the capture and at the playback stage.

To record an RTP PCAP stream, the recommended tool is [Wireshark](http://www.wireshark.org/). Run a capture during a SIP call, generating the needed audio on one of the call sides. Then, using ```ip.src == SRC_IP_ADDRESS and ip.dst == DST_IP_ADDRESS and rtp```, isolate the packets you want to save. Using File/Save and the Displayed filter, you can then create your .pcap file.

Playback of PCAP files has to adhere to the RTP protocol rules. Since your packets have a Sequence and a Timestamp, they will only be accepted the first time they are played in a scenario, then silently discarded. The patch mentioned above in the installation steps gets around this by rewriting the Sequence number and updating the Timestamp for packets before they are sent.

SIPp bundles a variety of PCAP files in the ```pcap/``` directory in the source, some of which I have put in the repository ```scenarios/pcap``` folder.

## A more complex scenario

To explain things further, I will be building a sample Adhearsion application I will then be load testing using SIPp. You can find the app in the ```ahn_app```folder in the repository.
It is a very simple app that plays a sample Asterisk file, then asks for input and logs the result.
The corresponding [scenario file](https://github.com/polysics/sipp_blog_post/blob/master/scenarios/ahn_app_scenario.xml) is very similar to the one we generated earlier. I only removed the first PCAP play and shortened the initial pause.

To run a scenario against Asterisk without using authentication, which is not at all easy to do with SIPp and not in scope for this post, you will want your ```sip.conf``` to contain ```allowguest=yes```, using this only for testing as it allows your Asterisk server to accept calls from non-authenticated parties, and ```allow=alaw``` to allow the codec we are using in the scenario. You will also need your default context sending calls to Adhearsion in ```extensions.conf```.

After setting up and running the Adhearsion application ```cd scenarios``` then ```sudo sipp -i 192.168.10.1 -p 8832 -sf ahn_app_scenario.xml -l 1 -m 1 -r 1 -s 111 192.168.10.11```. If everything works. you can then start raising limits and seeing how high you can go before your box starts having issues.

## Interpreting SIPp results

SIPp is a very strict testing tool, and as such it only accepts call flows that are exactly as specified. For example, if you have a pause in your scenario, nothing should be received from the far side during that. The above scenario thus often results in false failed calls because the BYE comes in before the paus is done, unless you sleep for 1 second after logging output.

In this case we decided to act on the application since we had access, but you might want to tweak the scenario instead.

The same principle goes for *any* SIP packet or interaction. SIPp is not a "call simulator" like a developer would think at a glance, and a scenario is not the same thing as simply picking up a softphone and dialing an extension, pressing DTMF as you go.

Your first step in developing your own scenario is thus testing it over and over to make sure you do not have any fake failures. That said, if your *only* goal is load testing and you have access to the server side, you can some times just run the load tests anyway and spot issues from the logs. That is not, however, a recommended approach as your statistics will report many false positive failures.

## SIPp statistics

If you try running the above scenario with ```sudo sipp -i 192.168.10.1 -p 8832 -sf ahn_app_scenario.xml -l 5 -m 50 -r 2 -s 111 192.168.10.11 -trace_stat -fd 2``` you will notice a new ```.csv``` file appears in the working directory. That file contains the statistics collected during the test, with the ```-trace_stat``` option enabling them and ```-fd``` setting an interval in seconds between writes. I have 

## What to look for when doing load testing
## Other tools
