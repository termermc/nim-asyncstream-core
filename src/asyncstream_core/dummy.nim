## Dummy implementations of async read/write streams

import ".."/[asyncstream_core]

type DummyAsyncReadStream* {.implements: AsyncReadStream.} = ref object
  isFinished*: bool

when DummyAsyncReadStream isnot AsyncReadStream:
  {.fatal: "DummyAsyncReadStream does not implement AsyncReadStream".}
