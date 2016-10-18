# Helper for creating directory hierarchies to use with tests.
#
# You'll typically create trees with `FixtureTree.create`. If you're using RSpec, put this inside one of your specs:
#
#   around do |example|
#     FixtureTree.create do |tree|
#       @tree = tree
#       example.run
#     end
#   end
#
# Now put some data into your tree:
#
#   before do
#     @tree.merge({
#       'one' => 'two', # keys can be either strings...
#       three: 'four',  # ...or symbols
#       five: {         # create nested directories by using a hash
#         six: 'seven'
#       }
#     })
#   end
#
# And test against it:
#
#   it "has a file named 'one' whose contents are 'two'" do
#     expect(@tree.path.join('one').open.read).to eq('two') # FixtureTree#path returns a Pathname object
#   end
#
#   it "has a nested directory named 'five' with a file named 'six' whose contents are 'seven'" do
#     expect(@tree.path.join('five/six').open.read).to eq('seven')
#   end
#
# You can add additional files if a test calls for them:
#
#   it 'lets me add additional files and keeps existing ones around' do
#     @tree.merge({
#       'eight.txt' => 'nine'
#     })
#     expect(@tree.path.join('eight.txt').open.read).to eq('nine')
#     expect(@tree.path.join('one').open.read).to eq('two')
#   end
#
# Or you can replace the entire tree:
#
#   it 'lets me replace the entire tree' do
#     @tree.replace({
#       ten: 'eleven'
#     })
#     expect(@tree.path.join('ten').open.read).to eq('eleven')
#     expect(@tree.path.join('one').exist?).to be(false)
#   end
#
# The tree will be automatically deleted when your `FixtureTree#create` block exits.
class FixtureTree
  attr_reader :path

  # Wrap the specified `Pathname` instance with a `FixtureTree` that can be used to modify it. No special cleanup will
  # be undertaken after you're done testing if you create a `FixtureTree` this way, so you'll need to make sure to
  # delete it after you're done with it.
  def initialize(path)
    @path = path
  end

  # Create an ephemeral `FixtureTree`.
  #
  # If a block is given, the tree will be yielded to the block, and the tree's data (including any modifications made
  # to it during the course of testing) will be deleted when the block exits. If not, `[dir, tree]` will be returned,
  # where `dir` is a Pathname object pointing to a temporary directory containing the tree and `tree` is the ephemeral
  # `FixtureTree` object. The tree's contents can be cleaned up by deleting `dir` after testing is complete.
  def self.create
    temp_dir = Pathname.new(Dir.mktmpdir('fixture_tree'))
    tree = FixtureTree.new(temp_dir.join('fixture'))

    if block_given?
      begin
        yield FixtureTree.new(temp_dir.join('fixture'))
      ensure
        temp_dir.rmtree if temp_dir.exist?
      end
    else
      [temp_dir, tree]
    end
  end

  # Merge the given directory hierarchy or file into this `FixtureTree`.
  #
  # `data` can be either a string or a hash. If it's a hash, this `FixtureTree` will be created as a directory if it's
  # not already one and a file or directory created for each entry in the hash. Values can themselves be strings or
  # hashes to create nested files or directories, respectively. If it's a string, this `FixtureTree` will be created
  # as a file whose contents are the specified string.
  def merge(data)
    if data.is_a?(Hash)
      delete unless @path.directory?
      @path.mkpath

      data.each do |name, contents|
        join(name.to_s).merge(contents)
      end
    else
      delete
      @path.write(data)
    end

    self
  end

  # Replace this `FixtureTree` with the specified directory hierarchy or file. This is equivalent to calling `delete`
  # followed by `merge(data)`.
  def replace(data)
    delete
    merge(data)

    self
  end

  # Deletes this `FixtureTree`, if it exists. If this tree is currently a directory, it will be removed along with its
  # children. If this tree is currently a file, the file will be deleted.
  #
  # `merge` or `replace` can later be called to recreate this `FixtureTree`.
  def delete
    if @path.directory?
      @path.rmtree
    elsif @path.exist?
      @path.delete
    end

    self
  end

  # Return a `FixtureTree` offering a view on a nested path of this `FixtureTree`. This can be used like:
  #
  #   some_tree.join('foo/bar').merge({'baz' => 'qux'})
  #
  # to get the same effect as:
  #
  #   some_tree.merge({'foo' => {'bar' => {'baz' => 'qux'}}})
  def join(path)
    FixtureTree.new(@path.join(path))
  end
end
