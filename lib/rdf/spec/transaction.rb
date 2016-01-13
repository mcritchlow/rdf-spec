require 'rdf/spec'

# Pass in an instance of RDF::Transaction as follows:
#
#   it_behaves_like "RDF::Transaction", RDF::Transaction
shared_examples "an RDF::Transaction" do |klass|
  include RDF::Spec::Matchers

  subject          { klass.new(repository, mutable: true) }
  let(:repository) { RDF::Repository.new }

  it { is_expected.to be_readable }

  describe "#initialize" do
    it 'accepts a repository' do
      repo = double('repository')

      expect(klass.new(repo).repository).to eq repo
    end

    it 'defaults immutable (read only)' do
      expect(klass.new(repository).mutable?).to be false
    end

    it 'allows mutability' do
      expect(klass.new(repository, mutable: true)).to be_mutable
    end
  end

  it "does not respond to #load" do
    expect { subject.load("http://example/") }.to raise_error(NoMethodError)
  end

  it "does not respond to #update" do
    expect { subject.update(RDF::Statement.new) }.to raise_error(NoMethodError)
  end

  it "does not respond to #clear" do
    expect { subject.clear }.to raise_error(NoMethodError)
  end

  describe '#buffered?' do
    it 'is false when changeset is empty' do
      expect(subject).not_to be_buffered
    end
  end

  describe '#changes' do
    it 'is a changeset' do
      expect(subject.changes).to be_a RDF::Changeset
    end

    it 'is initially empty' do
      expect(subject.changes).to be_empty
    end
  end

  describe "#delete" do
    let(:st) { RDF::Statement(:s, RDF::URI('p'), 'o') }
    
    it 'adds to deletes' do
      subject.repository.insert(st)

      expect do 
        subject.delete(st)
        subject.execute
      end.to change { subject.repository.empty? }.from(false).to(true)
    end

    it 'adds multiple to deletes' do
      sts = [st] << RDF::Statement(:x, RDF::URI('y'), 'z')
      subject.repository.insert(*sts)

      expect do
        subject.delete(*sts)
        subject.execute
      end.to change { subject.repository.empty? }.from(false).to(true)
    end

    it 'adds enumerable to deletes' do
      sts = [st] << RDF::Statement(:x, RDF::URI('y'), 'z')
      sts.extend(RDF::Enumerable)
      subject.repository.insert(sts)

      expect do
        subject.delete(sts)
        subject.execute
      end.to change { subject.repository.empty? }.from(false).to(true)
    end
  end

  describe "#insert" do
    let(:st) { RDF::Statement(:s, RDF::URI('p'), 'o') }
    
    it 'adds to inserts' do
      expect do
        subject.insert(st)
        subject.execute
      end.to change { subject.repository.statements }
              .to contain_exactly(st)
    end

    it 'adds multiple to inserts' do
      sts = [st] << RDF::Statement(:x, RDF::URI('y'), 'z')
      
      expect do
        subject.insert(*sts)
        subject.execute
      end.to change { subject.repository.statements }
              .to contain_exactly(*sts)
    end

    it 'adds enumerable to inserts' do
      sts = [st] << RDF::Statement(:x, RDF::URI('y'), 'z')
      sts.extend(RDF::Enumerable)

      expect do
        subject.insert(sts)
        subject.execute
      end.to change { subject.repository.statements }
              .to contain_exactly(*sts)
    end
  end

  describe '#execute' do
    it 'calls changes#apply with repository' do
      expect(subject.changes).to receive(:apply).with(subject.repository)
      subject.execute
    end
  end
end

shared_examples "RDF_Transaction" do |klass|
  it_behaves_like 'an RDF::Transaction', klass
end
