////
//// This module has all the functions you may need to work with bags (if you
//// feel something is missing, please
//// [open an issue](https://github.com/giacomocavalieri/tote/issues))!
////
//// To quickly browse the documentation you can use this cheatsheet:
////
//// <table>
//// <tbody>
////   <tr>
////     <td>Creating bags</td>
////     <td>
////      <a href="#new">new</a>,
////      <a href="#from_list">from_list</a>,
////      <a href="#from_map">from_map</a>
////     </td>
////   </tr>
////   <tr>
////     <td>Adding or removing items</td>
////     <td>
////      <a href="#insert">insert</a>,
////      <a href="#remove">remove</a>,
////      <a href="#remove_all">remove_all</a>,
////      <a href="#update">update</a>
////     </td>
////   </tr>
////   <tr>
////     <td>Querying the content of a bag</td>
////     <td>
////      <a href="#copies">copies</a>,
////      <a href="#contains">contains</a>,
////      <a href="#is_empty">is_empty</a>,
////      <a href="#size">size</a>
////     </td>
////   </tr>
////   <tr>
////     <td>Combining bags</td>
////     <td>
////      <a href="#intersect">intersect</a>,
////      <a href="#merge">merge</a>,
////      <a href="#subtract">subtract</a>
////     </td>
////   </tr>
////   <tr>
////     <td>Transforming the content of a bag</td>
////     <td>
////      <a href="#fold">fold</a>,
////      <a href="#map">map</a>,
////      <a href="#filter">filter</a>
////     </td>
////   </tr>
////   <tr>
////     <td>Converting a bag into other data structures</td>
////     <td>
////      <a href="#to_list">to_list</a>,
////      <a href="#to_set">to_set</a>,
////      <a href="#to_map">to_map</a>
////     </td>
////   </tr>
//// </tbody>
//// </table>
////

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order.{Eq, Gt, Lt}
import gleam/set.{type Set}

/// A `Bag` is a data structure similar to a set with the difference that it
/// can store multiple copies of the same item.
///
/// This means that you can efficiently check if an element is inside a bag with
/// the [contains](#contains) function, just like a set. At the same time, you
/// can ask how many copies of an item are contained inside a bag using the
/// [copies](#copies) function.
///
/// > If you are curious about implementation details, a `Bag(a)` is nothing
/// > more than a handy wrapper around a `Map(a, Int)` that is used to keep
/// > track of the number of occurrences of each item.
///
pub opaque type Bag(a) {
  Bag(map: Dict(a, Int))
}

// BAG CREATION ----------------------------------------------------------------

/// Creates a new empty bag.
///
pub fn new() -> Bag(a) {
  Bag(dict.new())
}

/// Creates a new bag from the given list by counting its items.
///
/// ## Examples
///
/// ```gleam
/// bag.from_list(["a", "b", "a", "c"])
/// |> bag.to_list
/// // [#("a", 2), #("b", 1), #("c", 1)]
/// ```
///
pub fn from_list(list: List(a)) -> Bag(a) {
  use bag, item <- list.fold(over: list, from: new())
  insert(into: bag, copies: 1, of: item)
}

/// Creates a new bag from the map where each key/value pair is turned into
/// an item with those many copies inside the bag.
///
/// ## Examples
///
/// ```gleam
/// map.from_list([#("a", 1), #("b", 2)])
/// |> bag.from_map
/// |> bag.to_list
/// // [#("a", 1), #("b", 2)]
/// ```
///
pub fn from_map(map: Dict(a, Int)) -> Bag(a) {
  Bag(map)
}

// UPDATING BAGS ---------------------------------------------------------------

/// Adds `n` copies of the given item into a bag.
///
/// If the number of copies to add is negative, then this is the same as calling
/// [`remove`](#remove) and will remove that many copies from the bag.
///
/// ## Examples
///
/// ```gleam
/// bag.new()
/// |> bag.insert(2, "a")
/// |> bag.copies(of: "a")
/// // 2
/// ```
///
/// ```gleam
/// bag.from_list(["a"])
/// |> bag.insert(-1, "a")
/// |> bag.copies(of: "a")
/// // 0
/// ```
///
pub fn insert(into bag: Bag(a), copies to_add: Int, of item: a) -> Bag(a) {
  case int.compare(to_add, 0) {
    Lt -> remove(from: bag, copies: to_add, of: item)
    Eq -> bag
    Gt ->
      Bag(
        dict.upsert(bag.map, item, fn(n) {
          case n {
            Some(n) -> n + to_add
            None -> to_add
          }
        }),
      )
  }
}

