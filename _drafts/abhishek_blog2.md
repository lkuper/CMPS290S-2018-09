---
title: "Conflict resolution in collaborative text editing with operational transformation (Part 2 of 2)"
author: Abhishek Singh
layout: single
classes: wide
---

by Abhishek Singh


## Introduction

In this post we continue our discussion on collaborative text editors. The goal of part 1 of the post was to provide an overview of the problems encountered in collaborative text editing. We looked at the problem of consistency through a narrow set of assumptions. In this post we remove some of those assumptions to arrive at a more generalized solution to the problem of maintaining  consistency in a collaborative text editor.

Here's a list of the assumptions:
>  1. Operation messages from either sites are received exactly once.
>  2. There are exactly two editors in the system: one at Alice's end and the other at Bob's end.
>  3. My implementation does not use clocks to timestamp operations, so the _happens before_ relationship is established based on message delivery. It is assumed that LOCAL and REMOTE operations happen concurrently.
>  4. Operations are processed in the order in which they are seen and executed at a particular site. In our implementation the executed operations are stored in a list `OTEditor.Ops`.
>  5. Unlike the implementation in the [paper](http://doi.acm.org/10.1145/67544.66963), we do not assign priorities to an operation. Every operation has equal priority.
>  6. An operation is sent to others immediately after it was executed at one particular site. There is no out-of-order delivery of messages.

Let's understand what would happen when these assumptions are removed. 
