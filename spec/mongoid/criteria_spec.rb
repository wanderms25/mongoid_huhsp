require "spec_helper"

describe Mongoid::Criteria do

  describe "#==" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    context "when the other is a criteria" do

      context "when the criteria are the same" do

        let(:other) do
          Band.where(name: "Depeche Mode")
        end

        it "returns true" do
          criteria.should eq(other)
        end
      end

      context "when the criteria differ" do

        let(:other) do
          Band.where(name: "Tool")
        end

        it "returns false" do
          criteria.should_not eq(other)
        end
      end
    end

    context "when the other is an enumerable" do

      context "when the entries are the same" do

        let!(:band) do
          Band.create(name: "Depeche Mode")
        end

        let(:other) do
          [ band ]
        end

        it "returns true" do
          criteria.should eq(other)
        end
      end

      context "when the entries are not the same" do

        let!(:band) do
          Band.create(name: "Depeche Mode")
        end

        let!(:other_band) do
          Band.create(name: "Tool")
        end

        let(:other) do
          [ other_band ]
        end

        it "returns false" do
          criteria.should_not eq(other)
        end
      end
    end

    context "when the other is neither a criteria or enumerable" do

      it "returns false" do
        criteria.should_not eq("test")
      end
    end
  end

  describe "#===" do

    context "when the other is a criteria" do

      let(:other) do
        Band.where(name: "Depeche Mode")
      end

      it "returns true" do
        (described_class === other).should be_true
      end
    end

    context "when the other is not a criteria" do

      it "returns false" do
        (described_class === []).should be_false
      end
    end
  end

  [ :all, :all_in ].each do |method|

    describe "\##{method}" do

      let!(:match) do
        Band.create(genres: [ "electro", "dub" ])
      end

      let!(:non_match) do
        Band.create(genres: [ "house" ])
      end

      let(:criteria) do
        Band.send(method, genres: [ "electro", "dub" ])
      end

      it "returns the matching documents" do
        criteria.should eq([ match ])
      end
    end
  end

  [ :and, :all_of ].each do |method|

    describe "\##{method}" do

      let!(:match) do
        Band.create(name: "Depeche Mode", genres: [ "electro" ])
      end

      let!(:non_match) do
        Band.create(genres: [ "house" ])
      end

      let(:criteria) do
        Band.send(method, { genres: "electro" }, { name: "Depeche Mode" })
      end

      it "returns the matching documents" do
        criteria.should eq([ match ])
      end
    end
  end

  describe "#as_json" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "returns the criteria as a json hash" do
      criteria.as_json.should eq([ band.serializable_hash ])
    end
  end

  describe "#between" do

    let!(:match) do
      Band.create(member_count: 3)
    end

    let!(:non_match) do
      Band.create(member_count: 10)
    end

    let(:criteria) do
      Band.between(member_count: 1..5)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#build" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    context "when provided valid attributes" do

      let(:band) do
        criteria.build(genres: [ "electro" ])
      end

      it "returns the new document" do
        band.should be_new_record
      end

      it "sets the criteria attributes" do
        band.name.should eq("Depeche Mode")
      end

      it "sets the attributes passed to build" do
        band.genres.should eq([ "electro" ])
      end
    end
  end

  [ :clone, :dup ].each do |method|

    describe "\##{method}" do

      let(:band) do
        Band.new
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode").asc(:name).includes(:records)
      end

      before do
        criteria.documents = [ band ]
        criteria.context
      end

      let(:clone) do
        criteria.send(method)
      end

      it "contains an equal selector" do
        clone.selector.should eq({ "name" => "Depeche Mode" })
      end

      it "clones the selector" do
        clone.selector.should_not equal(criteria.selector)
      end

      it "contains equal options" do
        clone.options.should eq({ sort: { "name" => 1 }})
      end

      it "clones the options" do
        clone.options.should_not equal(criteria.options)
      end

      it "contains equal inclusions" do
        clone.inclusions.should eq([ Band.relations["records"] ])
      end

      it "clones the inclusions" do
        clone.inclusions.should_not equal(criteria.inclusions)
      end

      it "contains equal documents" do
        clone.documents.should eq([ band ])
      end

      it "clones the documents" do
        clone.documents.should_not equal(criteria.documents)
      end

      it "contains equal scoping options" do
        clone.scoping_options.should eq([ nil, nil ])
      end

      it "clones the scoping options" do
        clone.scoping_options.should_not equal(criteria.scoping_options)
      end

      it "sets the context to nil" do
        clone.instance_variable_get(:@context).should be_nil
      end
    end
  end

  describe "#collection" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "returns the model collection" do
      criteria.collection.should eq(Band.collection)
    end
  end

  describe "#cache" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "sets the cache option to true" do
      criteria.cache.should be_cached
    end
  end

  describe "#context" do

    context "when the model is embedded" do

      let(:criteria) do
        described_class.new(Record) do |criteria|
          criteria.embedded = true
        end
      end

      it "returns the embedded context" do
        criteria.context.should be_a(Mongoid::Contexts::Enumerable)
      end
    end

    context "when the model is not embedded" do

      let(:criteria) do
        described_class.new(Band)
      end

      it "returns the mongo context" do
        criteria.context.should be_a(Mongoid::Contexts::Mongo)
      end
    end
  end

  describe "#create" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    context "when provided valid attributes" do

      let(:band) do
        criteria.create(genres: [ "electro" ])
      end

      it "returns the created document" do
        band.should be_persisted
      end

      it "sets the criteria attributes" do
        band.name.should eq("Depeche Mode")
      end

      it "sets the attributes passed to build" do
        band.genres.should eq([ "electro" ])
      end
    end
  end

  pending "#create!"

  describe "#documents" do

    let(:band) do
      Band.new
    end

    let(:criteria) do
      described_class.new(Band) do |criteria|
        criteria.documents = [ band ]
      end
    end

    it "returns the documents" do
      criteria.documents.should eq([ band ])
    end
  end

  describe "#documents=" do

    let(:band) do
      Band.new
    end

    let(:criteria) do
      described_class.new(Band)
    end

    before do
      criteria.documents = [ band ]
    end

    it "sets the documents" do
      criteria.documents.should eq([ band ])
    end
  end

  describe "#each" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    context "when provided a block" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      it "iterates over the matching documents" do
        criteria.each do |doc|
          doc.should eq(band)
        end
      end
    end

    context "when not provided a block" do

      pending "returns an enumerator"
    end
  end

  describe "#elem_match" do

    let!(:match) do
      Band.create(name: "Depeche Mode").tap do |band|
        band.records.create(name: "101")
      end
    end

    let!(:non_match) do
      Band.create(genres: [ "house" ])
    end

    let(:criteria) do
      Band.elem_match(records: { name: "101" })
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  pending "#execute_or_raise"

  describe "#exists" do

    let!(:match) do
      Band.create(name: "Depeche Mode")
    end

    let!(:non_match) do
      Band.create
    end

    let(:criteria) do
      Band.exists(name: true)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "#exists?" do

    context "when matching documents exist" do

      let!(:match) do
        Band.create(name: "Depeche Mode")
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      it "returns true" do
        criteria.exists?.should be_true
      end
    end

    context "when no matching documents exist" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      it "returns false" do
        criteria.exists?.should be_false
      end
    end
  end

  describe "#explain" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "returns the criteria explain path" do
      criteria.explain["cursor"].should eq("BasicCursor")
    end
  end

  describe "#extract_id" do

    context "when an id exists" do

      let(:criteria) do
        described_class.new(Band) do |criteria|
          criteria.selector[:id] = 1
        end
      end

      it "returns the id" do
        criteria.extract_id.should eq(1)
      end
    end

    context "when an _id exists" do

      let(:criteria) do
        described_class.new(Band) do |criteria|
          criteria.selector[:_id] = 1
        end
      end

      it "returns the _id" do
        criteria.extract_id.should eq(1)
      end
    end
  end

  describe "#find" do

    context "when using object ids" do

      let!(:band) do
        Band.create
      end

      context "when providing a single id" do

        context "when the id matches" do

          let(:found) do
            Band.find(band.id)
          end

          it "returns the matching document" do
            found.should eq(band)
          end
        end

        context "when the id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(BSON::ObjectId.new)
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(BSON::ObjectId.new)
            end

            it "returns nil" do
              found.should be_nil
            end
          end
        end
      end

      context "when providing a splat of ids" do

        let!(:band_two) do
          Band.create(name: "Tool")
        end

        context "when all ids match" do

          let(:found) do
            Band.find(band.id, band_two.id)
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, BSON::ObjectId.new)
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, BSON::ObjectId.new)
            end

            it "returns only the matching documents" do
              found.should eq([ band ])
            end
          end
        end
      end

      context "when providing an array of ids" do

        let!(:band_two) do
          Band.create(name: "Tool")
        end

        context "when all ids match" do

          let(:found) do
            Band.find([ band.id, band_two.id ])
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, BSON::ObjectId.new ])
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, BSON::ObjectId.new ])
            end

            it "returns only the matching documents" do
              found.should eq([ band ])
            end
          end
        end
      end
    end

    context "when using string ids" do

      before(:all) do
        Band.field :_id, type: String
      end

      after(:all) do
        Band.field :_id, type: BSON::ObjectId, default: ->{ BSON::ObjectId.new }
      end

      let!(:band) do
        Band.create do |band|
          band.id = "tool"
        end
      end

      context "when providing a single id" do

        context "when the id matches" do

          let(:found) do
            Band.find(band.id)
          end

          it "returns the matching document" do
            found.should eq(band)
          end
        end

        context "when the id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find("depeche-mode")
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find("depeche-mode")
            end

            it "returns nil" do
              found.should be_nil
            end
          end
        end
      end

      context "when providing a splat of ids" do

        let!(:band_two) do
          Band.create do |band|
            band.id = "depeche-mode"
          end
        end

        context "when all ids match" do

          let(:found) do
            Band.find(band.id, band_two.id)
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, "new-order")
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, "new-order")
            end

            it "returns only the matching documents" do
              found.should eq([ band ])
            end
          end
        end
      end

      context "when providing an array of ids" do

        let!(:band_two) do
          Band.create do |band|
            band.id = "depeche-mode"
          end
        end

        context "when all ids match" do

          let(:found) do
            Band.find([ band.id, band_two.id ])
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, "new-order" ])
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, "new-order" ])
            end

            it "returns only the matching documents" do
              found.should eq([ band ])
            end
          end
        end
      end
    end

    context "when using integer ids" do

      before(:all) do
        Band.field :_id, type: Integer
      end

      after(:all) do
        Band.field :_id, type: BSON::ObjectId, default: ->{ BSON::ObjectId.new }
      end

      let!(:band) do
        Band.create do |band|
          band.id = 1
        end
      end

      context "when providing a single id" do

        context "when the id matches" do

          let(:found) do
            Band.find(band.id)
          end

          it "returns the matching document" do
            found.should eq(band)
          end
        end

        context "when the id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(3)
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(3)
            end

            it "returns nil" do
              found.should be_nil
            end
          end
        end
      end

      context "when providing a splat of ids" do

        let!(:band_two) do
          Band.create do |band|
            band.id = 2
          end
        end

        context "when all ids match" do

          let(:found) do
            Band.find(band.id, band_two.id)
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, 3)
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(band.id, 3)
            end

            it "returns only the matching documents" do
              found.should eq([ band ])
            end
          end
        end
      end

      context "when providing an array of ids" do

        let!(:band_two) do
          Band.create do |band|
            band.id = 2
          end
        end

        context "when all ids match" do

          let(:found) do
            Band.find([ band.id, band_two.id ])
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, 3 ])
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find([ band.id, 3 ])
            end

            it "returns only the matching documents" do
              found.should eq([ band ])
            end
          end
        end
      end

      context "when providing a range" do

        let!(:band_two) do
          Band.create do |band|
            band.id = 2
          end
        end

        context "when all ids match" do

          let(:found) do
            Band.find(1..2)
          end

          it "contains the first match" do
            found.should include(band)
          end

          it "contains the second match" do
            found.should include(band_two)
          end
        end

        context "when any id does not match" do

          context "when raising a not found error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(1..3)
            end

            it "raises an error" do
              expect {
                found
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when raising no error" do

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            let(:found) do
              Band.find(1..3)
            end

            it "contains the first match" do
              found.should include(band)
            end

            it "contains the second match" do
              found.should include(band_two)
            end

            it "returns only the matches" do
              found.count.should eq(2)
            end
          end
        end
      end
    end
  end

  describe "#freeze" do

    let(:criteria) do
      Band.all
    end

    before do
      criteria.freeze
    end

    it "freezes the criteria" do
      criteria.should be_frozen
    end

    it "initializes inclusions" do
      criteria.inclusions.should be_empty
    end

    it "initializes the context" do
      criteria.context.should_not be_nil
    end
  end

  describe "#from_map_or_db" do

    before(:all) do
      Mongoid.identity_map_enabled = true
    end

    after(:all) do
      Mongoid.identity_map_enabled = false
    end

    context "when the document is in the identity map" do

      let!(:band) do
        Band.create(name: "Depeche Mode")
      end

      let(:criteria) do
        Band.where(_id: band.id)
      end

      let(:from_map) do
        criteria.from_map_or_db
      end

      it "returns the document from the map" do
        from_map.should equal(band)
      end
    end

    context "when the document is not in the identity map" do

      let!(:band) do
        Band.create(name: "Depeche Mode")
      end

      let(:criteria) do
        Band.where(_id: band.id)
      end

      before do
        Mongoid::IdentityMap.clear
      end

      let(:from_db) do
        criteria.from_map_or_db
      end

      it "returns the document from the database" do
        from_db.should_not equal(band)
      end

      it "returns the correct document" do
        from_db.should eq(band)
      end
    end
  end

  describe "$gt" do

    let!(:match) do
      Band.create(member_count: 5)
    end

    let!(:non_match) do
      Band.create(member_count: 1)
    end

    let(:criteria) do
      Band.gt(member_count: 4)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  describe "$gte" do

    let!(:match) do
      Band.create(member_count: 5)
    end

    let!(:non_match) do
      Band.create(member_count: 1)
    end

    let(:criteria) do
      Band.gte(member_count: 5)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  [ :in, :any_in ].each do |method|

    describe "\##{method}" do

      let!(:match) do
        Band.create(genres: [ "electro", "dub" ])
      end

      let!(:non_match) do
        Band.create(genres: [ "house" ])
      end

      let(:criteria) do
        Band.send(method, genres: [ "dub" ])
      end

      it "returns the matching documents" do
        criteria.should eq([ match ])
      end
    end
  end

  describe "#initialize" do

    let(:criteria) do
      described_class.new(Band)
    end

    it "sets the class" do
      criteria.klass.should eq(Band)
    end

    it "sets the aliased fields" do
      criteria.aliased_fields.should eq(Band.aliased_fields)
    end

    it "sets the serializers" do
      criteria.serializers.should eq(Band.fields)
    end
  end

  describe "#includes" do

    before do
      Mongoid.identity_map_enabled = true
    end

    after do
      Mongoid.identity_map_enabled = false
    end

    let!(:person) do
      Person.create
    end

    context "when providing inclusions to the default scope" do

      before do
        Person.default_scope(Person.includes(:posts))
      end

      after do
        Person.default_scoping = nil
      end

      let!(:post_one) do
        person.posts.create(title: "one")
      end

      let!(:post_two) do
        person.posts.create(title: "two")
      end

      context "when the criteria has no options" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.all.entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when calling first on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.first
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when calling last on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.last
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create
        end

        let!(:post_three) do
          person_two.posts.create(title: "three")
        end

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.asc(:_id).limit(1).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end

        it "does not insert the third post into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_three.id].should be_nil
        end
      end
    end

    context "when including a has and belongs to many" do

      let!(:preference_one) do
        person.preferences.create(name: "one")
      end

      let!(:preference_two) do
        person.preferences.create(name: "two")
      end

      context "when the criteria has no options" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:preferences).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "inserts the first document into the identity map" do
          preference_map[preference_one.id].should eq(preference_one)
        end

        it "inserts the second document into the identity map" do
          preference_map[preference_two.id].should eq(preference_two)
        end
      end

      context "when calling first on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.includes(:preferences).first
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "inserts the first document into the identity map" do
          preference_map[preference_one.id].should eq(preference_one)
        end

        it "inserts the second document into the identity map" do
          preference_map[preference_two.id].should eq(preference_two)
        end
      end

      context "when calling last on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.includes(:preferences).last
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "inserts the first document into the identity map" do
          preference_map[preference_one.id].should eq(preference_one)
        end

        it "inserts the second document into the identity map" do
          preference_map[preference_two.id].should eq(preference_two)
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create
        end

        let!(:preference_three) do
          person_two.preferences.create(name: "three")
        end

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:preferences).asc(:_id).limit(1).entries
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          preference_map[preference_one.id].should eq(preference_one)
        end

        it "inserts the second document into the identity map" do
          preference_map[preference_two.id].should eq(preference_two)
        end

        it "does not insert the third preference into the identity map" do
          preference_map[preference_three.id].should be_nil
        end
      end
    end

    context "when including a has many" do

      let!(:post_one) do
        person.posts.create(title: "one")
      end

      let!(:post_two) do
        person.posts.create(title: "two")
      end

      context "when the criteria has no options" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:posts).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when calling first on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.includes(:posts).first
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when calling last on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.includes(:posts).last
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create
        end

        let!(:post_three) do
          person_two.posts.create(title: "three")
        end

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:posts).asc(:_id).limit(1).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end

        it "does not insert the third post into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_three.id].should be_nil
        end
      end
    end

    context "when including a has one" do

      let!(:game_one) do
        person.create_game(name: "one")
      end

      let!(:game_two) do
        person.create_game(name: "two")
      end

      context "when the criteria has no options" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:game).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "deletes the replaced document from the identity map" do
          Mongoid::IdentityMap[Game.collection_name][game_one.id].should be_nil
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Game.collection_name][game_two.id].should eq(game_two)
        end

        context "when asking from map or db" do

          let(:in_map) do
            Mongoid::IdentityMap[Game.collection_name][game_two.id]
          end

          let(:game) do
            Game.where("person_id" => person.id).from_map_or_db
          end

          it "returns the document from the map" do
            game.should equal(in_map)
          end
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create
        end

        let!(:game_three) do
          person_two.create_game(name: "Skyrim")
        end

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:game).asc(:_id).limit(1).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Game.collection_name][game_two.id].should eq(game_two)
        end

        it "does not load the extra child into the map" do
          Mongoid::IdentityMap[Game.collection_name][game_three.id].should be_nil
        end
      end
    end

    context "when including a belongs to" do

      let(:person_two) do
        Person.create
      end

      let!(:game_one) do
        person.create_game(name: "one")
      end

      let!(:game_two) do
        person_two.create_game(name: "two")
      end

      before do
        Mongoid::IdentityMap.clear
      end

      context "when providing no options" do

        let!(:criteria) do
          Game.includes(:person).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ game_one, game_two ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Person.collection_name][person.id].should eq(person)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Person.collection_name][person_two.id].should eq(person_two)
        end
      end

      context "when the criteria has limiting options" do

        let!(:criteria) do
          Game.includes(:person).asc(:_id).limit(1).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ game_one ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Person.collection_name][person.id].should eq(person)
        end

        it "does not load the documents outside of the limit" do
          Mongoid::IdentityMap[Person.collection_name][person_two.id].should be_nil
        end
      end
    end

    context "when including multiples in the same criteria" do

      let!(:post_one) do
        person.posts.create(title: "one")
      end

      let!(:post_two) do
        person.posts.create(title: "two")
      end

      let!(:game_one) do
        person.create_game(name: "one")
      end

      let!(:game_two) do
        person.create_game(name: "two")
      end

      before do
        Mongoid::IdentityMap.clear
      end

      let!(:criteria) do
        Person.includes(:posts, :game).entries
      end

      it "returns the correct documents" do
        criteria.should eq([ person ])
      end

      it "inserts the first has many document into the identity map" do
        Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
      end

      it "inserts the second has many document into the identity map" do
        Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
      end

      it "removes the first has one document from the identity map" do
        Mongoid::IdentityMap[Game.collection_name][game_one.id].should be_nil
      end

      it "inserts the second has one document into the identity map" do
        Mongoid::IdentityMap[Game.collection_name][game_two.id].should eq(game_two)
      end
    end
  end

  describe "#inclusions" do

    let(:criteria) do
      Band.includes(:records)
    end

    let(:metadata) do
      Band.relations["records"]
    end

    it "returns the inclusions" do
      criteria.inclusions.should eq([ metadata ])
    end
  end

  describe "#inclusions=" do

    let(:criteria) do
      Band.all
    end

    let(:metadata) do
      Band.relations["records"]
    end

    before do
      criteria.inclusions = [ metadata ]
    end

    it "sets the inclusions" do
      criteria.inclusions.should eq([ metadata ])
    end
  end

  pending "#lt"
  pending "#lte"
  pending "#max_distance"

  pending "#merge"
  pending "#merge!"

  pending "#mod"
  pending "#ne"
  pending "#near"
  pending "#near_sphere"
  pending "#nin"
  pending "#nor"
  pending "#only"

  pending "#or"
  pending "#any_of"

  pending "#respond_to?"

  describe "#to_ary" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "returns the executed criteria" do
      criteria.to_ary.should eq([ band ])
    end
  end

  describe "#to_criteria" do

    let(:criteria) do
      Band.all
    end

    it "returns self" do
      criteria.to_criteria.should eq(criteria)
    end
  end

  describe "#to_proc" do

    let(:criteria) do
      Band.all
    end

    it "returns a proc" do
      criteria.to_proc.should be_a(Proc)
    end

    it "wraps the criteria in the proc" do
      criteria.to_proc[].should eq(criteria)
    end
  end

  pending "#type"

  pending "#where"
  pending "#within_box"
  pending "#within_circle"
  pending "#within_polygon"
  pending "#within_spherical_circle"
  pending "#with_size"
  pending "#with_type"
end