/// Removes `n` copies of the given item from a bag.
///
/// If the quantity to remove is greater than the number of copies in the bag,
/// all copies of that item are removed.
///
/// > ⚠️ Giving a negative quantity to remove doesn't really make sense, so the
/// > sign of the `copies` argument is always ignored.
///
/// ## Examples
///
/// ```gleam
/// bag.from_list(["a", "a"])
/// |> bag.remove(1, "a")
/// |> bag.copies(of: "a")
/// // 1
/// ```
///
/// ```gleam
/// bag.from_list(["a", "a"])
/// |> bag.remove(-1, "a")
/// |> bag.copies(of: "a")
/// // 1
/// ```
///
/// ```gleam
/// bag.from_list(["a", "a"])
/// |> bag.remove(10, "a")
/// |> bag.copies(of: "a")
/// // 0
/// ```
///
pub fn remove(from bag: Bag(a), copies to_remove: Int, of item: a) -> Bag(a) {
  let to_remove = int.absolute_value(to_remove)
  let item_copies = copies(bag, item)
  case int.compare(to_remove, item_copies) {
    Lt -> Bag(dict.insert(bag.map, item, item_copies - to_remove))
    Gt | Eq -> remove_all(bag, item)
  }
}

/// Removes all the copies of a given item from a bag.
///
/// ## Examples
///
/// ```gleam
/// bag.from_list(["a", "b", "a"])
/// |> bag.remove_all("a")
/// |> bag.to_list
/// // [#(b, 1)]
/// ```
pub fn remove_all(from bag: Bag(a), copies_of item: a) -> Bag(a) {
  Bag(dict.delete(bag.map, item))
}

/// Updates the number of copies of an item in the bag.
///
/// If the function returns 0 or a negative number, the item is removed from
/// the bag.
///
/// ## Examples
///
/// ```gleam
/// bag.from_list(["a"])
/// |> bag.update("a", fn(n) { n + 1 })
/// |> bag.copies(of: "a")
/// // 2
/// ```
///
/// ```gleam
/// bag.new()
/// |> bag.update("a", fn(_) { 10 })
/// |> bag.copies(of: "a")
/// // 10
/// ```
///
/// ```gleam
/// bag.from_list(["a"])
/// |> bag.update("a", fn(_) { -1 })
/// |> bag.copies(of: "a")
/// // 0
/// ```
///
pub fn update(in bag: Bag(a), item item: a, with fun: fn(Int) -> Int) -> Bag(a) {
  let count = copies(bag, item)
  let new_count = fun(count)
  case int.compare(new_count, 0) {
    Lt | Eq -> remove_all(bag, copies_of: item)
    Gt ->
      remove_all(from: bag, copies_of: item)
      |> insert(copies: new_count, of: item)
  }
}

// QUERYING BAGS ---------------------------------------------------------------

/// Counts the number of copies of an item inside a bag.
///
/// ## Examples
///
/// ```gleam
/// bag.from_list(["a", "b", "a", "c"])
/// |> bag.copies(of: "a")
/// // 2
/// ```
///
pub fn copies(in bag: Bag(a), of item: a) -> Int {
  case dict.get(bag.map, item) {
    Ok(copies) -> copies
    Error(Nil) -> 0
  }
}

/// Returns `True` if the bag contains at least a copy of the given item.
///
/// ## Examples
///
/// ```gleam
/// bag.from_list(["a", "b"])
/// |> bag.contains("a")
/// // True
/// ```
///
/// ```gleam
/// bag.from_list(["a", "b"])
/// |> bag.contains("c")
/// // False
/// ```
///
pub fn contains(bag: Bag(a), item: a) -> Bool {
  dict.has_key(bag.map, item)
}

/// Returns `True` if the bag is empty.
///
/// > ⚠️ This is more efficient than checking if the bag's size is 0.
/// > You should always use this function to check that a bag is empty!
///
/// ## Examples
///
/// ```gleam
/// bag.new()
/// |> bag.is_empty()
/// // True
/// ```
///
/// ```gleam
/// bag.from_list(["a", "b"])
/// |> bag.is_empty()
/// // False
/// ```
///
pub fn is_empty(bag: Bag(a)) -> Bool {
  bag.map == dict.new()
}

/// Returns the total number of items inside a bag.
///
/// > ⚠️ This function takes linear time in the number of distinct items in the
/// > bag.
/// >
/// > If you need to check that a bag is empty, you should always use the
/// > [`is_empty`](#is_empty) function instead of checking if the size is 0.
/// > It's going to be way more efficient!
///
/// ## Examples
///
/// ```gleam
/// bag.from_list(["a", "b", "a", "c"])
/// |> bag.size
/// // 4
/// ```
///
pub fn size(bag: Bag(a)) -> Int {
  use sum, _item, copies <- fold(over: bag, from: 0)
  sum + copies
}

// COMBINING BAGS --------------------------------------------------------------

