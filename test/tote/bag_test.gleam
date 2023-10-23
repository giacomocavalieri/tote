import gleam/int
import gleam/iterator
import gleam/list
import gleam/map.{Map}
import gleam/pair
import gleam/set
import gleeunit/should
import prng/random.{Generator}
import prng/seed
import tote/bag.{Bag}

// UNIT TESTS ------------------------------------------------------------------

pub fn empty_bag_has_size_zero_test() {
  bag.size(bag.new())
  |> should.equal(0)
}

// INSERTION, UPDATE AND REMOVAL PROPERTIES ------------------------------------

pub fn insert_adds_the_given_copies_test() {
  use #(bag, letter, added_copies) <- fuzz(bag_letter_and_copies())
  let existing_copies = bag.copies(of: letter, in: bag)
  bag.insert(into: bag, copies: added_copies, of: letter)
  |> bag.copies(of: letter)
  |> should.equal(existing_copies + added_copies)
}

pub fn remove_removes_the_given_copies_test() {
  use #(bag, letter, removed_copies) <- fuzz(bag_letter_and_copies())
  let existing_copies = bag.copies(of: letter, in: bag)
  bag.remove(from: bag, copies: removed_copies, of: letter)
  |> bag.copies(of: letter)
  |> should.equal(int.max(0, existing_copies - removed_copies))
}

pub fn remove_with_a_negative_number_is_the_same_as_with_a_positive_number_test() {
  use #(bag, letter, removed_copies) <- fuzz(bag_letter_and_copies())
  bag.remove(from: bag, copies: -removed_copies, of: letter)
  |> should.equal(bag.remove(from: bag, copies: removed_copies, of: letter))
}

pub fn insert_with_negative_number_is_the_same_as_remove_test() {
  use #(bag, letter, copies) <- fuzz(bag_letter_and_copies())
  bag.insert(into: bag, copies: -copies, of: letter)
  |> should.equal(bag.remove(from: bag, copies: copies, of: letter))
}

pub fn inserting_zero_copies_leaves_the_bag_unchanged_test() {
  use #(bag, letter) <- fuzz(bag_and_letter())
  bag.insert(into: bag, copies: 0, of: letter)
  |> should.equal(bag)
}

pub fn remove_all_removes_all_the_copies_test() {
  use #(bag, letter) <- fuzz(bag_and_letter())
  bag.remove_all(copies_of: letter, from: bag)
  |> bag.copies(of: letter)
  |> should.equal(0)
}

pub fn update_with_zero_is_equivalent_to_remove_all_test() {
  use #(bag, letter) <- fuzz(bag_and_letter())
  bag.update(in: bag, item: letter, with: fn(_) { 0 })
  |> should.equal(bag.remove_all(copies_of: letter, from: bag))
}

pub fn update_with_negative_is_equivalent_to_remove_all_test() {
  use #(bag, letter) <- fuzz(bag_and_letter())
  bag.update(in: bag, item: letter, with: fn(_) { -1 })
  |> should.equal(bag.remove_all(copies_of: letter, from: bag))
}

pub fn update_with_positive_is_equivalent_to_remove_all_and_insert_test() {
  use #(bag, letter, copies) <- fuzz(bag_letter_and_copies())
  bag.remove_all(copies_of: letter, from: bag)
  |> bag.insert(copies: copies, of: letter)
  |> should.equal(bag.update(in: bag, item: letter, with: fn(_) { copies }))
}

// PROPERTIES OF QUERYING FUNCTIONS --------------------------------------------

pub fn contains_after_insert_is_always_true_test() {
  use #(bag, letter, copies) <- fuzz(bag_letter_and_copies())
  bag.update(in: bag, item: letter, with: fn(_) { copies })
  |> bag.contains(letter)
  |> should.equal(True)
}

pub fn contains_after_removing_all_is_always_false_test() {
  use #(bag, letter) <- fuzz(bag_and_letter())
  bag.remove_all(copies_of: letter, from: bag)
  |> bag.contains(letter)
  |> should.equal(False)
}

pub fn contains_is_true_if_copies_is_greater_than_zero_test() {
  use #(bag, letter) <- fuzz(bag_and_letter())
  bag.contains(bag, letter)
  |> should.equal(bag.copies(of: letter, in: bag) > 0)
}

