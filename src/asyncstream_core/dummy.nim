## Dummy implementations of async read/write streams

import std/[asyncdispatch, options]
import ".."/[asyncstream_core]

type DummyAsyncReadStream*[T] = ref object
  intIsFinished: bool

proc read[T](this: DummyAsyncReadStream[T]): Future[ReadResult[T]]
  ##

proc read[T](this: DummyAsyncReadStream[T], count: int): Future[ReadResult[seq[T]]]
  ##

proc readAll[T](this: DummyAsyncReadStream[T]): Future[ReadResult[seq[T]]]
  ##

proc pipeTo[T](this: DummyAsyncReadStream[T], writeStream: AsyncWriteStream[T]): Future[PipeResult]
  ##

func isFinished*[T](this: DummyAsyncReadStream[T]): bool
  ##

func isFailed*[T](this: DummyAsyncReadStream[T]): bool
  ## 

func canRead*[T](this: DummyAsyncReadStream[T]): bool
  ## 

func exception*[T](this: DummyAsyncReadStream[T]): Option[Exception]
  ## The exception that caused the stream to fail, or None if the stream did not fail.
  ## Must be Some if isFailed is true.

DummyAsyncReadStream.implements(AsyncReadStream)
