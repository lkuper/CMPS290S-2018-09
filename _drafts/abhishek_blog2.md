---
title: "Conflict resolution in collaborative text editing with operational transformation (Part 2 of 2)"
author: Abhishek Singh
layout: single
classes: wide
---

by Abhishek Singh


## Introduction

In this post we continue our discussion on collaborative text editors. The goal of [part 1](http://composition.al/CMPS290S-2018-09/2018/11/20/conflict-resolution-in-collaborative-text-editing-with-operational-transformation-part-1-of-2.html) of the post was to provide an overview of the problems encountered in collaborative text editing. We looked at the problem of consistency through a narrow set of assumptions. In this post we remove some of those assumptions to arrive at a more generalized solution to the problem of maintaining  consistency in a collaborative text editor.

Here's a list of the assumptions:
>  1. Operation messages from either sites are received exactly once.
>  2. There are exactly two editors in the system: one at Alice's end and the other at Bob's end.
>  3. My implementation does not use clocks to timestamp operations, so the _happens before_ relationship is established based on message delivery. It is assumed that LOCAL and REMOTE operations happen concurrently.
>  4. Operations are processed in the order in which they are seen and executed at a particular site. In our implementation the executed operations are stored in a list `OTEditor.Ops`.
>  5. Unlike the implementation in the [paper](http://doi.acm.org/10.1145/67544.66963), we do not assign priorities to an operation. Every operation has equal priority.
>  6. An operation is sent to others immediately after it was executed at one particular site. There is no out-of-order delivery of messages.


<figure>
  <img src="test_operations.png" height="600" width="450" />
  <figcaption>Figure 1. Operations received by Alice and Bob are transformed before being applied to local data.</figcaption>
</figure> 


Let's understand what would happen when some of these assumptions are removed from our original design. Primarily, there is a problem of ascertaining [causality](https://en.wikipedia.org/wiki/Causality) of messages in the design. Consider the second and third operations exchanged between Alice and Bob in Figure 1. There is no way for Alice to know if the third operation (INSERT ("x", 2)) sent by Bob happened before or after Bob received the second operation from Alice (INSERT("y", 0)). That's because we ignored causality in the last blog post. This is a major problem. Even with only two users in the system, there is enough uncertainty in the system when we don't consider the history of how changes happened in the system. This is just one of the problems I wish to address in this post.

The text editor in the first post consisted of only 2 users Alice and Bob. It was designed with only 2 users in mind. It is easy to understand how operation messages are exchanged when only two users exist in the system. With increase in the number of users in the system, the number of messages needed to share changes with other users grows linearly. Since each user has a replica of the document state, each change in the document state must be informed to the other users. If there are `n` users in the system, every state change at one user must be communicated with `n-1` users. With each user making changes to their document state the design of the two-user collaborative text editor developed in the last post cannot be used as there was no notion to find out the exact state on which the operation was executed.

The problem of receiving out-of-order messages or duplicate messages is another issue in the design. If the same message is received multiple times we will not be able to differentiate between duplicates or out of order messages and would execute the operation on the replica. This would aggravate the problem of data inconsistency among the users. However, this is one assumption, we will maintain for the remainder of this post. We will look at some ways to deal with this problem at the end of the post.


### State management

The essence of the problem from one user's perspective is that we cannot trace the history of how a particular change was made and how it relates to that particular user's local replica history. This is the main problem. There are some solutions to this problem. The "easiest" one is to send a complete historical record of the operations on a replica with the new operation message. This is never a good option as it is a clear sign of state explosion. We will look at solutions which do not lead to state explosion. 

