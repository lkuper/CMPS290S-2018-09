# Readings

_This page is a draft and subject to change._

This page is neither sound (i.e., if it's listed here, that doesn't mean we'll read it) nor complete (i.e., if it's *not* listed here, that doesn't mean we *won't* read it).  So, don't read too much into what's listed here or how it's categorized.  I'm making it all up as I go along, y'all.

| Date             | Topic                                        | Presenter            | Reading
|------------------|----------------------------------------------|----------------------|-----------------------------------------------------
| Friday, 9/28     | Overview and introduction                    | Lindsey              | (none)
| Monday, 10/1     | The CAP theorem                              |                      | [Brewer's Conjecture and the Feasibility of Consistent, Available, Partition-Tolerant Web Services (2002)](http://www.comp.nus.edu.sg/~gilbert/pubs/BrewersConjecture-SigAct.pdf)
| Wednesday, 10/3  | CAP redux                                    |                      | [CAP Twelve Years Later: How the "Rules" Have Changed (IEEE Computer, 2012)](https://www.infoq.com/articles/cap-twelve-years-later-how-the-rules-have-changed)
| Friday, 10/5     | Consistency models: Linearizability          |                      | [Linearizability: A Correctness Condition for Concurrent Objects (TOPLAS 1990)](http://cs.brown.edu/~mph/HerlihyW90/p463-herlihy.pdf)
| Monday, 10/8     | Consistency models: Causal consistency       |                      | [Causal memory: definitions, implementation, and programming (Distributed Computing, 1995)](https://link.springer.com/article/10.1007/BF01784241)
| Wednesday, 10/10 | Consistency models: Causal consistency       |                      | [Time, Clocks, and the Ordering of Events in a Distributed System (1978)](https://lamport.azurewebsites.net/pubs/time-clocks.pdf)
| Friday, 10/12    | Consistency models: Sequential consistency   |                      | [How to Make a Multiprocessor Computer That Correctly Executes Multiprocess Programs (1979)](https://www.microsoft.com/en-us/research/publication/make-multiprocessor-computer-correctly-executes-multiprocess-programs/)
| Monday, 10/15    | Consistency models: Serializability          |                      | [Principles of Transaction-Oriented Database Recovery (ACM Computing Surveys, 1983)](https://dl.acm.org/citation.cfm?id=291)
| Wednesday, 10/17 | Consistency models: Eventual consistency     |                      | [Eventually consistent (CACM 2009)](https://dl.acm.org/citation.cfm?id=1435432)
| Friday, 10/19    | Consistency models: surveys and overviews    |                      | [Consistency, Availability, and Convergence (2011)](http://www.cs.cornell.edu/lorenzo/papers/cac-tr.pdf)
| Monday, 10/22    | Consistency models: surveys and overviews    |                      | [Consistency in Non-Transactional Distributed Storage Systems (ACM Computing Surveys, 2016)](https://dl.acm.org/citation.cfm?id=2926965) (see also: [author's version](http://www.vukolic.com/consistency-survey.pdf); [verson on arXiv](https://arxiv.org/abs/1512.00168); cf. [the Jepsen overview of consistency models](https://jepsen.io/consistency))
| Wednesday, 10/24 | Consistency models: "causal+" consistency    |                      | [Don't Settle for Eventual: Scalable Causal Consistency for Wide-Area Storage with COPS (SOSP '11)](https://www.cs.cmu.edu/~dga/papers/cops-sosp2011.pdf)
| Friday, 10/26    | Replicated data types: CRDTs                 |                      | [Conflict-Free Replicated Data Types (2011)](https://hal.inria.fr/inria-00609399/document)
| Monday, 10/29    | Replicated data types: CRDTs                 |                      | [A comprehensive study of Convergent and Commutative Replicated Data Types (2011)](https://hal.inria.fr/inria-00555588/document)
| Wednesday, 10/31 | Replicated data types: Cloud types           |                      | [Cloud Types for Eventual Consistency (ECOOP '12)](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/CloudTypes-ECOOP12.pdf) (see also: Burckhardt's book, [_Principles of Eventual Consistency_](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/final-printversion-10-5-14.pdf))
| Friday, 11/2     | Mixed consistency: a systems perspective     |                      | [Consistency-based service level agreements for cloud storage (SOSP '13)](https://www.microsoft.com/en-us/research/publication/consistency-based-service-level-agreements-for-cloud-storage/)
| Monday, 10/29    | Mixed consistency: a PL perspective          |                      | ['Cause I'm Strong Enough: Reasoning About Consistency Choices in Distributed Systems (POPL '16)](http://software.imdea.org/~gotsman/papers/logic-popl16.pdf)
| Wednesday, 10/31 | Mixed consistency: another PL perspective    |                      | [MixT: a Language for Mixing Consistency in Geodistributed Transactions (PLDI '18)](http://www.cs.cornell.edu/andru/papers/mixt/mixt.pdf)
| Friday, 11/2     | Verifying consistency                        |                      | [Chapar: Certified Causally Consistent Distributed Key-Value Stores (POPL '16)](http://www.cs.ucr.edu/~lesani/companion/popl16/POPL16.pdf)
| Monday, 11/5     | Languages and frameworks for distribution    |                      | [Consistency Analysis in Bloom: a CALM and Collected Approach (CIDR '11)](http://db.cs.berkeley.edu/papers/cidr11-bloom.pdf)
| Wednesday, 11/7  | Languages and frameworks for distribution    |                      | [Logic and Lattices for Distributed Programming (SOCC '15)](https://dl.acm.org/citation.cfm?id=2391230)
| Friday, 11/9     | Languages and frameworks for distribution    |                      | [From Clarity to Efficiency for Distributed Algorithms (OOPSLA '12)](http://www3.cs.stonybrook.edu/~liu/papers/DistPL-OOPSLA12.pdf)
| Monday, 11/12    | No class (Veterans Day)
| Wednesday, 11/14 | Languages and frameworks for distribution    |                      | [PSync: A partially synchronous language for fault-tolerant distributed algorithms (POPL '16)](https://hal.inria.fr/hal-01251199/document)
                                                                                           (see also: [the extended TOPLAS version](https://arxiv.org/pdf/1412.8461.pdf); [the DistAlgo website](https://sites.google.com/site/distalgo/))
| Friday, 11/16    | Multitier programming                        |                      | [Links: web programming without tiers (FMCO '06)](http://links-lang.org/papers/links-fmco06.pdf)
| Monday, 11/19    | Multitier programming                        |                      | [Distributed System Development with ScalaLoci (OOPSLA '18)](https://2018.splashcon.org/event/splash-2018-oopsla-distributed-system-development-with-scalaloci) (TODO: update with correct paper link) (see also: [ScalaLoci website](https://scala-loci.github.io/) and [GitHub organization](https://github.com/scala-loci))
| Wednesday, 11/21 | Languages and frameworks for distribution    |                      | [Orleans: Cloud Computing for Everyone (SOCC '11)](https://www.microsoft.com/en-us/research/wp-content/uploads/2011/10/socc125-print.pdf)
| Friday, 11/23    | No class (Thanksgiving)
| Monday, 11/26    | Languages and frameworks for distribution    |                      | [P: Safe Asynchronous Event-Driven Programming (PLDI '13)](https://dl.acm.org/citation.cfm?id=2462184) (see also: [P on GitHub](https://github.com/p-org/P))
| Wednesday, 11/28 | Languages and frameworks for distribution    |                      | [Compositional Programming and Testing of Dynamic Distributed Systems (OOPSLA '18)](https://2018.splashcon.org/event/splash-2018-oopsla-compositional-programming-and-testing-of-dynamic-distributed-systems) (TODO: update with correct paper link)
| Friday, 11/30    | Abstractions for configuration management    |                      | [Modular Software Upgrades for Distributed Systems (ECOOP '06)](http://pmg.csail.mit.edu/pubs/ajmani06modular-abstract.html)
| Monday, 12/3     | Abstractions for configuration management    |                      | [Abstractions for Network Update (SIGCOMM '12)](http://reitblatt.com/papers/consistent-updates-sigcomm12.pdf)
| Wednesday, 12/5  | Abstractions for configuration management    |                      | [Rehearsal: A Configuration Verification Tool for Puppet (PLDI '16)](https://people.cs.umass.edu/~arjun/papers/2016-rehearsal.html)
| Friday, 12/7     | Abstractions for configuration management    |                      | [Tortoise: Interactive System Configuration Repair (ASE '17)](https://people.cs.umass.edu/~arjun/papers/2017-weiss-tortoise.html)
| Wednesday, 12/12 | ~~final exam~~ end-of-quarter celebration

## Further reading

There's a vast amount of stuff that wouldn't be at all out of place in a course on "languages and abstractions for distributed programming", but that this particular course won't have time to cover, including but not limited to:

  - ...material on _process calculi_, such as:
    - [A Calculus of Mobile Agents (CONCUR '96)](https://dl.acm.org/citation.cfm?id=703841)
    - [Mobile Ambients (FoSSaCS '98)](http://lucacardelli.name/Papers/MobileAmbientsETAPS98.A4.pdf)
  - ...material on _early or pioneering distributed languages_, such as:
    - [Distribution and Abstract Types in Emerald (IEEE TSE 1987)](http://web.cecs.pdx.edu/~black/publications/Emerald%20IEEE%20TSE.pdf)
    - [Distributed Programming in Argus (CACM 1988)](https://dl.acm.org/citation.cfm?id=42399)
    - [A Language with Distributed Scope (POPL '95)](http://lucacardelli.name/Papers/Obliq.pdf)
    - [Erlang (CACM 2010)](https://cacm.acm.org/magazines/2010/9/98014-erlang/fulltext)
    - [Alice Through the Looking Glass (TFP '04)](https://people.mpi-sws.org/~rossberg/papers/Rossberg,%20Le%20Botlan,%20Tack,%20Brunklaus,%20Smolka%20-%20Alice%20Through%20the%20Looking%20Glass.pdf) (see also: [the Alice ML website](https://www.ps.uni-saarland.de/alice/))
  - ...material on _extending languages for distribution_, such as:
    - [Towards Haskell in the Cloud (Haskell '11)](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/07/remote.pdf) (see also: [the Cloud Haskell website](http://haskell-distributed.github.io/))
  - ...material on _Dryad, Naiad, and all that_, such as:
    - [DryadLINQ: A System for General-Purpose Distributed Data-Parallel Computing Using a High-Level Language (OSDI '08)](https://www.usenix.org/legacy/events/osdi08/tech/full_papers/yu_y/yu_y.pdf)
    - [Naiad: A Timely Dataflow System (SOSP '13)](http://sigops.org/sosp/sosp13/papers/p439-murray.pdf)
  - ...(more) material on _verifying distributed systems_, such as:
    - [Verdi: A Framework for Implementing and Formally Verifying Distributed Systems (PLDI '15)](http://verdi.uwplse.org/verdi.pdf) (see also: [the Verdi website](http://verdi.uwplse.org/))
  - ...material on _computation orchestration_, such as:
    - [Computation Orchestration: A Basis for Wide-Area Computing (JSSM 2007)](http://orc.csres.utexas.edu/papers/OrcJSSM.pdf)
    - [The Orc Programming Language (FORTE '09)](http://orc.csres.utexas.edu/papers/forte09.pdf)
  - ...material on _modal logic as a basis for distributed computing_, such as:
    - [Using Reasoning About Knowledge to Analyze Distributed Systems (1987)](https://www.cs.cornell.edu/home/halpern/papers/UsingRAK.pdf)
    - [Modal Proofs as Distributed Programs (ESOP '04)](http://sip.cs.princeton.edu/pub/modal-esop04.pdf)
    - [Type-Safe Distributed Programming in ML5 (TGC '07)](http://www.cs.cmu.edu/~tom7/papers/ml5_tgc2007_preproceedings.pdf) (see also: Murphy's dissertation, [_Modal Types for Mobile Code_](http://www.cs.cmu.edu/~tom7/papers/modal-types-for-mobile-code.pdf))
  - Etc., etc., etc.