pub fn copies_returns_the_number_of_inserted_copies_test() {
  use #(bag, letter, copies) <- fuzz(bag_letter_and_copies())
  bag.update(in: bag, item: letter, with: fn(_) { copies })
  |> bag.copies(of: letter)
  |> should.equal(copies)
}

pub fn a_bag_created_from_a_list_has_size_equal_to_its_length_test() {
  use letters <- fuzz(letters())
  bag.size(bag.from_list(letters))
  |> should.equal(list.length(letters))
}

pub fn size_is_equivalent_to_fold_test() {
  use bag <- fuzz(bag())
  bag.fold(bag, 0, fn(size, _, copies) { size + copies })
  |> should.equal(bag.size(bag))
}

// TODO: this will fail on the js target because of a bug in the map's
//       implementation. A fix is on its way so this target should be removed
//       in future versions of the language
@target(erlang)
pub fn bag_is_empty_when_size_is_zero_test() {
  use bag <- fuzz(bag())
  bag.is_empty(bag)
  |> should.equal(bag.size(bag) == 0)
}

// PROPERTIES OF TRANSFORMATION FUNCTIONS --------------------------------------

pub fn elements_mapped_to_the_same_thing_get_summed_together_test() {
  use #(bag, letter) <- fuzz(bag_and_letter())
  bag.map(bag, fn(_, _) { letter })
  |> bag.copies(of: letter)
  |> should.equal(bag.size(bag))
}

pub fn filter_drops_elements_with_result_false_test() {
  use bag <- fuzz(bag())
  bag.filter(bag, keeping: fn(_, _) { False })
  |> bag.is_empty
  |> should.equal(True)
}

pub fn filter_keeps_elements_with_result_true_test() {
  use bag <- fuzz(bag())
  bag.filter(bag, keeping: fn(_, _) { True })
  |> should.equal(bag)
}

// PROPERTIES OF CONVERTIONS ---------------------------------------------------

pub fn to_map_inverse_of_from_map_test() {
  use map <- fuzz(letters_map())
  bag.to_map(bag.from_map(map))
  |> should.equal(map)
}

pub fn from_map_inverse_of_to_map_test() {
  use bag <- fuzz(bag())
  bag.from_map(bag.to_map(bag))
  |> should.equal(bag)
}

pub fn to_set_same_as_taking_the_distinct_items_test() {
  use bag <- fuzz(bag())

  let distinct_items =
    bag.to_map(bag)
    |> map.keys
    |> set.from_list

  bag.to_set(bag)
  |> should.equal(distinct_items)
}

pub fn to_map_same_as_to_list_and_then_list_to_map_test() {
  use bag <- fuzz(bag())
  bag.to_list(bag)
  |> map.from_list
  |> should.equal(bag.to_map(bag))
}

// FUZZYING HELPERS ------------------------------------------------------------

fn fuzz(for_each generator: Generator(a), check assertion: fn(a) -> Nil) -> Nil {
  random.to_iterator(generator, seed.new(11))
  |> iterator.take(100)
  |> iterator.each(assertion)
}

fn letter() -> Generator(String) {
  random.uniform("a", ["b", "c", "d", "e", "f", "g"])
}

fn letters() -> Generator(List(String)) {
  use size <- random.then(random.int(0, 100))
  random.list(from: letter(), of: size)
}

fn bag() -> Generator(Bag(String)) {
  random.map(letters(), bag.from_list)
}

fn bag_and_letter() -> Generator(#(Bag(String), String)) {
  random.map2(bag(), letter(), pair.new)
}

fn bag_letter_and_copies() -> Generator(#(Bag(String), String, Int)) {
  triple(bag(), letter(), positive_int())
}

fn letters_map() -> Generator(Map(String, Int)) {
  let letter_with_copies = random.map2(letter(), positive_int(), pair.new)

  random.int(0, 100)
  |> random.then(fn(size) { random.list(letter_with_copies, of: size) })
  |> random.map(map.from_list)
}

fn positive_int() -> Generator(Int) {
  random.int(0, random.max_int)
}

fn triple(
  gen1: Generator(a),
  gen2: Generator(b),
  gen3: Generator(c),
) -> Generator(#(a, b, c)) {
  random.map3(gen1, gen2, gen3, fn(a, b, c) { #(a, b, c) })
}
