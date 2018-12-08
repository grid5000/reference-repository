#!/usr/bin/ruby

# FIXME adjust (probably broken)

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../lib')))
require "refrepo"
require "test/unit"
require "hashdiff"

# Helper test routine. Test if the hashes are equal. Also do the test for symbolized keys.
def assert_equal_hash(hash1, hash2)
  diff = HashDiff.diff(hash1, hash2)
  assert_equal([], diff)
end

# Helper test routine. Test if the hashes are equal after having been expanded.
def assert_equal_expanded_hash(hash1, hash2)
  expanded_hash1 = hash1.clone.expand_square_brackets()
  expanded_hash2 = hash2.clone.expand_square_brackets()
  assert_equal_hash(expanded_hash1, expanded_hash2)
end

class TestInputLoader < Test::Unit::TestCase
 
  def test__deep_merge_entries
    a, b = 1, 2
    ha = {key: "value_a"}
    hb = {key: "value_b"}

    # Check
    assert_equal_hash(deep_merge_entries(a,    b),    b) # numeric - numeric
    assert_equal_hash(deep_merge_entries(a,   hb),   hb) # numeric - hash
    assert_equal_hash(deep_merge_entries(ha,   b),    b) # hash    - numeric
    assert_equal_hash(deep_merge_entries(ha,  hb),   hb) # hash    - hash

    assert_equal_hash(deep_merge_entries(a,   nil),   a) # numeric - nil
    assert_equal_hash(deep_merge_entries(nil,   b),   b) # nil     - numeric
    assert_equal_hash(deep_merge_entries(ha,  nil),  ha) # hash    - nil
    assert_equal_hash(deep_merge_entries(nil,  hb),  hb) # nil     - hash
    assert_equal_hash(deep_merge_entries(nil, nil), nil) # nil     - nil

    # Check recursivity
    # At the last level
    a = {"c-1" => {"c-2" => {"a-3" => 0}}}
    b = {"c-1" => {"c-2" => {"b-3" => 0}}}
    assert_equal_hash(deep_merge_entries(a, b), {"c-1" => {"c-2" => {"a-3" => 0, "b-3" => 0}}})

    # At an intermediate level
    a = {"c-1" => {"a-2" => {"a-3" => 0}}}
    b = {"c-1" => {"b-2" => {"b-3" => 0}}}
    assert_equal_hash(deep_merge_entries(a, b), {"c-1" => {
                          "a-2" => {"a-3" => 0}, 
                          "b-2" => {"b-3" => 0}
                        }
                      })
  end

  # Test the example given in documentation
  def test__expand_square_brackets__doc_example
    hash = {
      "foo-1" => {a => 0}, 
      "foo-2" => {a => 0}, 
      "foo-3" => {a => 0}, 
      "foo-[2-]" => {b => 1}
    }
    
    expected_expanded_hash = {
      "foo-1" => {a => 0}, 
      "foo-2" => {a => 0, b => 1}, 
      "foo-3" => {a => 0, b => 1}
    }

    assert_equal_expanded_hash(hash, expected_expanded_hash)
  end

  # The 'a' parameter
  def test__expand_square_brackets__a_values
    assert_equal_expanded_hash({"foo-[-3]" => 0},  {"foo-1" => 0, "foo-2" => 0, "foo-3" => 0}) # Default 'a' value is 1
    assert_equal_expanded_hash({"foo-[2-3]" => 0}, {"foo-2" => 0, "foo-3" => 0})             # Simply check if the value of 'a' is taken into account
  end

  def test__expand_square_brackets__create_keys
    #
    # If 'b' is given, create missing keys. Also, the keys must be of the same type (Symbol or String).
    #

    # With symbol keys and numeric values
    assert_equal_expanded_hash({"foo-[2-3]" => 0}, {"foo-2" => 0, "foo-3" => 0})
    assert_equal_expanded_hash({"foo-[-2]" => 0},  {"foo-1" => 0, "foo-2" => 0})

    # With symbol keys and hash values
    assert_equal_expanded_hash({"foo-[2-3]" => {a => 0}}, {"foo-2" => {a => 0}, "foo-3" => {a => 0}})
    assert_equal_expanded_hash({"foo-[-2]" =>  {a => 0}}, {"foo-1" => {a => 0}, "foo-2" => {a => 0}})
    
    # With string keys and numeric values
    assert_equal_expanded_hash({"foo-[2-3]" => 0}, {"foo-2" => 0, "foo-3" => 0})
    assert_equal_expanded_hash({"foo-[-2]"  => 0}, {"foo-1" => 0, "foo-2" => 0})
        
    # With string keys and hash values
    assert_equal_expanded_hash({"foo-[2-3]" => {a => 0}}, {"foo-2" => {a => 0}, "foo-3" => {a => 0}})
    assert_equal_expanded_hash({"foo-[-2]"  => {a => 0}}, {"foo-1" => {a => 0}, "foo-2" => {a => 0}})
    
    #
    # If 'b' is not given, do not create any new key
    #
    assert_equal_expanded_hash({"foo-[-]" => 0}, {})   # All
    assert_equal_expanded_hash({"foo-[2-]" => 0}, {})

  end

  def test__expand_square_brackets__keep_existing_keys
    #
    # Do not modify existing keys
    #

    [0, {h: 0}].each { |v|
      assert_equal_expanded_hash({"foo-[1-3]" => v, "foo-2" => 1}, {"foo-1" => v, "foo-2" => 1, "foo-3" => v}) # b given
      assert_equal_expanded_hash({"foo-[2-]" =>  v, "foo-2" => 1}, {"foo-2" => 1})                         # b not given 
    }
  end
  
  # Some tests with nil values (=> nil values are created, existing nil values are overriden)
  def test__expand_square_brackets__nil
    assert_equal_expanded_hash({"foo-[2-3]" => nil},              {"foo-2" => nil, "foo-3" => nil})  # PREFIX-[a-b] is nil
    assert_equal_expanded_hash({"foo-[2-3]" => 0, "foo-2" => nil},  {"foo-2" => 0, "foo-3" => 0})      # PREFIX-x     is nil
    assert_equal_expanded_hash({"foo-[2-]" => nil, "foo-3" => 0},   {"foo-3" => 0})                  # PREFIX-[a-]  is nil
    assert_equal_expanded_hash({"foo-[2-]" => 0,   "foo-3" => nil}, {"foo-3" => 0})                  # PREFIX-x     is nil
  end

end
