require 'rdf/spec'

RSpec.shared_examples 'an RDF::Writable' do
  include RDF::Spec::Matchers
  let(:filename) {RDF::Spec::TRIPLES_FILE}
  let(:statements) {RDF::NTriples::Reader.new(File.open(filename)).to_a}
  let(:supports_graph_name) {writable.respond_to?(:supports?) && writable.supports?(:graph_name)}

  before :each do
    raise 'writable must be defined in with let(:readable)' unless
      defined? writable
  end

  subject { writable }
  let(:statement) {statements.detect {|s| s.to_a.all? {|r| r.uri?}}}
  let(:count) {statements.size}

  it {is_expected.to respond_to(:writable?)}
  its(:writable?) {is_expected.to eq !!subject.writable?}

  describe "#<<" do
    it "inserts a reader" do
      skip("writability") unless subject.writable?
      reader = RDF::NTriples::Reader.new(File.open(filename)).to_a
      subject << reader
      is_expected.to have_statement(statement)
      expect(subject.count).to eq count
    end

    it "inserts a graph" do
      skip("writability") unless subject.writable?
      graph = RDF::Graph.new << statements
      subject << graph
      is_expected.to have_statement(statement)
      expect(subject.count).to eq count
    end

    it "inserts an enumerable" do
      skip("writability") unless subject.writable?
      enumerable = statements.dup.extend(RDF::Enumerable)
      subject << enumerable
      is_expected.to have_statement(statement)
      expect(subject.count).to eq count
    end

    it "inserts data responding to #to_rdf" do
      skip("writability") unless subject.writable?
      mock = double('mock')
      allow(mock).to receive(:to_rdf).and_return(statements)
      subject << mock
      is_expected.to have_statement(statement)
      expect(subject.count).to eq count
    end

    it "inserts a statement" do
      skip("writability") unless subject.writable?
      subject << statement
      is_expected.to have_statement(statement)
      expect(subject.count).to eq 1
    end
  end

  context "when inserting statements" do
    it "is_expected.to support #insert" do
      skip("writability") unless subject.writable?
      is_expected.to respond_to(:insert)
    end

    it "is_expected.to not raise errors" do
      skip("writability") unless subject.writable?
      expect { subject.insert(statement) }.not_to raise_error
    end

    it "is_expected.to support inserting one statement at a time" do
      skip("writability") unless subject.writable?
      subject.insert(statement)
      is_expected.to have_statement(statement)
    end

    it "is_expected.to support inserting multiple statements at a time" do
      skip("writability") unless subject.writable?
      subject.insert(*statements)
      statements.each do |statement|
        is_expected.to have_statement(statement) unless statement.to_a.any?(&:node?)
      end
    end

    it "is_expected.to insert statements successfully" do
      skip("writability") unless subject.writable?
      subject.insert(*statements)
      expect(subject.count).to eq count
    end

    it "is_expected.to not insert a statement twice" do
      skip("writability") unless subject.writable?
      subject.insert(statement)
      subject.insert(statement)
      expect(subject.count).to eq 1
    end

    it "is_expected.to treat statements with a different context as distinct" do
      skip("writability") unless subject.writable?
      s1 = statement.dup
      s1.context = nil
      s2 = statement.dup
      s2.context = RDF::URI.new("urn:context:1")
      s3 = statement.dup
      s3.context = RDF::URI.new("urn:context:2")
      subject.insert(s1)
      subject.insert(s2)
      subject.insert(s3)
      # If contexts are not suported, all three are redundant
      expect(subject.count).to eq (supports_graph_name ? 3 : 1)
    end

    it "is_expected.to treat statements with a different graph_name as distinct" do
      skip("writability") unless subject.writable?
      s1 = statement.dup
      s1.graph_name = nil
      s2 = statement.dup
      s2.graph_name = RDF::URI.new("urn:context:1")
      s3 = statement.dup
      s3.graph_name = RDF::URI.new("urn:context:2")
      subject.insert(s1)
      subject.insert(s2)
      subject.insert(s3)
      # If graph_names are not suported, all three are redundant
      expect(subject.count).to eq (supports_graph_name ? 3 : 1)
    end
  end
end

##
# @deprecated use `it_behaves_like "an RDF::Writable"` instead
module RDF_Writable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  def self.included(mod)
    warn "[DEPRECATION] `RDF_Writable` is deprecated. "\
         "Please use `it_behaves_like 'an RDF::Writable'`"
  end

  describe 'examples for' do
    include_examples 'an RDF::Writable' do
      let(:writable) { @writable }

      before do
        raise '@writable must be defined' unless defined?(writable)
      end
    end
  end
end
