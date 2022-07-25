Kubernetes Network Test
=======================

This is two http applications designed to prove whether networking is
possible between kubernetes worker nodes. We made it because at one
point after an upgrade the network appeared to be not always working,
but we didn't really have a good way to run diagnostics, and we never
figured out exactly what was going on.

With this tool, we'll be able to have 100% confidence that containers on
one node are able (or are not able) to talk to containers on other
nodes. Here's a diagram:

![A prometheus server scrapes 3 monitors which each check 3 indicators,
  resulting in 9 total checks, where monitors check on indicators.][1]

[1]: ./monitors_and_indicators.png

Prometheus is itself out of scope; the monitors should be able to export
metrics that prometheus understands; and the indicators should be
accessible by the monitors so that the monitors can verify working
network connectivity.
