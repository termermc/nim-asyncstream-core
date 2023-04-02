## Dummy implementations of async read/write streams

import std/[asyncdispatch, options]
import ".."/[asyncstream_core]

type DummyAsyncReadStream* = ref object
  intIsFinished: bool

proc read(this: DummyAsyncReadStream): Future[ReadResult[string]]
  ##

proc read[T](this: DummyAsyncReadStream, count: int): Future[ReadResult[seq[string]]]
  ##

proc readAll[T](this: DummyAsyncReadStream): Future[ReadResult[seq[string]]]
  ##

func isFinished*[T](this: DummyAsyncReadStream): bool
  ##

func isFailed*[T](this: DummyAsyncReadStream): bool
  ## 

func canRead*[T](this: DummyAsyncReadStream): bool
  ## 

func exception*[T](this: DummyAsyncReadStream): Option[Exception]
  ## The exception that caused the stream to fail, or None if the stream did not fail.
  ## Must be Some if isFailed is true.

DummyAsyncReadStream.implements(AsyncReadStream[string])
