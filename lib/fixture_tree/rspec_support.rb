class FixtureTree
  # RSpec helpers to make testing with FixtureTree even easier.
  #
  # Extend RSpecSupport in a test:
  #
  #   RSpec.describe 'something' do
  #     extend FixtureTree::RSpecSupport
  #
  #     # specs here
  #   end
  #
  # Or include it in all your tests:
  #
  #   RSpec.configure do |c|
  #     c.extend RSpecSupport
  #   end
  #
  # You can then declare trees using `fixture_tree`:
  #
  #   RSpec.describe 'something' do
  #     fixture_tree :example_tree, data: {foo: 'bar'}
  #
  #     it "has a file named 'foo' whose contents are 'bar'" do
  #       expect(example_tree.path.join('foo').open.read).to eq('bar')
  #     end
  #   end
  #
  # Trees can be populated in `before` hooks, if you like:
  #
  #   fixture_tree :example_tree
  #
  #   before(:each) do
  #     example_tree.merge({foo: 'bar'})
  #   end
  #
  #   it "has a file named 'foo' whose contents are 'bar'" do
  #     expect(example_tree.path.join('foo').open.read).to eq('bar')
  #   end
  #
  # Nested contexts can overwrite trees:
  #
  #   fixture_tree :example_tree, data: {foo: 'bar'}
  #
  #   it "has a file named 'foo'" do
  #     expect(example_tree.path.children.map(&:basename)).to contain_exactly('foo')
  #   end
  #
  #   context 'with a different set of files' do
  #     fixture_tree :example_tree, data: {baz: 'qux'}
  #
  #     it "only has a file named 'baz'" do
  #       expect(example_tree.path.children.map(&:basename)).to contain_exactly('baz')
  #     end
  #   end
  #
  # Or you can include `merge: true` to merge with the parent context's tree:
  #
  #   fixture_tree :example_tree, data: {foo: 'bar'}
  #
  #   it "has a file named 'foo'" do
  #     expect(example_tree.path.children.map(&:basename)).to contain_exactly('foo')
  #   end
  #
  #   context 'with an additional file' do
  #     fixture_tree :example_tree, merge: true, data: {baz: 'qux'}
  #
  #     it "has files named 'foo' and 'baz'" do
  #       expect(example_tree.path.children.map(&:basename)).to contain_exactly('foo', 'baz')
  #     end
  #   end
  #
  # And that's about it.
  module RSpecSupport
    def fixture_tree(name, data: nil, merge: false, eager: false)
      # eager intentionally left undocumented because it's not actually useful until I implement support for running
      # hooks when a tree is instantiated
      let(name) do
        if merge && defined?(super)
          # asked to merge and super is defined. we'll assume it's a tree from an outer context and merge into it
          # instead of creating a new tree.
          tree = super()
        else
          # either our parent context doesn't define a tree or we weren't asked to merge with it, so create a new one.
          temp_dir, tree = FixtureTree.create

          # store the temp dir so that we can clean it up after the test completes
          instance_variable_set(:"@_fixture_tree_dir_#{name}", temp_dir)
        end

        if data
          tree.merge(data)
        end
      end

      if eager
        before do
          send(name)
        end
      end

      after do
        # clean up the temp dir if we still know about one
        if instance_variable_defined?(:"@_fixture_tree_dir_#{name}")
          # delete it
          instance_variable_get(:"@_fixture_tree_dir_#{name}").rmtree
          # then unset it so that we won't accidentally try to clean it up in a parent context
          remove_instance_variable(:"@_fixture_tree_dir_#{name}")
        end
      end
    end
  end
end