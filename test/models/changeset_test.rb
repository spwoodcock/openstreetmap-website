require "test_helper"

class ChangesetTest < ActiveSupport::TestCase
  def test_from_xml_no_text
    no_text = ""
    message_create = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(no_text, :create => true)
    end
    assert_match(/Must specify a string with one or more characters/, message_create.message)
    message_update = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(no_text, :create => false)
    end
    assert_match(/Must specify a string with one or more characters/, message_update.message)
  end

  def test_from_xml_no_changeset
    nocs = "<osm></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(nocs, :create => true)
    end
    assert_match %r{XML doesn't contain an osm/changeset element}, message_create.message
    message_update = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(nocs, :create => false)
    end
    assert_match %r{XML doesn't contain an osm/changeset element}, message_update.message
  end

  def test_from_xml_no_k_v
    nokv = "<osm><changeset><tag /></changeset></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(nokv, :create => true)
    end
    assert_match(/tag is missing key/, message_create.message)
    message_update = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(nokv, :create => false)
    end
    assert_match(/tag is missing key/, message_update.message)
  end

  def test_from_xml_no_v
    no_v = "<osm><changeset><tag k='key' /></changeset></osm>"
    message_create = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(no_v, :create => true)
    end
    assert_match(/tag is missing value/, message_create.message)
    message_update = assert_raise(OSM::APIBadXMLError) do
      Changeset.from_xml(no_v, :create => false)
    end
    assert_match(/tag is missing value/, message_update.message)
  end

  def test_from_xml_duplicate_k
    dupk = "<osm><changeset><tag k='dup' v='test' /><tag k='dup' v='value' /></changeset></osm>"
    message_create = assert_raise(OSM::APIDuplicateTagsError) do
      Changeset.from_xml(dupk, :create => true)
    end
    assert_equal "Element changeset/ has duplicate tags with key dup", message_create.message
    message_update = assert_raise(OSM::APIDuplicateTagsError) do
      Changeset.from_xml(dupk, :create => false)
    end
    assert_equal "Element changeset/ has duplicate tags with key dup", message_update.message
  end

  def test_from_xml_valid
    # Example taken from the Update section on the API_v0.6 docs on the wiki
    xml = "<osm><changeset><tag k=\"comment\" v=\"Just adding some streetnames and a restaurant\"/></changeset></osm>"
    assert_nothing_raised do
      Changeset.from_xml(xml, :create => false)
    end
    assert_nothing_raised do
      Changeset.from_xml(xml, :create => true)
    end
  end

  def test_subscription
    changeset = create(:changeset)
    user = create(:user)

    assert_not changeset.subscribed?(user)

    changeset.subscribe(user)
    assert changeset.subscribed?(user)

    changeset.unsubscribe(changeset.subscribers.first)
    assert_not changeset.subscribed?(user)
  end
end
