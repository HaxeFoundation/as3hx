TODO FOR HAXE3
--------------

* Ensure that ", implements" is turned into " implements", same for extends,
  to handle haxe3's version of interface declaration syntax.

* Replace ObjectHash<N, M> with Map<N, M>
* Replace IntHash<N> with Map<Int, N>
* Replace Hash<N> with Map<String, N>
* Note that cast to Map<T, Dynamic> doesn't work (haxe bug) so instead use:
  - For T = Int, cast to haxe.ds.IntMap<Dynamic>
  - For T = String, cast to haxe.ds.StringMap<Dynamic>
  - For T = object, cast to haxe.ds.ObjectMap<Dynamic>
* Note that if any of the type parameters of Map are themselves parameterized
  types, Map can't be used.
* Note that enums can't be used as Map keys, so must manually convert the
  enum to/from string and use a String key


* Replace enum "classes" with real enums

* Don't generate isEmpty() check for Array, use length() == 0

* Change converter to use (get, set) property types, and to name the
  getter and setter methods get_x and set_x

* Consider changing private static var init = { } pattern by adding a Bool
  type and then adding a true; to the end of the block

* Re-evaluate how test_only is converted into haxe - what about emitting
  a TIVOCONFIG_TEST version of the property description and a normal one,
  and emitting test_only property methods surrounded by TIVOCONFIG_TEST?
