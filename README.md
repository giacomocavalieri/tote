# tote

[![Package Version](https://img.shields.io/hexpm/v/tote)](https://hex.pm/packages/tote)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/tote/)

👜 Bags (or multisets) in Gleam

> ⚙️ This package works for both the Erlang and JavaScript target

## What's a bag?

A `Bag` is a data structure similar to a set with the difference that it
can store multiple copies of the same item.

This means that you can efficiently check if an element is inside a bag with
the [contains](https://hexdocs.pm/tote/tote/bag.html#contains) function,
just like a set.
At the same time, you can ask how many copies of an item are contained inside a
bag using the [copies](https://hexdocs.pm/tote/tote/bag.html#copies) function.

> If you are curious about implementation details, a `Bag(a)` is nothing
> more than a handy wrapper around a `Map(a, Int)` that is used to keep
> track of the number of occurrences of each item.

## Installation

To add this package to your Gleam project:

```sh
gleam add tote
```

## Getting started

All the bag-related functions are in the `tote/bag` module, so once you've
imported that you're good to go:

```gleam
import gleam/int
import gleam/io
import tote/bag

pub fn main() {
  let valentino_bag =
    bag.from_list([
      "lipstick", "in", "my", "wh-", "wh-", "lipstick",
      "in", "my", "Valentino", "white", "bag", "?!"
    ])

  bag.copies(of: "lipstick", in: valentino_bag)
  |> int.to_string
  |> io.println
  // -> 2
}
```

If you don't get the Valentino reference,
[you're welcome!](https://www.youtube.com/watch?v=IzTlPjgJfTk)

## Contributing

If you think there's any way to improve this package, or if you spot a bug don't
be afraid to open PRs, issues or requests of any kind! Any contribution is
welcome 💜
