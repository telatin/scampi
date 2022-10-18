---
title: Scaffolding
layout: post
categories: [scampi, scaffolding]
image: /scampi-1.16/images/image1.png
description: "Some flash ideas on how to scaffold a genome"
customexcerpt: "Some infos on scaffolding"
---


## Mate pairs

Long mate paired libraries allow the sequencing of the two ends of a large insert. 
*Nannochloropsis gaditana* was sequenced with SOLiD Mate Paired libraries, one with average insert size of 2kbp, the other with an average insert size of 5kbp.

Mapping the mate pairs allows to:

* Verify the correctness of contigs, when both pairs map within the same contig
* Connect contigs, when both pairs map to different contigs

### Correctness

[![Physical coverage of a contig]({{site.baseurl}}/scampi-1.16/images/image9.png)](https://telatin.github.io/scampi/)

The contig in the picture is shown with the *physical coverage* of mate paired libraries. The break in 
the coverage is due to the fact that the contig is a mis-assembly.

### Physical coverage

[![Phy cov]({{site.baseurl}}/scampi-1.16/images/image8.png)](https://telatin.github.io/scampi/)

The physical coverage is the number of time a sequence is covered by the two pairs, *and* the
space between the two pairs.

### Scaffolding

[![Mate pairs]({{site.baseurl}}/scampi-1.16/images/image16.png)](https://telatin.github.io/scampi/)

The mate paired reads connecting two contigs are shown in the picture. It's important to check that
the two pairs are mapped in the correct orientation and a reasonable distance. Below we depict a single
mate paired pair, with the orientation of SOLiD and Illumina libraries:

[![Illumina vs Solid library]({{site.baseurl}}/scampi-1.16/images/image3.png)](https://telatin.github.io/scampi/)


### Result

[![A whole scaffold]({{site.baseurl}}/scampi-1.16/images/image1.png)](https://telatin.github.io/scampi/)

The whole scaffolding is a set of contigs placed in the correct reciprocal orientation.