/// Intersects two bags keeping the minimum number of copies of each item
/// that appear in both bags.
///
/// ## Examples
///
/// ```gleam
/// let bag1 = bag.from_list(["a", "a", "b", "c"])
/// let bag2 = bag.from_list(["a", "c", "c"])
///
/// bag.intersect(bag1, bag2)
/// |> bag.to_list
/// // [#("a", 1), #("c", 1)]
/// ```
///
pub fn intersect(one: Bag(a), with other: Bag(a)) -> Bag(a) {
  use acc, item, copies_in_one <- fold(over: one, from: new())
  case copies(other, item) {
    0 -> acc
    copies_in_other ->
      insert(acc, int.min(copies_in_one, copies_in_other), item)
  }
}

/// Adds all the items of two bags together.
///
/// ## Examples
///
/// ```gleam
/// let bag1 = bag.from_list(["a", "b"])
/// let bag2 = bag.from_list(["b", "c"])
///
/// bag.merge(bag1, bag2)
/// |> bag.to_list
/// // [#("a", 1), #("b", 2), #("c", 1)]
/// ```
///
pub fn merge(one: Bag(a), with other: Bag(a)) -> Bag(a) {
  use acc, item, copies_in_one <- fold(over: one, from: other)
  insert(into: acc, copies: copies_in_one, of: item)
}

/// Removes all items of the second bag from the first one.
///
/// ## Examples
///
/// ```gleam
/// let bag1 = bag.from_list(["a", "b", "b"])
/// let bag2 = bag.from_list(["b", "c"])
///
/// bag.subtract(from: one, items_of: other)
/// |> bag.to_list
/// // [#("a", 1), #("b", 1)]
/// ```
///
pub fn subtract(from one: Bag(a), items_of other: Bag(a)) -> Bag(a) {
  use acc, item, copies_in_other <- fold(over: other, from: one)
  remove(from: acc, copies: copies_in_other, of: item)
}

// TRANSFORMING BAGS -----------------------------------------------------------

/// Combines all items of a bag into a single value by calling a given function
/// on each one.
///
/// The function will receive as input the accumulator, the item and
/// its number of copies.
///
/// ## Examples
///
/// ```gleam
/// let bag = bag.from_list(["a", "b", "b"])
/// bag.fold(over: bag, from: 0, with: fn(count, _, copies) {
///   count + copies
/// })
/// // 3
/// ```
pub fn fold(
  over bag: Bag(a),
  from initial: acc,
  with fun: fn(acc, a, Int) -> acc,
) -> acc {
  dict.fold(over: bag.map, from: initial, with: fun)
}

/// Updates all values of a bag calling on each a function that takes as
/// argument the item and its number of copies.
///
/// If one or more items are mapped to the same item, their occurrences are
/// summed up.
///
/// ## Examples
///
/// ```gleam
/// bag.from_list(["a", "b", "b"])
/// |> bag.map(fn(item, _) { "c" })
/// |> bag.to_list
/// // [#("c", 3)]
/// ```
///
pub fn map(bag: Bag(a), with fun: fn(a, Int) -> b) -> Bag(b) {
  use acc, item, copies <- fold(over: bag, from: new())
  insert(into: acc, copies: copies, of: fun(item, copies))
}

/// Only keeps the items of a bag the respect a given predicate that takes as
/// input an item and the number of its copies.
///
/// ## Examples
///
/// ```gleam
/// bag.from_list(["a", "b", "a", "b", "c", "d"])
/// |> bag.filter(keeping: fn(_, copies) { copies <= 1 })
/// |> bag.to_list
/// // [#("c", 1), #("d", 1)]
/// ```
///
pub fn filter(bag: Bag(a), keeping predicate: fn(a, Int) -> Bool) -> Bag(a) {
  use acc, item, copies <- fold(over: bag, from: new())
  case predicate(item, copies) {
    True -> insert(into: acc, copies: copies, of: item)
    False -> acc
  }
}

// BAG CONVERSIONS -------------------------------------------------------------

/// Turns a `Bag` into a list of items and their respective number of copies in
/// the bag.
///
/// ## Examples
///
/// ```gleam
/// bag.from_list(["a", "b", "a", "c"])
/// |> bag.to_list
/// // [#("a", 2), #("b", 1), #("c", 1)]
/// ```
///
pub fn to_list(bag: Bag(a)) -> List(#(a, Int)) {
  dict.to_list(bag.map)
}

/// Turns a `Bag` into a set of its items, losing all information on their
/// number of copies.
///
/// ## Examples
///
/// ```gleam
/// bag.from_list(["a", "b", "a", "c"])
/// |> bag.to_set
/// // set.from_list(["a", "b", "c"])
/// ```
///
pub fn to_set(bag: Bag(a)) -> Set(a) {
  set.from_list(dict.keys(bag.map))
}

/// Turns a `Bag` into a map. Each item in the bag becomes a key and the
/// associated value is the number of its copies in the bag.
///
pub fn to_map(bag: Bag(a)) -> Dict(a, Int) {
  bag.map
}
