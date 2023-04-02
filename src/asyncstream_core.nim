## # Unified asynchronous stream interface in Nim
## This module provides common types and concepts for asynchronous read and write streams in Nim.
## This module only implements very simple primitive stream types for reference and basic usage.
## 
## `AsyncReadStream` and `AsyncWriteStream` are designed to support real-world conditions, such as differences in read and write speeds and cases where internal buffers are filled and need to be waited on before writing again. 
## 
## To force the compiler to 

import std/[asyncfutures, options]

template implements*(typeA: typedesc, typeB: typedesc) =
  ## Convenience template to check if a type implements another type by causing a fatal error.
  ## You can put it after your type definition to ensure that your type implements another.
  ## 
  ## Example:
  ## ```
  ## MyAsyncReadStream.implements(AsyncReadStream[string])
  ## ```

  when typeA isnot typeB:
    {.fatal: $typeA & " does not implement " & $typeB.}

type ReadResultKind* {.pure.} = enum
  Data
    ## A data result

  Finished
    ## A finished result.
    ## The stream has finished, and there is no additional data to read.

  Error
    ## Reading from the stream failed.
    ## No additional data can be read past this point.

type ReadResult*[T] = object
  case kind*: ReadResultKind
    ## The result kind

  of ReadResultKind.Data:
    data*: T
      ## The data
  
  of ReadResultKind.Finished:
    ## The stream is finished; no additional properties
  
  of ReadResultKind.Error:
    exception*: Exception
      ## The exception that caused the read error

type WriteResultKind* {.pure.} = enum
  Written
    ## The data was written to the stream (or its internal queue) successfully
  
  Full
    ## The stream's internal queue was full

  Error
    ## An error occurred while writing to the stream

type WriteResult* = object
  case kind*: WriteResultKind
    ## The result kind
  
  of WriteResultKind.Written:
    ## The write operation was successful; no additional properties
  
  of WriteResultKind.Full:
    ## The stream's write queue was full; no additional properties
  
  of WriteResultKind.Error:
    exception*: Exception
      ## The exception that caused the write error

type CompleteResultKind* {.pure.} = enum
  Complete
    ## The stream was completed successfully
  
  Error
    ## An error occurred while completing the stream

type CompleteResult* = object
  case kind*: CompleteResultKind
    ## The result kind
  
  of CompleteResultKind.Complete:
    ## The stream was completed successfully; no additional properties
  
  of CompleteResultKind.Error:
    exception*: Exception
      ## The exception that caused the completion error

## Concept to be implemented by streams that use a queue
type QueuedStream* = concept
  
  func queueLen(this: Self): int
    ## The current queue length
  
  func isQueueEmpty(this: Self): int
    ## Whether the queue is currently empty.
    ## Should be true if queueLen is 0.
  
  func isQueueFull(this: Self): int
    ## Whether the queue is currently full
  
  func maxQueueLen(this: Self): int
    ## The queue's max length.
    ## If this property is mutable, the object will also implement HasMutableMaxQueueLen.

## Concept to be implemented by streams that have a mutable maximum queue length
type HasMutableMaxQueueLen* = concept

  proc `=maxQueueLen`(this: Self, newMaxLen: int)
    ## Sets the queue's max length

## Concept to be implemented by async write streams.
## Write streams that are backed by a queue and want to expose queue-related APIs to users should also implement QueuedStream.
type AsyncWriteStream*[T] = concept
  
  proc write(this: Self, item: sink T): Future[WriteResult]
    ## Writes a single item to the stream

  proc write(this: Self, items: sink seq[T]): Future[WriteResult]
    ## Writes multiple items to the stream.
    ## An error response should be returned as soon as the write operation fails.
    ## Additionally, if the number of items currently in the queue exceeds the maximum number of queue items, a Full result should be returned instead of writing any items.
    ## 
    ## Example scenario:
    ## A stream's write queue has 2 free slots.
    ## The "write" proc is called with 3 items.
    ## No items are written, and a Full result is returned because there are not enough free slots in the queue to write all the items in the write call.
  
  proc complete(this: Self): Future[CompleteResult]
    ## Completes the write stream and marks it as finished.
    ## Additional work such as closing a file descriptor or other cleanup work may be done as well.
    ## 
    ## If an Error response is returned, the stream's completion status will be dubious; you should check if it is marked as finished manually.
  
  proc complete[T](this: Self, item: sink T): Future[WriteResult]
    ## Writes a single item to the stream, completes the stream, then marks it as finished.
    ## Additional work such as closing a file descriptor or other cleanup work may be done as well.
    ## A Written result will be returned once the item is written and the stream is finished.
    ## 
    ## If an Error response is returned, the stream's completion status will be dubious; you should check if it is marked as finished manually.
  
  proc complete[T](this: Self, items: sink seq[T]): Future[WriteResult]
    ## Writes multiple items to the stream, completes the stream, then marks it as finished.
    ## Additional work such as closing a file descriptor or other cleanup work may be done as well.
    ## A Written result will be returned once the items are written and the stream is finished.
    ## 
    ## If an Error response is returned, the stream's completion status will be dubious; you should check if it is marked as finished manually.
  
  func isFinished(this: Self): bool
    ## Whether the stream is finished.
    ## Must be true if isFailed is also true.

  func isFailed(this: Self): bool
    ## Whether the stream failed.
    ## If this is true, isFinished must also be true, and exception must be Some.

  func canWrite(this: Self): bool
    ## Whether the stream can currently be written to.
    ## This must be false if isFinished is true.
    ## 
    ## This could be false for a variety of other reasons:
    ##  - The internal stream queue is full
    ##  - The stream is locked or paused

  func exception(this: Self): Option[Exception]
    # The exception that caused the stream to fail, or None if the stream did not fail.
    # Must be Some if isFailed is true.

## Concept to be implemented by async read streams.
## Read streams that are backed by a queue and want to expose queue-related APIs to users should also implement QueuedStream.
type AsyncReadStream*[T] = concept

  proc read(this: Self): Future[ReadResult[T]]
    ## Reads a single item.

  proc read(this: Self, count: int): Future[ReadResult[seq[T]]]
    ## Reads multiple items.
    ## This proc should never return more items than requested, but may return less.
    ## It should only return 0 items if count < 1, otherwise it should always return at least one.
    ## 
    ## It should only return less items than requested if the stream ended or an exception occurred.
    ## In that case, the next call to it should return a Finished or Exception result.
    ## 
    ## This proc should not raise any exceptions.
    ## If the stream cannot be read due to an error, return an Error result.

  proc readAll(this: Self): Future[ReadResult[seq[T]]]
    ## Reads the entire stream to a seq and returns it.
    ## Using this proc may not be desirable if the stream size is unknown or is expected to be very large.
    ## It behaves like read in terms of its return value.

  func isFinished(this: Self): bool
    ## Whether the stream is finished.
    ## Must be true if isFailed is also true.

  func isFailed(this: Self): bool
    ## Whether the stream failed.
    ## If this is true, isFinished must also be true, and exception must be Some.

  func canRead(this: Self): bool
    ## Whether the stream can currently be read from.
    ## This must be false if isFinished is true.
    ## 
    ## This could be false for a variety of other reasons:
    ##  - The internal stream queue is empty
    ##  - The stream is locked or paused

  func exception(this: Self): Option[Exception]
    ## The exception that caused the stream to fail, or None if the stream did not fail.
    ## Must be Some if isFailed is true.
